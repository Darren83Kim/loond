# EPIC 5 진행 — 운영 자동화

> 시작: 2026-09-15 · 갱신: 2026-09-15 (KST)

## 목표
- GitHub Actions **일 1회** Worker (TourAPI KorService2)
- published JSON 갱신 + asset sync
- §11 R11–R14 (문화포털·증분동기화·코드확정·Actions sync)

## 현재
- [x] `.github/workflows/daily_worker.yml` 초안
- [x] repo secret `TOUR_API_SERVICE_KEY` 등록
- [x] `worker/loond_worker/run_tour_daily.py` — ENJOY(`searchFestival2`) + DISCOVER(`areaBasedList2`) → merge APPLY → published + raw
- [x] `tour_collect.py` — `STRATEGY=area_filter` 시 areaCode2 403/30 non-fatal (CI stub)
- [x] workflow_dispatch 성공 — https://github.com/Darren83Kim/loond/actions/runs/34944506091 (APPLY 3 / ENJOY 15 / DISCOVER 101)

## 일일 수집 요약
- Base: `https://apis.data.go.kr/B551011/KorService2`
- STRATEGY=`area_filter` (areaCode=31 + addr/title 「수원」)
- ENJOY: `searchFestival2` (eventStartDate ≈ year-start / today-30d)
- DISCOVER: `areaBasedList2` contentTypeId 12/14/25/28/38/39 · food/shopping cap ~30
- APPLY rows preserved; `suwon-tour-*` refreshed
- sourceName=`한국관광공사 TourAPI`; sourceUrl=detailCommon2 homepage 또는 visitkorea detail

```bash
cd worker
export TOUR_API_SERVICE_KEY=...   # never commit / never print
python -m loond_worker.run_tour_daily
```

## 메모
- Actions에서 `requests`는 TourAPI list 호출이 타임아웃/0건이 될 수 있음 → `urllib.request` + User-Agent 사용 (EPIC4 Windows와 동일).
- `areaCode2`는 HTTP 403/resultCode 30 가능; stub는 non-fatal, 일일 수집은 `run_tour_daily`.

## 비용/한도 메모
- Actions Free ~2,000분/월 → 일 1회 5–10분이면 충분
- TourAPI 개발 1,000회/일 → 앱 미호출, Worker만

## 마감
핵심 DoD PASS — 详见 `docs/EPIC5-결과.md`. 다음 EPIC 6.
