# 지역별 원격 로드 설계

상태: **P2 workflow landed** — Pages 배포 파이프라인 준비 (repo private → Pages 활성화는 사용자 조치 필요)  
작성: 2026-09-17 · P1 완료: 2026-09-17 · P2 workflow: 2026-09-17  
관련: `docs/ops/multi-city.md`, `OpportunityRepository` (현재 에셋 로드)

## 1. 문제

- 지금은 `app/assets/data/opportunities.json`을 APK에 통째로 넣는다.
- 지역 선택은 **로컬 필터**일 뿐, 네트워크 fetch가 아니다.
- 시를 늘릴수록 APK·첫 설치 용량이 커진다.
- 목표 UX: **지역을 고르면 그 지역 피드만 받아온다.**

### 현재 규모 (2026-09-17 번들)

| 구분 | 크기 |
|------|------|
| 전체 JSON (6시) | ~1.1 MB (gzip ~68 KB) |
| 시당 JSON | ~100–220 KB (gzip ~8–17 KB) |

전국(시·군 수백)으로 가면 에셋 번들은 비현실적이다. 시당 원격 로드가 맞다.

## 2. 목표 / 비목표

**목표**

1. 앱 번들에는 **시드(최소)**만 남긴다 (오프라인·첫 실행용).
2. 지역 선택 시 해당 `regionId` JSON만 받아 캐시한다.
3. Daily worker가 시별 아티팩트 + 매니페스트를 배포한다.
4. 오프라인에서는 **캐시된 지역**만 보여 준다.

**비목표 (1차)**

- 실시간 검색 API / 개인화 추천 서버
- 로그인·유료 CDN 필수화
- 항목 단위 델타 동기화 (etag/버전으로 파일 단위 교체면 충분)
- APPLY 스크래퍼를 폰에서 돌리기

## 3. 아키텍처

```
[GitHub Actions daily]
  TourAPI / culture / eminwon / rules
        ↓
  data/published/
    opportunities.json      (통합 — P1 유지)
    manifest.json
    regions/{regionId}.json (+ .json.gz)
        ↓  publish (Pages — P2)
[HTTPS static host]
        ↓
[Loond app]
  RegionPicker → RegionFeedStore.fetch(regionId)   (P3)
    → disk cache → UI
```

### 3.1 매니페스트

`data/published/manifest.json` 예시:

```json
{
  "schemaVersion": 1,
  "updatedAt": "2026-09-17T09:00:00+09:00",
  "baseUrl": "https://darren83kim.github.io/loond/regions/",
  "regions": [
    {
      "id": "suwon",
      "label": "수원",
      "path": "suwon.json",
      "etag": "sha256:…",
      "bytes": 189895,
      "bytesGzip": 17083,
      "counts": { "APPLY": 12, "ENJOY": 32, "DISCOVER": 100 },
      "depth": "deep"
    }
  ]
}
```

- 앱은 기동/지역 피커 진입 시 매니페스트를 가볍게 갱신한다 (P3).
- `etag`(또는 `updatedAt`+hash)가 같으면 다운로드 스킵.

### 3.2 지역 파일

- 기존 opportunity 스키마 유지 (`schemaVersion`, `region`, `regionLabel`, `updatedAt`, `opportunities`, `counts`).
- 파일 하나 = **한 지역** (필터 서버 불필요).
- gzip 전송 권장 (시당 ~10–20 KB) — worker가 `regions/*.json.gz`도 함께 씀.

### 3.3 호스팅 — **결정: GitHub Pages (1차)**

| 옵션 | 상태 |
|------|------|
| **A. GitHub Pages** | **Locked (1차)** — workflow `.github/workflows/pages.yml` |
| B. Cloudflare R2 + 공개 버킷 | 트래픽·안정성 필요 시 이전 (앱 `baseUrl`만 교체) |
| C. 자체 API | 비목표 |

**Live Pages 경로 (목표):**

- Site: `https://darren83kim.github.io/loond/`
- Manifest: `https://darren83kim.github.io/loond/manifest.json`
- Region files: `https://darren83kim.github.io/loond/regions/{id}.json` (+ `.json.gz`)
- `manifest.baseUrl`: `https://darren83kim.github.io/loond/regions/`
- Deploy: Actions uploads `data/published/` contents to **site root** (not nested under `/data/published/`).

**Pages 활성화 (2026-09-17):**

- Workflow: on push to `main` when `data/published/**` changes, plus `workflow_dispatch`.
- API enable attempt: `POST /repos/Darren83Kim/loond/pages` with `build_type=workflow` → **422** — *Your current plan does not support GitHub Pages for this repository* (repo is **private** on Free).
- **User must do one of:**
  1. **Make repo Public** — Settings → General → Danger Zone → Change repository visibility → Public; **or**
  2. **Upgrade** to GitHub Pro (private Pages supported).
- Then: Settings → Pages → Build and deployment → **Source = GitHub Actions** (or re-run `gh api -X POST repos/Darren83Kim/loond/pages -f build_type=workflow`).
- After enable: `gh workflow run deploy-pages` (or push under `data/published/`) and wait for the `github-pages` environment deploy.

### 3.4 앱 동작 (P3 — 미구현)

1. **시드**: APK에 `suwon`(또는 빈 stub + 매니페스트 스냅샷)만 포함.
2. **선택**: `RegionStore`에 `selected_region_id` 저장 (기존 유지).
3. **로드**: `OpportunityRepository.loadForRegion(id)` — 캐시/etag → HTTPS GET.
4. **전환 UX**: 로딩 → 새 피드; 실패 시 캐시/시드 + 재시도 배너.
5. **프리패치(선택)**: 인접/최근 지역 1–2개.

### 3.5 캐시 (P3)

- 위치: 앱 문서 디렉터리 `feeds/{regionId}.json` + `feeds/manifest.json`.
- 정책: 지역당 최신 1본. LRU 최대 N도시 (예: 8).
- 만료: 매니페스트 `updatedAt`/etag 기준.

## 4. Worker / Actions (P1 Done)

| 항목 | 경로 / 진입점 |
|------|----------------|
| Splitter | `worker/loond_worker/publish_regions.py` |
| Shared sync | `sync_published_outputs()` — 앱 에셋 + regions + manifest |
| CLI | `cd worker && python -m loond_worker.publish_regions` |
| Hooks | `run_tour_daily.merge_and_publish`, `culture_collect` `__main__`, `apply_review.sync_assets`, `scripts/sync_published_assets.py` |
| Outputs | `data/published/regions/{id}.json` (+ `.gz`), `data/published/manifest.json` |
| Daily commit | `.github/workflows/daily_worker.yml`도 regions/ + manifest 포함 |

통합 `opportunities.json`은 **유지** (디버그·현행 앱 에셋). P3에서 에셋은 시드만 남기는 방향.

## 5. 보안·품질

- 앱에 OpenAPI 키를 넣지 않는다 (지금처럼 worker 전용).
- HTTPS만. 인증 불필요(공개 피드).
- JSON 스키마/`schemaVersion` 검증 후 UI 반영 (P3).
- **지역 오분류 방지** (별도): `고양` ⊂ `고양이` 같은 부분문자열 매칭 금지 → 단어 경계/`culture_gugun`·주소 우선. (대구미술관 건 — P0 핫픽스, 본 P1과 분리)

## 6. 단계적 롤아웃

| Phase | 내용 | 완료 기준 | 상태 |
|-------|------|-----------|------|
| **P0** | 설계 합의 + 오분류 핫픽스(고양이) | 문서 OK, 폰에서 대구 항목 사라짐 | 설계 OK · 핫픽스 Open |
| **P1** | Worker: `regions/*.json` + `manifest.json` 산출 | repo에 시별 파일 존재 | **Done** |
| **P2** | 정적 호스트 배포 (GitHub Pages) | URL로 curl 가능 | **Workflow Done** · Pages Settings **Blocked** (private/Free) |
| **P3** | 앱: 원격 로드 + 디스크 캐시, 에셋은 시드만 | 지역 전환 시 네트워크 확인, APK 용량 감소 | Open |
| **P4** | Thin 도시·전국 확장 | 매니페스트에 도시만 추가 | Open |

### P1 체크리스트

- [x] `publish_regions.py` — 번들 → regions + manifest
- [x] `sync_published_outputs()` — 모든 통합 JSON writer 경로에서 호출
- [x] CLI `python -m loond_worker.publish_regions`
- [x] `data/published/regions/*.json` + `manifest.json` 생성·커밋
- [x] 통합 JSON + 앱 에셋 sync 유지
- [x] 호스팅 결정 = GitHub Pages (문서)
- [x] P2 Pages workflow (`.github/workflows/pages.yml`) on main
- [ ] P2 Pages Settings 활성화 — **blocker**: private repo on Free plan (make Public or upgrade Pro, then Source=GitHub Actions)
- [ ] P3 Flutter remote fetch


### P2 체크리스트

- [x] `.github/workflows/pages.yml` — `upload-pages-artifact` + `deploy-pages`, site root = `data/published/`
- [x] `permissions: pages: write` + `id-token: write` + `github-pages` environment
- [x] Trigger: push `main` + `data/published/**`, `workflow_dispatch`
- [x] `manifest.baseUrl` = `https://darren83kim.github.io/loond/regions/`
- [ ] Repo Pages enabled (Public or Pro) + Source = GitHub Actions
- [ ] Live curl 200 for manifest + region JSON

### P2 curl smoke (Pages live 후)

```bash
# manifest
curl -fsSL -o /tmp/loond-manifest.json -w "%{http_code}\n" \
  https://darren83kim.github.io/loond/manifest.json
python3 -c "import json; m=json.load(open('/tmp/loond-manifest.json')); print(m['baseUrl'], len(m['regions']), [r['id'] for r in m['regions']])"

# one region
curl -fsSL -o /tmp/loond-suwon.json -w "%{http_code}\n" \
  https://darren83kim.github.io/loond/regions/suwon.json
python3 -c "import json; d=json.load(open('/tmp/loond-suwon.json')); print(d.get('region'), d.get('counts'), len(d.get('opportunities',[])))"

# optional gzip (if client sends Accept-Encoding or fetches .gz)
curl -fsSL -o /tmp/loond-suwon.json.gz -w "%{http_code}\n" \
  https://darren83kim.github.io/loond/regions/suwon.json.gz
```

## 7. 결정 로그

1. **호스팅**: GitHub Pages (1차) — **Locked 2026-09-17**. Workflow landed 2026-09-17; live URL blocked until repo Public or Pro. R2는 필요 시.
2. **시드 범위**: P3에서 확정 (수원만 vs 최근 선택 없음 → 수원).
3. **통합 JSON**: P1 유지 (디버그·현행 에셋).
4. **P0 오분류**: 설계와 병행 가능; 본 P1 범위 밖.

## 8. 비고 — 왜 지금 에셋이었나

PoC·내부 테스트에서 TourAPI 키 없이 폰에서 바로 보기 위함이었다.  
출시·전국 확장 전제로 바꾸면 **원격 로드가 본선**, 에셋은 비상 시드다.
