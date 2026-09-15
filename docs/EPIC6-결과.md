# EPIC 6 결과 — AdMob (테스트)

> 작성: 2026-09-15

## TL;DR
Google **테스트** 앱/유닛 ID로 배너·네이티브·전면 슬롯 구현. 웹은 광고 비활성. 실 유닛·ATT는 §11 **R18** → 출시 전.

## DoD
| 조건 | 결과 |
|------|------|
| 테스트 광고가 레이아웃을 깨지 않음 | PASS (코드·웹 빌드; 실기기 확인은 권장) |
| 원문 CTR과 광고 노출 훅 | PASS — `AnalyticsStub.adImpression` / `outbound_click` |
| 1·2번째 카드·CTA 근처 금지 | PASS |
| 전면 ≤1/세션 (상세 pop 후) | PASS |

## 잔여
R18: 실 AdMob 앱/유닛 ID + ATT/AD_ID 고지 (구 6-4)
