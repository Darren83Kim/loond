# EPIC 6 진행 — AdMob (테스트 유닛)

> 시작: 2026-09-15 · 갱신: 2026-09-15 (KST)

## 목표
- Google **sample/test** Ad Unit ID만 사용 (실키·AdMob 계정 불필요)
- 배너 + 네이티브(~4카드) + 전면(세션 ≤1, 상세 이탈 후)
- 웹은 광고 스킵 (크래시 금지)
- 「광고」 라벨 · 원문 CTA 비차단 · 1·2번째 카드/CTA 전후 금지

## 구현 요약
| 항목 | 내용 |
|------|------|
| 패키지 | `google_mobile_ads: ^5.3.1` |
| Init | `lib/ads/ads_init.dart` — conditional IO/stub; web no-op |
| 테스트 App ID | Android `…~3347511713` / iOS `…~1458002511` |
| Banner | `…/6300978111` — 홈 `bottomNavigationBar` |
| Native | `…/2247696110` — `NativeTemplateStyle` medium, 카드 톤 |
| Interstitial | `…/1033173712` — 상세 `pop` 후 ≤1/session |
| Analytics | `AnalyticsStub.adImpression` (print) |

## 슬롯 규칙
- 글로벌 카드 index `i`: 광고는 `i>=2 && (i-2)%4==0` 직후 삽입 → 위치 3,7,11…
- 상세 화면·원문 CTA 주변에 광고 위젯 없음
- 전면은 Home에서 `Navigator.push` await 후 `maybeShowAfterDetailPop`

## 검증
```bash
cd app
flutter pub get
flutter analyze
flutter run -d chrome          # 광고 없음, 앱 정상
flutter run -d <android>       # 테스트 배너/네이티브/전면
```

## DoD
- [x] 테스트 ID만 사용
- [x] 웹 스킵 (conditional import + `AdConfig.adsEnabled`)
- [x] 레이아웃 규칙 준수
- [x] impression 훅 (`ad_impression` print)
- [ ] 실기기에서 테스트 광고 육안 확인 (에뮬/실기) → EPIC 7 스모크와 함께

## 이월
- 6-4 출시 전 실 유닛·ATT/AD_ID 고지 → EPIC 7 / 스토어
