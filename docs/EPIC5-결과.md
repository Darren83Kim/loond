# EPIC 5 결과 — 운영 자동화 (핵심)

> 작성: 2026-09-15

## TL;DR

| 질문 | 답 |
|------|-----|
| Actions 일 1회 Worker? | **워크플로 활성** + `workflow_dispatch` **성공** |
| 앱이 TourAPI 호출? | **안 함** — published JSON만 |
| Secret | `TOUR_API_SERVICE_KEY` 등록됨 |
| 성공 런 | https://github.com/Darren83Kim/loond/actions/runs/34944506091 |

## DoD (핵심)

| 조건 | 결과 |
|------|------|
| 스케줄/수동 1회 성공 로그 | PASS (`workflow_dispatch`) |
| Actions에 asset sync | PASS (5-1a / R14) |
| 검증 체크리스트 1쪽 (5-4) | **Done** — `docs/ops/pending-publish-checklist.md` (R15) |
| 문화포털·증분동기화·sigungu | 이월 R11–R13 |
| CORS/`?v=` (5-6) | 이월 (Phase A asset) |
| HWP 운영 루틴 (5-7) | 이월 |

## 기술

- `worker/loond_worker/run_tour_daily.py` — KorService2 + urllib
- `.github/workflows/daily_worker.yml` — cron `0 0 * * *` (09:00 KST)
- `tour_collect` areaCode2 실패는 `area_filter`에서 non-fatal

## 다음

EPIC 6 AdMob (테스트 유닛). R15–R17 Done. 잔여 R11–R13 등은 §11.
