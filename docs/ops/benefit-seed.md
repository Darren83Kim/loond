# BENEFIT 시드 (수원 맞춤 혜택)

상태: **Live seed** — 2026-09-21  
관련: `docs/design/my-chance-profile-draft.md`, `BenefitProfile` soft matching, Pages `regions/suwon.json`

## 목적

「맞춤 혜택」이 빈 CTA만 보이지 않도록, **보조금24/복지로 API 스크랩 없이** 공식 안내 URL이 있는 수원(·전국제도 수원 안내) BENEFIT를 소량 시드한다.

앱은 수급 심사가 아니며, 카드 → `sourceUrl` 원문 확인이 본선이다.

## 현재 시드 (suwon · type=`BENEFIT`)

| id | 제목 | 축 | sourceUrl |
|----|------|----|-----------|
| `suwon-benefit-youth-basic-income` | 청년기본소득 (경기도·수원) | 청년 | [suwon.go.kr …/welfare14-04-03.jsp](https://www.suwon.go.kr/sw-www/deptHome/dep_welfare/welfare14/welfare14-04/welfare14-04-03.jsp) |
| `suwon-benefit-parental-benefit` | 부모급여 | 육아·영아 | […/welfare14-02-01.jsp](https://www.suwon.go.kr/sw-www/deptHome/dep_welfare/welfare14/welfare14-02/welfare14-02-01.jsp) |
| `suwon-benefit-child-allowance` | 아동수당 | 아동 | […/welfare14-02-10.jsp](https://www.suwon.go.kr/sw-www/deptHome/dep_welfare/welfare14/welfare14-02/welfare14-02-10.jsp) |
| `suwon-benefit-housing-benefit` | 주거급여 (청년주거급여 포함) | 주거 | […/city09_01.jsp](https://www.suwon.go.kr/sw-www/deptHome/dep_city/city09/city09_01.jsp) |
| `suwon-benefit-birth-grant` | 자녀 출산·입양 지원금 | 임신·출산 | […/welfare14-01-10.jsp](https://www.suwon.go.kr/sw-www/deptHome/dep_welfare/welfare14/welfare14-01/welfare14-01-10.jsp) |

공통:

- `meta.source` = `curated_benefit`
- `category` = `welfare_support` (soft match blob + 관련 APPLY 복지 힌트와 정렬)
- `status` = `published`, `applicationEnd` = null → UI D-Day 「상시」
- title/summary/target/benefit에 매칭 키워드(청년·아동수당·영아·주거·출산 등) 포함

기간제(예: 청년 주거 패키지 2026.1 모집)는 **마감된 창을 시드하지 않음**. 다음 모집 공고가 열리면 동일 절차로 추가.

## 데이터 경로

1. **소스 of truth**: `data/published/opportunities.json` (통합 디버그 피드)
2. `python3 scripts/sync_published_assets.py` 또는 `python -m loond_worker.publish_regions --sync-assets`
   - → `data/published/regions/suwon.json` (+ `.gz`)
   - → `data/published/manifest.json` (etag/counts에 `BENEFIT` 포함)
   - → `app/assets/data/opportunities.json` (**수원 시드만**)
3. **폰 원격**: push `main` + `data/published/**` → Actions `deploy-pages` →  
   `https://darren83kim.github.io/loond/regions/suwon.json`  
   앱 `OpportunityRepository.loadForRegion`이 manifest etag 갱신 후 캐시 교체.
4. **버전 bump**: 원격 Pages만으로 충분하면 **불필요**. 시드 에셋은 오프라인·첫 설치용 백업.

## Tour daily 보존

`run_tour_daily.merge_and_publish`는 APPLY + **BENEFIT** + culture_portal ENJOY를 유지하고 TourAPI ENJOY/DISCOVER만 교체한다.  
시드를 넣지 않으면 다음 daily에 BENEFIT가 사라지므로, 신규 항목은 반드시 통합 JSON에 넣고 sync 후 커밋.

## 새로고침 절차

1. 공식 페이지에서 자격·금액·신청 창 확인 (수원시청 / 복지로 상세).
2. Opportunity 스키마 필드로 JSON 작성 (`type: BENEFIT`, `meta.source: curated_benefit`).
3. `data/published/opportunities.json`에 upsert (같은 id면 교체).
4. `python3 scripts/sync_published_assets.py`
5. APPLY/ENJOY counts 회귀 확인 후 commit + push → Pages 배포 대기(~1–3분).
6. 폰: 앱 재실행 또는 지역 재선택으로 remote refresh (재설치 불필요, 단 오래된 디스크 캐시는 etag 변경으로 갱신).

## 비범위

- 보조금24/복지로 API 조건 매칭
- 소득·재산 하드 필터
- 타 시 BENEFIT 대량 시드 (필요 시 동일 패턴으로 확장)
