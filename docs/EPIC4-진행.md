# EPIC 4 진행 — ENJOY / DISCOVER

작성: 2026-09-15 (KST)

## 상태 요약

| Task | 상태 | 비고 |
|------|------|------|
| **4-0** TourAPI 수원 area/sigungu 상수 | **drafted** | `worker/loond_worker/region_codes.py` — `VERIFY_PENDING=True` |
| **4-1** TourAPI 키·축제(ENJOY) | **blocked** | `TOUR_API_SERVICE_KEY` 필요; live `areaCode1` verify |
| 4-2 문화포털 | 대기 | 키/4-1 이후 |
| 4-3~4-6 | 대기 | ENJOY/DISCOVER 병합은 성공 API 호출 후에만 |
| **4-7** published→asset 동기화 | **scaffolded** | `scripts/sync_published_assets.sh` (+ `.py`) |

## 4-0 잠정 상수

- `REGION_ID=suwon` / `REGION_NAME=수원`
- `TOUR_API_AREA_CODE="31"` (경기도)
- Sigungu (TourAPI-relative, **not** 법정동): 장안=1, 권선=2, 팔달=3, 영통=4 — **areaCode1으로 검증 필수**
- Strategy: `multi_sigungu` primary; fallback `FILTER_ADDR_KEYWORD="수원"`
- Base: `https://apis.data.go.kr/B551011/KorService1`
- Key: env `TOUR_API_SERVICE_KEY` only

검증 스텁:

```bash
cd worker
export TOUR_API_SERVICE_KEY=...   # never commit
python -m loond_worker.tour_collect
```

키 없으면 exit 0 (CI-safe). 키 있으면 `data/raw/tourapi_area_codes_31.json` 및 `tourapi_suwon_codes_verified.json` 기록.

## 4-7

```bash
./scripts/sync_published_assets.sh
# or: python3 scripts/sync_published_assets.py
```

`data/published/opportunities.json` → `app/assets/data/opportunities.json`

## 하지 않음 (이번 커밋)

- 전체 ENJOY 병합 / festival invent — API 키·성공 호출 전 금지
- 문화포털(4-2) 수집
