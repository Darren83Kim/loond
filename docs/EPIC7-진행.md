# EPIC 7 진행 — 테스트 / 출시

> 시작: 2026-09-15  
> 갱신: 2026-09-15 (§11 R9/R15/R16 Done · 내부 테스트 문서)

## 목표
- 스모크: 빈 APPLY, 원문 CTA, 만료 제외 (+ 7-1a E2E)
- 스토어 메타·스크린샷
- 개인정보처리방침 URL
- 내부 테스트 → 제출 준비
- §11 전항 Open/Done/Deferred (7-1b)

## 체크리스트 (초안)
- [x] 웹 CTA 배선 — **7-1a 배선 Done** (`location.assign` + example.com). 목적지 Windows 브라우저 OK; **앱 내 클릭** Deferred (R7)
- [x] APPLY empty 카피 (ENJOY 미혼합) — UI 기존 + `app/test/home_empty_apply_test.dart`
- [x] applicationEnd 지난 APPLY 미노출 — `applySorted` + `app/test/opportunity_bundle_test.dart`
- [x] ENJOY `endDate` 지난 항목 숨김 — `enjoySorted` + 동일 단위 테스트
- [x] 개인정보처리방침 초안 — `docs/legal/privacy-policy.md` (한). 설정에서 GitHub blob URL 링크 (`배포 시 URL 교체`).
- [x] 스토어 리스팅 초안 — `docs/store/listing-ko.md`
- [x] §11 R1–R18 1차 판정 (7-1b) — `docs/구현계획서.md` §11
- [x] pending→published 검증 체크리스트 — `docs/ops/pending-publish-checklist.md` (R15)
- [x] Actions 실패 시 GitHub Issue — `daily_worker.yml` (R16)
- [x] EPIC 메모 `E:\` 실행 안내 정리 — GitHub/`/home/box/projects/loond` (R9)
- [x] Play 내부 테스트 준비 문서 — `docs/store/internal-test.md`
- [ ] Play Console 내부 테스트 트랙에 AAB 업로드·테스터 추가 (실행은 사람)
- [ ] 스크린샷을 실기기 샷으로 교체 (`docs/store/screenshots/`)

## 7-1 만료 제외 (구현 메모)
- **APPLY**: 피드 `applySorted`에서 `dDay == null || dDay >= 0`만 노출. `dDay`는 `applicationEnd ?? endDate` 기준(기존 getter). 과거 마감은 목록에서만 제외, published JSON 자체는 worker/에셋에 남을 수 있음.
- **ENJOY**: `endDate`가 있고 오늘보다 이전이면 `enjoySorted`에서 숨김. `endDate` null(상시)은 유지.
- 홈 UI는 기존처럼 `bundle.applySorted` / `enjoySorted`만 사용하면 됨.
- 테스트: `opportunity_bundle_test.dart` (만료), `home_empty_apply_test.dart` (빈 APPLY + ENJOY 비혼합).

## 개인정보·스토어
| 항목 | 경로 / URL |
|------|------------|
| 방침 초안 | `docs/legal/privacy-policy.md` |
| 임시 앱 링크 | https://github.com/Darren83Kim/loond/blob/main/docs/legal/privacy-policy.md |
| 리스팅 초안 | `docs/store/listing-ko.md` |
| 내부 테스트 | `docs/store/internal-test.md` |
| 검증 체크리스트 | `docs/ops/pending-publish-checklist.md` |

## 잔여
- 수원 원문: 목적지 Windows 확인됨; **앱 내 CTA 클릭**은 스토어 전 선택 (R7 Deferred)
- Android 에뮬/실기기 스모크 (R8)
- AdMob 프로덕션 ID 교체 — 출시 직전 (문서에 운영 ID 기재 금지) (R18)
- Play 내부 테스트 트랙 실제 업로드·테스터 초대 (`docs/store/internal-test.md`)
- §11 Deferred: R1/R2/R3/R5/R8/R11/R12/R13/R18 (+ R7) — 출시 후/키·기기 확보 후

## CTA E2E (웹)
- 2026-09-15: `LaunchMode.externalApplication` → about:blank 이슈
- 수정: `lib/util/open_url.dart` — 웹은 `platformDefault` + `_blank`
- 재시도: `url_launcher` `Link` 위젯(웹 DOM `<a target=_blank>`)으로 CTA 교체 — window.open 팝업차단/about:blank 회피
- 웹 CTA: `LinkTarget.self` / `webOnlyWindowName: _self` (같은 탭) — `_blank`는 스모크·일부 환경에서 about:blank
- 웹 CTA 최종: `web.window.location.assign(sourceUrl)` (같은 탭). `_blank`/Link 시그널 레이스는 about:blank. 스모크 시 Chrome에 남은 AdMob 탭은 오탐 주의.
- 웹 CTA: `dart.library.js_interop` → `location.assign` (dart.library.html만 쓰면 dart2js/wasm에서 IO launcher로 빠질 수 있음)

## 7-1a 원문 CTA E2E (2026-09-15)

- 웹 구현: `openOutboundUrl` → `dart.library.js_interop` + `window.location.assign` (같은 탭). 모바일은 `url_launcher` externalApplication.
- **배선 스모크 PASS**: 임시 `sourceUrl=https://example.com/` → CTA 클릭 → 같은 탭 `https://example.com/` 확인.
- **수원 원문 목적지**: Grok Bot 컴퓨터에서 `https://www.suwon.go.kr/...` TLS 실패(`unexpected eof`) — Chrome 탭이 닫힘. TourAPI와 동일 계열 네트워크/TLS 제약. JSON의 `sourceUrl`은 정식 수원 URL로 유지.
- 판정: **코드·배선 Done / 수원 목적지 E2E는 Windows PC·실기기에서 확인 (Deferred)**.
- **Windows PC (2026-09-15)**: `suwon.go.kr` APPLY 원문 URL `curl` **HTTP 200** (TLS OK). 기본 브라우저로 동일 URL 오픈. 앱 내 CTA 클릭 E2E는 로컬 Flutter 미리보기에서 추가 확인 권장.

## 스토어 스크린샷
- 웹 프리뷰 4장 → `docs/store/screenshots/` (2026-09-15)

## 내부 테스트 AAB (2026-09-15)

- Windows PC에서 `flutter build appbundle` **성공** → `app-release.aab` (~49MB)
- 경로(로컬): `C:\Users\round1studio_34\loond\app\build\app\outputs\bundle\release\app-release.aab`
- `google_mobile_ads` **9.1.0** (AGP 9 호환; 5.3.1은 bundleRelease 실패)
- release signing은 아직 **debug** — Play 업로드 전 upload keystore 권장
- 체크리스트: `docs/store/internal-test.md` §9

