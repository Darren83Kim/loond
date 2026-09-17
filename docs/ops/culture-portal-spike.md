# 문화포털 ENJOY 스파이크 (R11)

날짜: 2026-09-17

## API
- 한국문화정보원 **한눈에보는문화정보조회서비스** (data.go.kr `B553457`)
- 사용 엔드포인트 (구 `nopenapi/.../period` **폐기**):
  - `http://apis.data.go.kr/B553457/cultureinfo/period2`
  - `http://apis.data.go.kr/B553457/cultureinfo/area2`
  - `http://apis.data.go.kr/B553457/cultureinfo/detail2` — per-seq outbound `url` / `placeUrl` / `phone` / `price`
- Secret: `CULTURE_API_SERVICE_KEY` (Decoding 키)
- 이 환경에서 `https://apis.data.go.kr` TLS EOF → **HTTP + curl HTTP/1.1**

## 수원 수집
1. `period2` + `keyword=수원`, 기간 오늘~+120일
2. `area2` + `sido=경기` + `gugun=수원시` (타 시군 혼입 가능 → 후필터)
3. title/place/sigungu에 「수원」포함만 유지, 종료일 지난 건 제외
4. 각 `seq`에 `detail2` 호출해 실 예매/원문 URL 보강

## sourceUrl 규칙
1. **우선**: `detail2` 응답의 `url` (비어 있지 않으면). HTML 엔티티(`&amp;` 등)는 unescape.
2. **폴백**: `https://www.culture.go.kr/portal/cltInfo/oneCltInfo/view.do?menuNo=200010&seq={seq}`
3. **금지**: `https://www.culture.go.kr/oneclt/oneCltView.do?seq={seq}` (menuNo 없음 → 포털 에러 페이지)

예: seq `393756` (`[수원] 파랑새`) → `https://nol.yanolja.com/ticket/products/26009848`

`placeUrl` / `phone` / `price` 는 `meta` 및 description에 보관 (`meta.sourceUrlSource` = `detail2_url` | `portal_fallback`).

## 매핑
- id: `suwon-culture-{seq}`
- type: `ENJOY`
- sourceName: `문화포털(한눈에보는문화정보)`
- meta.source: `culture_portal`
- 제목·URL 등 문자열은 HTML unescape (`&middot;` 등)

## 결과
- 문화포털 ENJOY 수집·병합 (TourAPI와 병존; 2026-09-17 dedupe 후 **16건**)
- Worker: `worker/loond_worker/culture_collect.py`

## TourAPI daily 주의 (2026-09-17)
- `run_tour_daily` 가 예전엔 `suwon-tour-*` APPLY를 전부 제거해 **예약 체험 5건**이 사라졌음.
- 이제 `meta.source=curated_traveler` / `category=tour_*` APPLY와 `culture_portal` ENJOY는 보존.

## Title dedupe vs TourAPI (2026-09-17)
- `culture_collect.merge_into_published` drops culture ENJOY whose **normalized title** matches an existing non-culture ENJOY (prefer TourAPI).
- Normalize: HTML unescape → NFKC → lower → strip `[…]`/`(…)` brackets → remove punct/quotes/spaces.
- Daily Actions: TourAPI first (preserves culture), then `python -m loond_worker.culture_collect` with `CULTURE_API_SERVICE_KEY` (skip+warn if missing).

## Traveler home 「곧 열려요」
- `enjoySorted`: culture_portal (`suwon-culture-*`) boosted before other ENJOY, then startDate, then title.
- Horizon preview cap: **16**.

## Daily Actions (2026-09-17)
- `.github/workflows/daily_worker.yml`: TourAPI 수집 후 `python -m loond_worker.culture_collect`
- Secret: `CULTURE_API_SERVICE_KEY` (없으면 warn 후 skip, TourAPI 잡은 유지)
- `merge_into_published`: TourAPI ENJOY와 **정규화 제목 중복**이면 문화 쪽 drop (TourAPI 우선)
- 2026-09-17 재수집: culture 17→**16** keep (drop 예: 화성행궁 야간개장)
- 홈 「곧 열려요」: culture_portal 우선 정렬, horizon 미리보기 16
