# EPIC 4 진행 — ENJOY / DISCOVER

작성: 2026-09-15 (KST) · 갱신: 2026-09-15 14:34 KST

## 상태 요약

| Task | 상태 | 비고 |
|------|------|------|
| **4-0** TourAPI 수원 area/sigungu 상수 | **updated** | `region_codes.py` — KorService2; `STRATEGY=area_filter`; `VERIFY_PENDING=True` (areaCode2 key scope fail) |
| **4-1** TourAPI 키·축제(ENJOY) | **done (partial)** | Windows PC live: `searchFestival2` → 수원 **15** ENJOY published |
| **4-3** TourAPI DISCOVER | **done (partial)** | `areaBasedList2` + 수원 filter → **102** DISCOVER published (food capped 30) |
| 4-2 문화포털 | 대기 | 키 이후 |
| 4-4~4-6 | 부분 | 중복은 contentId 기준; 문화포털 병합 전 |
| **4-7** published→asset 동기화 | **run** | `scripts/sync_published_assets.py` |

## Live 수집 결과 (2026-09-15)

- Base: `https://apis.data.go.kr/B551011/KorService2` (**not** KorService1 — retired / NO_OPENAPI_SERVICE)
- Host: USER Windows PC (box TLS to `apis.data.go.kr` fails)
- `searchFestival2`: areaCode=31 alone thin; **nationwide + addr/title `수원`** → 15 festivals
- Draft sigungu 1–4 under area 31 → **0** festival rows
- `areaBasedList2` contentTypeId 12/14/25/28/38/39 + 수원 filter → 264 raw; published curated 102
- `areaCode2?areaCode=31` → resultCode **30** 등록되지 않은 서비스키 (list APIs OK with same key)
- Empirical: legacy `sigungucode≈13` on Suwon rows; legal-dong `41` + `{111,113,115,117}`

Raw: `data/raw/festivals_raw.json`, `discover_raw.json`, `summary.txt`

## 4-0 상수 (현행)

- `REGION_ID=suwon` / `REGION_NAME=수원`
- `TOUR_API_AREA_CODE="31"` (경기도)
- `STRATEGY="area_filter"` — primary: area/nationwide + `FILTER_ADDR_KEYWORD="수원"`
- Legal-dong helpers: `TOUR_API_LDONG_REGN=41`, signgu 111/113/115/117
- Base: `https://apis.data.go.kr/B551011/KorService2`
- Key: env `TOUR_API_SERVICE_KEY` only (URL-encoded form OK if spliced without re-encoding)

```bash
cd worker
export TOUR_API_SERVICE_KEY=...   # never commit
python -m loond_worker.tour_collect
```

## Published counts (after merge)

| type | count |
|------|------:|
| APPLY | 3 |
| ENJOY | 15 |
| DISCOVER | 102 |
| **total** | **120** |

`sourceName=한국관광공사 TourAPI`; `sourceUrl` = detailCommon2 homepage when present, else `https://korean.visitkorea.or.kr/detail/ms_detail.do?cotid={contentid}` (fest: `fes_detail.do`).

## 4-7

```bash
python3 scripts/sync_published_assets.py
```

## 하지 않음 / 남은 것

- 문화포털(4-2)
- areaCode2 formal VERIFY flip (`VERIFY_PENDING` still True)
- DISCOVER food full dump (raw 192; published cap 30)
