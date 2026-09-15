# Play 내부 테스트 트랙 준비

> EPIC 7 · 출시 직전 내부 배포용 체크리스트 (한국어)  
> 리스팅 문구: [`listing-ko.md`](listing-ko.md) · 스크린샷: [`screenshots/`](screenshots/)

## 1. Play Console — 내부 테스트 (고수준)

1. [Google Play Console](https://play.google.com/console) → 앱 선택(없으면 앱 만들기).
2. **테스트 → 내부 테스트** 트랙 열기.
3. 새 릴리스 만들기 → **AAB** 업로드 → 릴리스 노트(한국어 짧게) → 검토·출시(내부).
4. **테스터** 탭에서 이메일 목록(또는 Google 그룹) 추가 후 저장.
5. 테스터에게 **옵트인 링크** 공유 → Play 스토어에서 내부 버전 설치.

> 프로덕션/비공개 테스트와 구분. 내부 트랙은 소규모·빠른 피드백용.

## 2. 빌드 (비밀 없이)

저장소 루트에서 앱 디렉터리로:

```bash
cd app   # 예: /home/box/projects/loond/app
flutter pub get
flutter build appbundle
```

- 산출: `app/build/app/outputs/bundle/release/app-release.aab`
- **서명 키·keystore·API 키는 repo에 넣지 않는다.** 로컬/`key.properties`(gitignore) 또는 CI secret만.
- 내부 테스트도 release AAB가 일반적. debug APK는 콘솔 업로드용이 아님.

Flutter SDK 예: `/home/box/flutter` (그록컴) 또는 로컬 설치 PATH.

## 3. 스토어 리스팅 필드

콘솔 입력 시 [`listing-ko.md`](listing-ko.md)를 따른다.

- 앱 이름·짧은 설명·긴 설명·카테고리·키워드
- 문의 메일 플레이스홀더 → 실제 연락처로 교체

## 4. 개인정보처리방침 URL

- 초안: [`docs/legal/privacy-policy.md`](../legal/privacy-policy.md)
- 임시(내부 OK):  
  `https://github.com/Darren83Kim/loond/blob/main/docs/legal/privacy-policy.md`
- 콘솔 **앱 콘텐츠 → 개인정보처리방침** 과 앱 설정 링크를 **동일 URL**로 맞춘다.
- 프로덕션 제출 전 전용 HTTPS 호스팅으로 교체 권장.

## 5. 스크린샷

경로: **`docs/store/screenshots/`**

현재 웹 프리뷰 4장(`01`–`04` …webp)은 **자리 표시**.  
내부·스토어 제출 전 **실기기(또는 에뮬) 세로 샷**으로 교체. 체크 항목은 `listing-ko.md` 참고.

## 6. AdMob

- **내부 테스트**: Google **테스트/샘플** 앱·유닛 ID 유지 OK (`ad_config.dart`).
- **프로덕션 공개 전**: §11 **R18** — 실 앱/유닛 ID + ATT/AD_ID 고지. 운영 ID는 문서에 적지 말 것.

## 7. 테스터 목록 (플레이스홀더)

| 이름/역할 | Google 계정 이메일 | 추가일 | 비고 |
|-----------|-------------------|--------|------|
| (본인) | _you@example.com_ | | |
| | | | |
| | | | |

콘솔 테스터 목록과 이 표를 맞춰 둔다.

## 8. 내부 스모크 (설치 후)

- [ ] 홈 로드 — APPLY / ENJOY / DISCOVER
- [ ] 상세 → 원문 CTA (실기기 1회 권장, §11 R7)
- [ ] 설정 → 개인정보처리방침 링크
- [ ] 광고 슬롯 레이아웃만 확인 (테스트 ID)
- [ ] 빈 APPLY 카피가 ENJOY와 섞이지 않음

## 관련

- [`EPIC7-진행.md`](../EPIC7-진행.md)
- [`구현계획서.md`](../구현계획서.md) §11 (R7·R8·R18)
