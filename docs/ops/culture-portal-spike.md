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

## Multi-city (2026-09-17)
- Generalized to `collect_enjoy_for_regions()` over `region_codes.REGIONS`.
- ids: `{region_id}-culture-{seq}` (not only suwon-).
- See `docs/ops/multi-city.md`.

## R31 얇은 ENJOY (2026-10-29)

라이브 manifest(`updatedAt` 2026-10-16, 2026-10-29에 재확인) ENJOY: 충주 1, 단양 2, 가평 4, 군산 4, 속초 5, 공주 5, 통영 5, 성남 6, 부여 6, 순천 6, 거제 6, 부천 8. 로컬 발행본(2026-10-28)도 같은 도시가 얇고, 단양·가평·통영 culture 행은 0이었다.

문화포털 공개 목록(키 없음, 기간 2026-10-29~+120일 또는 키워드)과 코드를 대조한 원인:

1. **시군구를 도시명과 완전 일치할 때만 유지**해서 `분당구`·`원미구` 행이 성남·부천에서 탈락했다. 구 이름은 그 도시 `districts`에 있을 때만 통과한다.
2. **장소 문자열에 도시명이 없으면 제목을 무시**했다. `[충주] 호수 위 우주`(장소 탄금호 국제조정경기장, 주소는 충주시)가 여기에 해당한다. `[도시]` 또는 `○○시/군` 토큰이고 시도가 맞으며 장소가 다른 시·군을 가리키지 않을 때만 살린다. `단양 수양개빛터널`, `통영의 …`(상시·온라인, 장소 시·군 없음), `고양이`는 그대로 버린다.
3. **시도 문자열이 짧은 이름만**이었다. 공개 목록의 전남·광주 행은 `area=광주`이고 주소는 `전남광주통합특별시 …`다. `ctpvNm=전남` 검색은 0건. `충청북도`·`전북특별자치도`·`강원특별자치도` 별칭을 area2에 같이 보낸다.
4. **TourAPI** `lDongSignguCd=43130`처럼 시도코드가 붙은 5자리는 인덱스 미스 후 키워드로 떨어지지 않아 축제가 삭제됐다. `43130`→충주, `43800`→단양, `12130`→여수. 코드가 있는데 카탈로그에 없으면 여전히 키워드로 넘기지 않는다.
5. 전국 `searchFestival2`가 8건 미만인 도시만 `searchKeyword2`(contentTypeId=15)와 해당 법정동 `searchFestival2`로 보강한다. 15가 아닌 타입은 ENJOY로 넣지 않는다.

기대(이번 PR은 발행 JSON을 다시 쓰지 않음. 키 있는 수집 다음):

| 도시 | 수집 전(로컬 2026-10-28 culture / tour) | 다음 수집에서 기대 |
|------|------------------------------------------|-------------------|
| 충주 | 2 / 1 | culture는 포털 창 안 충주 5건 쪽으로. `[충주] 호수 위 우주`가 포함되어야 한다. 축제 backfill은 5자리 코드·키워드에 실제 축제가 있을 때만 증가 |
| 단양 | 0 / 2 | culture는 0 유지가 맞다(상시 1건은 장소 시·군이 없어 버림). 축제는 ldong 43/800에 15번 타입이 더 있을 때만 2보다 커진다 |
| 가평 | 0 / 4 | 포털 키워드 가평은 0건. culture는 빈 상태가 정직하다. 축제 backfill만 |
| 성남·부천 | 6 / 2, 4 / 1 | 분당구·원미구 등 구 단위 행이 살아나 포털 창(성남 약 9건)에 가까워진다 |
| 순천·여수 | 3 / 2, 2 / 8 | `전남광주통합특별시`·`area=광주` + 순천시/여수시만 해당 도시에 남고 광주 구 행은 가져가지 않는다 |
| 통영 | 0 / 5 | 제목에 `통영의`만 있는 온라인 행은 계속 제외. 축제 backfill만 |

목록 API가 한 도시에서 전부 실패하면 그 도시 culture 행은 지우지 않는다(서울 culture 와이프 방지). 성공했는데 0건이면 비운다.

키 없이 이 VM에서 culture/TourAPI 실호출은 하지 못했다(`CULTURE_API_SERVICE_KEY` / `TOUR_API_SERVICE_KEY` 없음). 머지 후:

```bash
# 전체 daily (TourAPI 축제 backfill + 전 도시 culture). 시크릿은 Actions에 이미 있음.
# GitHub: Actions → daily-loond-worker → Run workflow

# 얇은 도시 culture만 (다른 도시 culture 행은 유지)
cd worker
export CULTURE_API_SERVICE_KEY=...   # 채팅·커밋에 넣지 말 것
python -m loond_worker.culture_collect --regions chungju,danyang,gapyeong,gunsan,sokcho,gongju,tongyeong,seongnam,buyeo,suncheon,geoje,bucheon
```

테스트: `cd worker && python3 -m unittest tests.test_r31_enjoy -v`
