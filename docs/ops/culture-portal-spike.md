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
- 문화포털 ENJOY **17건**을 published/app assets에 병합 (TourAPI ENJOY와 병존)
- Worker: `worker/loond_worker/culture_collect.py`

## TourAPI daily 주의 (2026-09-17)
- `run_tour_daily` 가 예전엔 `suwon-tour-*` APPLY를 전부 제거해 **예약 체험 5건**이 사라졌음.
- 이제 `meta.source=curated_traveler` / `category=tour_*` APPLY와 `culture_portal` ENJOY는 보존.
