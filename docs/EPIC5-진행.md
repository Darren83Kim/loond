# EPIC 5 진행 — 운영 자동화

> 시작: 2026-09-15

## 목표
- GitHub Actions **일 1회** Worker (TourAPI KorService2)
- published JSON 갱신 + asset sync
- §11 R11–R14 (문화포털·증분동기화·코드확정·Actions sync)

## 현재
- [x] `.github/workflows/daily_worker.yml` 초안
- [ ] repo secret `TOUR_API_SERVICE_KEY` 등록 (GitHub → Settings → Secrets)
- [ ] `run_tour_daily.py` 본문 (PC에서 검증된 수집 로직 이식; 증분은 R12)
- [ ] workflow_dispatch 1회 성공 로그 (DoD)

## 비용/한도 메모
- Actions Free ~2,000분/월 → 일 1회 5–10분이면 충분
- TourAPI 개발 1,000회/일 → 앱 미호출, Worker만
