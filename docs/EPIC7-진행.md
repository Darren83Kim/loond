# EPIC 7 진행 — 테스트 / 출시

> 시작: 2026-09-15  
> 갱신: 2026-09-15 (만료 제외 · 개인정보·스토어 초안)

## 목표
- 스모크: 빈 APPLY, 원문 CTA, 만료 제외 (+ 7-1a E2E)
- 스토어 메타·스크린샷
- 개인정보처리방침 URL
- 내부 테스트 → 제출 준비
- §11 전항 Open/Done/Deferred (7-1b)

## 체크리스트 (초안)
- [ ] 웹/기기: 메인→상세→원문 CTA — **7-1a E2E pending computerUse 결과**
- [ ] APPLY empty 카피 (ENJOY 미혼합) — 데이터로 재현 또는 위젯 테스트
- [x] applicationEnd 지난 APPLY 미노출 — `OpportunityBundle.applySorted`에서 `dDay < 0` 제외 (JSON에는 유지 OK). ENJOY는 `endDate` 지난 항목 선택적 숨김.
- [x] 개인정보처리방침 초안 — `docs/legal/privacy-policy.md` (한). 설정에서 GitHub blob URL 링크 (`배포 시 URL 교체`).
- [x] 스토어 리스팅 초안 — `docs/store/listing-ko.md` (이름·짧/긴 설명·키워드·스크린샷 체크리스트)
- [ ] §11 R1–R18 판정 (7-1b)

## 7-1 만료 제외 (구현 메모)
- **APPLY**: 피드 `applySorted`에서 `dDay == null || dDay >= 0`만 노출. `dDay`는 `applicationEnd ?? endDate` 기준(기존 getter). 과거 마감은 목록에서만 제외, published JSON 자체는 worker/에셋에 남을 수 있음.
- **ENJOY**: `endDate`가 있고 오늘보다 이전이면 `enjoySorted`에서 숨김. `endDate` null(상시)은 유지.
- 홈 UI는 기존처럼 `bundle.applySorted` / `enjoySorted`만 사용하면 됨.

## 개인정보·스토어
| 항목 | 경로 / URL |
|------|------------|
| 방침 초안 | `docs/legal/privacy-policy.md` |
| 임시 앱 링크 | https://github.com/Darren83Kim/loond/blob/main/docs/legal/privacy-policy.md |
| 리스팅 초안 | `docs/store/listing-ko.md` |

## 잔여
- 원문 CTA E2E (computerUse) 대기
- AdMob 프로덕션 ID 교체 — 출시 직전 (문서에 운영 ID 기재 금지)
- §11 전항 판정
## CTA E2E (웹)
- 2026-09-15: `LaunchMode.externalApplication` → about:blank 이슈
- 수정: `lib/util/open_url.dart` — 웹은 `platformDefault` + `_blank`
- 재시도: `url_launcher` `Link` 위젯(웹 DOM `<a target=_blank>`)으로 CTA 교체 — window.open 팝업차단/about:blank 회피
- 웹 CTA: `LinkTarget.self` / `webOnlyWindowName: _self` (같은 탭) — `_blank`는 스모크·일부 환경에서 about:blank
- 웹 CTA 최종: `web.window.location.assign(sourceUrl)` (같은 탭). `_blank`/Link 시그널 레이스는 about:blank. 스모크 시 Chrome에 남은 AdMob 탭은 오탐 주의.
- 웹 CTA: `dart.library.js_interop` → `location.assign` (dart.library.html만 쓰면 dart2js/wasm에서 IO launcher로 빠질 수 있음)

