# Multi-city TourAPI / culture (internal test)

Date: 2026-09-17

## Cities (RegionRegistry)

| id | name_ko | area_code | filter_keywords | culture_gugun |
|----|---------|-----------|-----------------|---------------|
| suwon | 수원 | 31 | 수원 | 수원시 |
| yongin | 용인 | 31 | 용인 | 용인시 |
| seongnam | 성남 | 31 | 성남 | 성남시 |
| goyang | 고양 | 31 | 고양 | 고양시 |
| bucheon | 부천 | 31 | 부천 | 부천시 |
| hwaseong | 화성 | 31 | 화성 | 화성시 |

Catalog: `worker/loond_worker/region_codes.py` → `REGIONS` (matches app `RegionRegistry`).

## TourAPI partition rules

1. Fetch Gyeonggi (`areaCode=31`) festivals (`searchFestival2`) + discover (`areaBasedList2`) **once**.
2. Assign each item to **at most one** city by addr1/addr2/title keywords.
3. Priority order = table order above (suwon → … → hwaseong).
4. **화성 vs 수원화성**: text containing `수원` → suwon (checked first); else `화성` → hwaseong.
5. Prefer `culture_gugun` (e.g. `성남시`) when present; guard `성남` vs `홍성남*`.
6. No keyword match → drop (not published).
7. Opportunity ids: `{region_id}-tour-{contentId}`.
8. Merge: keep **all APPLY**; keep culture ENJOY (`meta.source=culture_portal` or id contains `-culture-`); replace prior TourAPI `*-tour-*` ENJOY/DISCOVER.

## Culture portal

- `collect_enjoy_for_regions()` loops `REGIONS`.
- per city: `period2` keyword=`name_ko`, `area2` sido=경기 + gugun when known; blob must contain city name.
- ids: `{region_id}-culture-{seq}`.
- Soft-fail per city on API errors.
- Title-dedupe vs non-culture ENJOY **within the same region**.

## App

- `hasPublishedData` true when city has ≥1 opportunity after collect.
- Discover district chips (`suwonGus`) only when `regionId=='suwon'`.
- Traveler curated APPLY remains suwon-only (region filter).

## Deferred

- Municipal APPLY for non-suwon cities: **Deferred**.

## Collect counts (2026-09-17 KST)

| region | APPLY | ENJOY | DISCOVER |
|--------|-------|-------|----------|
| suwon | 12 | 32 | 100 |
| yongin | 0 | 9 | 165 |
| seongnam | 0 | 9 | 91 |
| goyang | 0 | 19 | 87 |
| bucheon | 0 | 12 | 69 |
| hwaseong | 0 | 13 | 107 |

- curated traveler APPLY: 5 (suwon)
- culture ENJOY: 56 (after 1 title-dedupe)
- TourAPI base on box: **HTTP** `apis.data.go.kr` (HTTPS TLS EOF)

## APPLY 소스 타입
- 초안: [`docs/ops/notice-source-types.md`](notice-source-types.md) (2026-09-17)

## Remote region load (P1 Done · P2 workflow)

- Per-region feeds + manifest are emitted on every publish sync:
  `data/published/regions/{id}.json`, `data/published/manifest.json`.
- Hosting = GitHub Pages. Workflow: `.github/workflows/pages.yml` (site root = `data/published/`).
- **P2 blocker**: repo is private on Free — Pages API 422. Make **Public** or upgrade **Pro**, then Settings → Pages → Source = GitHub Actions.
- Target URLs: `https://darren83kim.github.io/loond/manifest.json`, `.../regions/{id}.json`.
- See `docs/ops/remote-region-load.md`. **P3 app remote fetch still open**.
