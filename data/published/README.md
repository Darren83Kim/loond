# published 피드

- `opportunities.json` — 통합 피드 (앱 에셋·디버그용; schemaVersion 1)
- `opportunities.example.json` — 최소 예시
- `manifest.json` — 시별 원격 로드용 인덱스 (etag/bytes/counts; remote-load P1)
- `regions/{regionId}.json` (+ optional `.json.gz`) — 시별 피드
- 계약: `../SCHEMA.md`
- 설계: `docs/ops/remote-region-load.md`
