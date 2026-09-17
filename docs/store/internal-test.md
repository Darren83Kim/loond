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

## 9. Windows PC 빌드 메모 (DESKTOP-SRFAJQ8)

```powershell
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:ANDROID_HOME = "$env:USERPROFILE\AppData\Local\Android\Sdk"
$env:PATH = "$env:JAVA_HOME\bin;C:\flutter\bin;" + $env:PATH
cd $env:USERPROFILE\loond\app   # git bundle로 동기화한 작업본
flutter pub get
flutter build appbundle
```

- 산출: `app\build\app\outputs\bundle\release\app-release.aab`
- 현재 `android/app/build.gradle.kts` release는 **debug signing**을 씀 → 내부 스모크용 가능하나, Play 업로드 전 **upload keystore + key.properties**(gitignore)로 교체 권장.
- Android 라이선스: `sdkmanager --licenses` (JAVA_HOME을 Android Studio JBR로).
- 로컬 경로: `C:\Users\round1studio_34\loond` (GitHub private clone 대신 box `git bundle`로 동기화 가능).

## 10. 내부 테스트 세팅 런북 (2026-09-17)

목표: **Play 내부 테스트 트랙에 서명 AAB를 올리고**, 테스터가 옵트인 링크로 설치한 뒤 **6도시 스모크**를 돌린다.

### 0) 용어 정리 (헷갈리기 쉬운 부분)

| 트랙 | 용도 | 테스터 수 |
|------|------|-----------|
| **내부 테스트** | 우리끼리 빠른 배포 | 소수 OK (본인+지인) |
| **비공개(클로즈드) 테스트** | 신규 개인 개발자 계정의 **프로덕션 진입 조건**에 자주 필요 | 보통 **12명 · 14일** |
| 프로덕션 | 스토어 공개 | 위 조건 충족 후 |

「테스터 12명」은 대개 **클로즈드→프로덕션** 게이트다. 내부 테스트만 먼저 돌려도 되고, 출시까지 보려면 12명을 클로즈드에도 넣어 두면 한 번에 해결된다.

### 1) 로컬에서 할 일 (에이전트/PC)

- [ ] `app/android/key.properties` + upload `.jks` 생성 (gitignore, repo 금지)
- [ ] `flutter build appbundle` → `app/build/app/outputs/bundle/release/app-release.aab`
- [ ] 패키지 ID: `com.loond.loond` (build.gradle과 콘솔 동일)
- [ ] PC 체크아웃을 `main` 최신(P3 원격 로드 포함)으로 맞춤

### 2) Play Console — 앱·정책 (최초 1회)

- [ ] 앱 만들기 (또는 기존 앱 선택) · 기본 언어 한국어
- [ ] 스토어 설정: [`listing-ko.md`](listing-ko.md) 문구 붙여넣기
- [ ] 그래픽: `docs/store/play/icon-512.png`, `feature-graphic.png`
- [ ] 휴대폰 스크린샷: `docs/store/screenshots/phone/01`–`06` (세로)
- [ ] 개인정보처리방침 URL (콘솔·앱 설정 동일):  
  `https://github.com/Darren83Kim/loond/blob/main/docs/legal/privacy-policy.md`
- [ ] 앱 콘텐츠: 광고 선언(AdMob), 콘텐츠 등급, 대상 연령, 데이터 보안 설문
- [ ] 국가/지역: 한국 우선

### 3) 내부 테스트 트랙

- [ ] 테스트 → 내부 테스트 → 새 릴리스 → **AAB 업로드**
- [ ] 릴리스 노트 예: `내부 테스트: 지역별 원격 피드(P3), 경기 6도시 ENJOY/DISCOVER, 수원 APPLY`
- [ ] 검토 후 **내부 테스트로 출시**
- [ ] 테스터 → 이메일 목록(또는 Google 그룹) 저장 → **옵트인 링크** 복사

### 4) 테스터 12명 (출시까지 볼 때)

- [ ] 스프레드시트/아래 표에 Google 계정 이메일 12개 확보
- [ ] **내부 테스트** + (가능하면) **비공개 테스트** 양쪽에 동일 목록
- [ ] 옵트인 링크·「Play 스토어에서 테스터로 참여」안내 문구 공유
- [ ] 설치 확인 체크 (이름 / 설치일 / 기기)

| # | 이름 | Google 이메일 | 내부 | 클로즈드 | 설치확인 |
|---|------|---------------|------|----------|----------|
| 1 | (본인) | | ☐ | ☐ | ☐ |
| 2–12 | | | ☐ | ☐ | ☐ |

### 5) 설치 후 스모크 (6도시 · 티어별)

**공통 (모든 시)**

- [ ] 지역 전환 시 로딩 후 피드 갱신 (원격 P3)
- [ ] ENJOY / DISCOVER 카드·상세·원문 CTA
- [ ] 다른 시 콘텐츠가 섞이지 않음 (제목·장소)
- [ ] 오프라인: 수원 시드 또는 캐시된 시만

**수원 (Deep-A)**

- [ ] APPLY 목록·마감·주민/여행 필터
- [ ] 예약 큐레이션(여행 모드) 노출

**용인·성남·고양·부천·화성 (Auto)**

- [ ] ENJOY/DISCOVER 위주 · APPLY는 있으면 샘플만
- [ ] 고양: 「고양이」 오분류 재발 없음

### 6) 피드백 수집 (R20)

- 거슬림 / 빈칸 / 잘못된 지역 / CTA 깨짐 / 느린 지역 전환
- 이슈는 `docs/구현계획서.md` §11 또는 채팅으로

### 관련 경로

- AAB: `app/build/app/outputs/bundle/release/app-release.aab`
- 서명: `app/android/key.properties`, `app/android/upload-keystore.jks` (로컬만)
- 원격 피드: `https://darren83kim.github.io/loond/`
