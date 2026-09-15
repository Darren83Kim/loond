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

## 지역 · TourAPI (EPIC 4-0)

- `region_id=suwon` / `region_name=수원` — see `loond_worker/region_codes.py` (also re-exported from `config`)
- `TOUR_API_AREA_CODE="31"` (경기도)
- Sigungu draft (TourAPI-relative, **not** 법정동): 장안=1, 권선=2, 팔달=3, 영통=4 — **`VERIFY_PENDING=True`** until `areaCode1` live check
- Strategy: `multi_sigungu` primary; fallback `FILTER_ADDR_KEYWORD="수원"`
- Base URL: `https://apis.data.go.kr/B551011/KorService1`
- Service key: env **`TOUR_API_SERVICE_KEY`** only (never commit)

```bash
# no key → exit 0 with message (CI-safe)
python -m loond_worker.tour_collect

# with key → areaCode1 for 31, writes data/raw/tourapi_*.json
export TOUR_API_SERVICE_KEY=your_key
python -m loond_worker.tour_collect
```

## published → app asset sync (EPIC 4-7)

From repo root:

```bash
./scripts/sync_published_assets.sh
# or: python3 scripts/sync_published_assets.py
```

Copies `data/published/opportunities.json` → `app/assets/data/opportunities.json`.
