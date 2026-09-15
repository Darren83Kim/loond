# 로온드 (Loond)

> **로온드 (Loond)** — *이 지역, 지금 뭐가 있지?*

## 문서
- [`docs/기획서.md`](docs/기획서.md)
- [`docs/구현계획서.md`](docs/구현계획서.md)
- [`docs/참고.md`](docs/참고.md)
- [`docs/EPIC1-PoC결과.md`](docs/EPIC1-PoC결과.md) … [`docs/EPIC5-결과.md`](docs/EPIC5-결과.md)
- [`docs/EPIC6-진행.md`](docs/EPIC6-진행.md) — **AdMob 테스트 유닛**
- [`data/SCHEMA.md`](data/SCHEMA.md) — 정적 JSON 계약

## 데이터
- published: [`data/published/opportunities.json`](data/published/opportunities.json)
- worker: `worker/` (`python -m loond_worker.run_poc`)
- TourAPI daily: `python -m loond_worker.run_tour_daily` (needs `TOUR_API_SERVICE_KEY`)
- Asset sync: `./scripts/sync_published_assets.sh`

## 앱
```bash
cd app && flutter pub get
flutter run -d chrome    # 광고 스킵
flutter run -d android   # Google 테스트 광고
```

## 단계
기획 ✅ · EPIC1–5 ✅ · **EPIC6 AdMob (테스트 ID)** ✅ · EPIC7 출시 ⏳
