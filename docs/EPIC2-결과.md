# EPIC 2 결과 — 정적 데이터 계약

> 2026-09-14 · DoD 충족

## TL;DR

Worker와 Flutter가 같은 **`opportunities.json` (schemaVersion 1)** 을 쓴다.  
실데이터는 EPIC 1 published 3건을 계약에 맞게 정규화했다.

## DoD

| 조건 | 결과 |
|------|------|
| Worker·앱 동일 스키마 | PASS — `data/SCHEMA.md` |
| 예시 파일 | PASS — `data/published/opportunities.example.json` |
| 루트 포맷 | PASS — schemaVersion, region, regionLabel, updatedAt, opportunities[] |
| ENJOY/DISCOVER | PASS — **같은 배열 + type 필터** (빈 type = Empty UI) |
| fetch/캐시 | PASS — SCHEMA §4 (`?v=` 버스팅, CORS) |

## 변경 요지

- 루트에 `schemaVersion: 1`
- 파이프라인 전용 필드를 **`meta`** 로 이동 (앱 필수 필드와 분리)
- `region_name` 중복 제거 → `region` + 루트 `regionLabel`

## 다음

EPIC 3: Flutter가 `opportunities.json` 로드 → APPLY 리스트·상세·원문 (에뮬 확인)
