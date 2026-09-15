# 로온드 (Loond)

> **로온드 (Loond)** — *이 지역, 지금 뭐가 있지?*

## 문서
- [`docs/기획서.md`](docs/기획서.md)
- [`docs/구현계획서.md`](docs/구현계획서.md)
- [`docs/참고.md`](docs/참고.md)
- [`docs/EPIC1-PoC결과.md`](docs/EPIC1-PoC결과.md)
- [`docs/EPIC2-결과.md`](docs/EPIC2-결과.md)
- [`docs/EPIC3-결과.md`](docs/EPIC3-결과.md)
- [`docs/EPIC4-진행.md`](docs/EPIC4-진행.md) — **EPIC 4 scaffolding (4-0 / 4-7)**
- [`data/SCHEMA.md`](data/SCHEMA.md) — **정적 JSON 계약**

## 데이터
- published: [`data/published/opportunities.json`](data/published/opportunities.json)
- worker: `worker/` (`python -m loond_worker.run_poc`)
- TourAPI stub: `python -m loond_worker.tour_collect` (needs `TOUR_API_SERVICE_KEY` for live verify)
- Asset sync (EPIC 4-7): `./scripts/sync_published_assets.sh`

## 단계
기획 ✅ · 구현계획 ✅ · EPIC1 ✅ · EPIC2 ✅ · EPIC3 ✅ · **EPIC4** ⏳ (4-0 drafted, 4-7 sync script; awaiting API key for 4-1)
