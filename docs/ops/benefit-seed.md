# BENEFIT 시드 (수원 맞춤 혜택)

상태: **Live seed** — 2026-09-21 (eligibility hard gates)  
관련: `docs/design/my-chance-profile-draft.md`, `BenefitProfile` + `meta.eligibility`, Pages `regions/suwon.json`

## 목적

「맞춤 혜택」이 빈 CTA만 보이지 않도록, **보조금24/복지로 API 스크랩 없이** 공식 안내 URL이 있는 수원(·전국제도 수원 안내) BENEFIT를 소량 시드한다.

앱은 수급 심사가 아니며, 카드 → `sourceUrl` 원문 확인이 본선이다.  
다만 curated 시드는 **`meta.eligibility` hard gate**로 명백히 비대상(연령·자녀 밴드)인 카드를 숨긴다. soft score는 통과 항목 순위만 결정.

## meta.eligibility (Opportunity)

JSON under `meta.eligibility` (앱: `BenefitEligibility`):

| 필드 | 타입 | 의미 |
|------|------|------|
| `ageMin` / `ageMax` | int? | 출생연도 기준 `ageInYear` inclusive. 프로필에 출생연도 없으면 연령 게이트 스킵(명백 실패 아님). |
| `childAgeBands` | string[] | any-of. wire = `infant0_2` / `preschool3_5` / `elementary6_12` / `teen13_18` / `pregnancy_planned` (프로필 칩과 동일). 프로필이 구체 밴드를 골랐고 교집합 없으면 제외. |
| `requiresChild` | bool | `hasChild != true`이면 제외. |

파서: `Opportunity.fromJson` → `meta.eligibility`. 매칭: `passesBenefitEligibility` → `buildMatchedBenefitFeed`만 hard exclude. 「관련 신청」APPLY는 soft만.

## 현재 시드 (suwon · type=`BENEFIT`)

| id | 제목 | eligibility | sourceUrl |
|----|------|-------------|-----------|
| `suwon-benefit-youth-basic-income` | 청년기본소득 (경기도·수원) | ageMin 23 · ageMax 25 (공식 만 24세 + 출생연도 여유) | [welfare14-04-03](https://www.suwon.go.kr/sw-www/deptHome/dep_welfare/welfare14/welfare14-04/welfare14-04-03.jsp) |
| `suwon-benefit-parental-benefit` | 부모급여 | requiresChild + `infant0_2` (0–23개월) | [welfare14-02-01](https://www.suwon.go.kr/sw-www/deptHome/dep_welfare/welfare14/welfare14-02/welfare14-02-01.jsp) |
| `suwon-benefit-child-allowance` | 아동수당 | requiresChild + infant/preschool/elementary (만 9세 미만; 고학년 초등 over-include 가능) | [welfare14-02-10](https://www.suwon.go.kr/sw-www/deptHome/dep_welfare/welfare14/welfare14-02/welfare14-02-10.jsp) |
| `suwon-benefit-housing-benefit` | 주거급여 | (없음 — 소득 기준, 연령 게이트 없음) | [city09_01](https://www.suwon.go.kr/sw-www/deptHome/dep_city/city09/city09_01.jsp) |
| `suwon-benefit-youth-housing` | 청년주거급여 | ageMin 19 · ageMax 34 (GG 청년 밴드) | 동일 주거급여 안내 URL |
| `suwon-benefit-birth-grant` | 자녀 출산·입양 지원금 | requiresChild + `pregnancy_planned`\|`infant0_2` | [welfare14-01-10](https://www.suwon.go.kr/sw-www/deptHome/dep_welfare/welfare14/welfare14-01/welfare14-01-10.jsp) |

공통:

- `meta.source` = `curated_benefit`
- `category` = `welfare_support`
- `status` = `published`, `applicationEnd` = null → UI D-Day 「상시」

기간제(예: 청년 주거 패키지 2026.1 모집)는 **마감된 창을 시드하지 않음**.

## 데이터 경로

1. **소스 of truth**: `data/published/opportunities.json` (통합 디버그 피드)
2. `python3 scripts/sync_published_assets.py` 또는 `python -m loond_worker.publish_regions --sync-assets`
   - → `data/published/regions/suwon.json` (+ `.gz`)
   - → `data/published/manifest.json`
   - → `app/assets/data/opportunities.json` (**수원 시드만**)
3. **폰 원격**: push `main` + `data/published/**` → Actions `deploy-pages` →  
   `https://darren83kim.github.io/loond/regions/suwon.json`
4. **버전 bump**: eligibility **Dart 매칭** 변경 시 app version 필요 (예: `0.1.6+7`). JSON-only면 Pages 재배포만으로 충분.

## Tour daily 보존

`run_tour_daily.merge_and_publish`는 APPLY + **BENEFIT** + culture_portal ENJOY를 유지하고 TourAPI ENJOY/DISCOVER만 교체한다.  
시드를 넣지 않으면 다음 daily에 BENEFIT가 사라지므로, 신규 항목은 반드시 통합 JSON에 넣고 sync 후 커밋.

## 새로고침 절차

1. 공식 페이지에서 자격·금액·신청 창 확인.
2. Opportunity + `meta.eligibility` 작성 (`type: BENEFIT`, `meta.source: curated_benefit`).
3. `data/published/opportunities.json`에 upsert.
4. `python3 scripts/sync_published_assets.py`
5. APPLY/ENJOY counts 회귀 확인 후 commit + push → Pages 배포.
6. 폰: 앱 재실행 또는 지역 재선택으로 remote refresh. **매칭 로직 변경 APK**가 있으면 업데이트 설치 필요; JSON-only eligibility면 원격 갱신만으로 게이트 적용(구버전 앱은 eligibility 무시·구 soft만).

## 비범위

- 보조금24/복지로 API 조건 매칭
- 소득·재산 하드 필터
- 타 시 BENEFIT 대량 시드
