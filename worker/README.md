# Loond Worker — EPIC 1 (Suwon APPLY PoC) + EPIC 4 scaffolding

수원시 고시공고(`BD_ofrList.do`) → 키워드/블랙리스트 필터 → Opportunity(`pending_review`) → 수동 검증 후 `published` JSON.

## 요구사항

- Python 3.10+
- `pip install -r requirements.txt`

## 실행

프로젝트 루트는 이 폴더의 상위 (`…/loond`).

```bash
cd worker
python -m pip install -r requirements.txt
python -m loond_worker.run_poc
```

옵션:

```bash
# 이전 원본 CSV/JSON 재사용
python -m loond_worker.run_poc --reuse-raw ../data/raw/notices_window.csv

# 이미 수집된 data/raw/notices_window.json 사용
python -m loond_worker.run_poc --skip-collect

# pending에만 publish_period_proxy 플래그 샘플 허용 (published에는 사용 안 함)
python -m loond_worker.run_poc --proxy-samples
```

## 산출물

| 경로 | 내용 |
|------|------|
| `../data/raw/notices_window.json` | ~90일 창 목록 |
| `../data/raw/notices_filtered.json` | 필터 결과 |
| `../data/raw/detail_sample.json` | 상세 5~10건 추출 |
| `../data/pending_review/pending_review.json` | 검증 큐 |
| `../data/pending_review/pending_review.csv` | 검증 큐(시트용) |
| `../data/published/opportunities.json` | published만 |

## 규칙 (요약)

- HTTPS TLS 실패 시 **HTTP** 사용 (스파이크와 동일).
- 페이지/상세 사이 **예의 있는 delay**.
- `applicationEnd` 없으면 **`pending_review`만** — published 금지.
- 게재기간 종료일은 `applicationEndSource=publish_period_proxy` 로만 표시 가능 (자동 published 금지).
- HWP/HWPX는 존재 여부만 기록 (본 파서 PoC 범위 밖).

## eminwon_ofr PoC (multi-city notices)

수원 `collect.py`와 별도로, 새올 `OfrAction.do` 고시공고 목록→상세→`pending_review`만 쌓는 PoC.

```bash
cd worker
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/python -m loond_worker.eminwon_collect --region goyang --pages 2 --details 3
```

- city config: `loond_worker/notice_sources.py`
- 산출: `../data/raw/eminwon_{region}_list.json`, `../data/pending_review/eminwon_{region}_pending.json`
- **published/opportunities.json 자동 병합 없음**
- TLS 실패 시 http fallback

자세한 도시 URL·신뢰도: `docs/ops/notice-source-types.md`

## 지역 · TourAPI (EPIC 4-0 / 4-1)

- `region_id=suwon` / `region_name=수원` — see `loond_worker/region_codes.py`
- Base URL: **`https://apis.data.go.kr/B551011/KorService2`** (KorService1 retired)
- `TOUR_API_AREA_CODE="31"` (경기도) + **`STRATEGY=area_filter`** (`FILTER_ADDR_KEYWORD="수원"`)
- Draft sigungu 1–4 under 31 returned 0 live; legal-dong 41/{111,113,115,117} observed on items
- `VERIFY_PENDING=True` — `areaCode2` key-scope error; list APIs OK
- Service key: env **`TOUR_API_SERVICE_KEY`** only (never commit). Prefer Windows host if box TLS fails.

```bash
# Daily ENJOY/DISCOVER collect → published (EPIC 5; preferred)
export TOUR_API_SERVICE_KEY=your_key   # never commit
python -m loond_worker.run_tour_daily

# areaCode2 verify stub only (CI-safe; area_filter → exit 0 on 403/30)
python -m loond_worker.tour_collect
```

## published → app asset sync (EPIC 4-7)

From repo root:

```bash
./scripts/sync_published_assets.sh
# or: python3 scripts/sync_published_assets.py
```

Copies `data/published/opportunities.json` → `app/assets/data/opportunities.json`.

## APPLY review 규칙 엔진 (reject / needs_review / auto_publish)

eminwon·수원 pending을 전량 publish하지 않고 규칙으로 분기한다.

```bash
cd worker
.venv/bin/python -m loond_worker.apply_review \
  --in ../data/pending_review/eminwon_goyang_pending.json
# auto_publish만 published merge + asset sync
.venv/bin/python -m loond_worker.apply_review \
  --in ../data/pending_review/eminwon_goyang_pending.json --publish
```

- 코드: `loond_worker/apply_rules.py`, CLI `loond_worker.apply_review`
- 행정 블랙리스트: `config.EMINWON_ADMIN_BLACKLIST` (수원 BLACKLIST와 분리)
- 문서: [`docs/ops/apply-review-rules.md`](../docs/ops/apply-review-rules.md)
- 기본은 `--publish` 없음 (안전). 1차 고양 배치는 대부분 reject/needs_review 예상.

## pending → published 검증 (EPIC 5-4 / R15)


수동 승격 체크리스트: [`docs/ops/pending-publish-checklist.md`](../docs/ops/pending-publish-checklist.md)  
(마감일·화이트리스트 APPLY·채용/입찰 제외·sourceUrl·HWP 확인·asset sync)
