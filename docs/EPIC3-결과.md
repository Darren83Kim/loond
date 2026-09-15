# EPIC 3 결과 — Flutter MVP (로온드)

작성 시각: 2026-09-14 18:15 KST (대략)

## 요약

EPIC 3 Flutter MVP 앱 코드를 완성했고, Flutter stable SDK를 `C:\flutter`에 설치했습니다.  
`flutter analyze` 이슈 없음. **Windows 데스크톱 빌드·Android debug APK 빌드 성공**.  
에뮬레이터/실기기는 아직 없음(AVD 미생성). AdMob·Score·회원가입·지도·알림은 구현하지 않음.

## 수행 내용

### 1. Flutter SDK

| 항목 | 내용 |
|------|------|
| 경로 | `C:\flutter` (`git clone … -b stable --depth 1`) |
| 버전 | Flutter **3.47.4** (stable), Dart **3.13.3** |
| PATH | 사용자 PATH에 `C:\flutter\bin` 추가 |
| 기존 깨진 SDK | `C:\DsDevelop\flutter` (bin/cache만 있고 `flutter.bat` 없음) — **사용하지 말 것** |

### 2. Android SDK

| 항목 | 내용 |
|------|------|
| SDK 경로 | `%LOCALAPPDATA%\Android\Sdk` |
| 구성 | cmdline-tools, platform-tools, platforms;android-35, build-tools;35.0.0 |
| JAVA | Android Studio JBR (`C:\Program Files\Android\Android Studio\jbr`) |
| 환경변수 | 사용자 `ANDROID_HOME` / `ANDROID_SDK_ROOT` → 위 SDK 경로로 설정 (기존 `C:\DsDevelop` 오설정 교정) |
| 라이선스 | 일부 수동 파일로 처리. `flutter doctor --android-licenses` 완전 통과는 미확인일 수 있음 |
| 에뮬레이터 | **미설치/미생성** — AVD 없음 |

참고: 프로젝트가 **E:**, Pub 캐시가 **C:** 인 경우 Kotlin incremental 캐시 오류가 나서  
`android/gradle.properties`에 `kotlin.incremental=false` 를 넣었습니다.

### 3. 앱 (EPIC 3)

- `flutter create . --project-name loond --org com.loond` (android/ios/windows/web 생성, 기존 `lib/` 유지)
- published JSON 동기화: `data/published/opportunities.json` → `app/assets/data/opportunities.json`
- `google_mobile_ads` **제거** (EPIC 6). `url_launcher`, `intl` 유지
- 모델: SCHEMA schemaVersion 1 정렬 (`summary` 필수, `meta.hasHwp` 선택 반영, Hard Sort)
- UI(한국어):
  - Main: NOW > APPLY / ENJOY **분리**, ANYTIME > DISCOVER, MY CHANCE **CTA만**
  - APPLY 0건 시 `"지금 신청 가능한 공고가 없어요"` (ENJOY로 채우지 않음)
  - Detail: 요약·D-Day·원문 CTA(`sourceUrl`)·HWP 안내·출처
  - Settings: 개인정보/출처/문의 플레이스홀더
  - AnalyticsStub: `opportunity_open`, `outbound_click` print

현재 published 피드: APPLY 3건, ENJOY/DISCOVER 0건 → ENJOY·DISCOVER는 Empty 카피 노출.

### 4. 검증

| 명령 | 결과 |
|------|------|
| `flutter pub get` | 성공 (`google_mobile_ads` 제거 확인) |
| `flutter analyze` | **No issues found** |
| `flutter devices` | Windows, Chrome, Edge (Android 기기/에뮬 없음) |
| `flutter build windows --debug` | 성공 → `build\windows\x64\runner\Debug\loond.exe` |
| `flutter build apk --debug` | 성공 → `build\app\outputs\flutter-apk\app-debug.apk` |

## 실행 방법

새 터미널에서 (PATH 반영 후):

```powershell
$env:Path = "C:\flutter\bin;" + $env:Path
$env:JAVA_HOME = "C:\Program Files\Android\Android Studio\jbr"
$env:ANDROID_HOME = "$env:LOCALAPPDATA\Android\Sdk"
cd E:\DsDevelop_Loond\app

# Windows 데스크톱
flutter run -d windows

# 또는 Chrome
flutter run -d chrome

# Android (기기/에뮬 연결 후)
flutter run -d android
# 또는 이미 빌드된 APK 설치
# adb install build\app\outputs\flutter-apk\app-debug.apk
```

데이터 갱신 시:

```powershell
Copy-Item E:\DsDevelop_Loond\data\published\opportunities.json `
  E:\DsDevelop_Loond\app\assets\data\opportunities.json -Force
```

## 주요 파일

- `app/lib/main.dart`
- `app/lib/ui/home_screen.dart`
- `app/lib/ui/detail_screen.dart`
- `app/lib/ui/settings_screen.dart`
- `app/lib/models/opportunity.dart`
- `app/lib/data/opportunity_repository.dart`
- `app/lib/analytics/analytics_stub.dart`
- `app/assets/data/opportunities.json`
- `app/pubspec.yaml`

## 남은 블로커

1. **Android Emulator / AVD 없음** — Studio에서 Device Manager로 시스템 이미지+AVD 생성 필요. 당분간 Windows/`chrome`/`apk`로 검증 가능.
2. **라이선스 완전 수락** — 필요 시 Android Studio 첫 실행 또는 `sdkmanager --licenses`로 잔여 라이선스 확인.
3. **깨진 `C:\DsDevelop\flutter`** — 혼동 방지를 위해 삭제 권장(선택).
4. iOS 빌드는 Windows에서 불가(정상).

## DoD 체크

- [x] main → detail → sourceUrl (url_launcher)
- [x] APPLY empty copy / ENJOY 독립 섹션
- [x] Hard Sort only (Score UI 없음)
- [x] published JSON 에셋 로드
- [x] 이벤트 스텁
- [x] 회원가입/Score/지도/알림/AdMob 미구현

---

## 잔여·이월

EPIC 1–3 감사에서 남은 항목은 `docs/구현계획서.md` **§11 잔여·이월 레지스터**에 모았다.  
뒤 에픽 Task(4-0, 4-7, 5-6, 5-7, 7-1a, 7-5) 또는 EPIC 7 최종 재점검(7-1b)에서 닫는다.

