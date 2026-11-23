# 프로덕션 출시 계획 (감사 기준)

- 작성: **2026-10-16 (KST)**
- 대상: 로온드 Android (`com.loond.loond`). 정부·지자체 공식 앱이 아님.
- 현재 클로즈드 빌드: `app/pubspec.yaml` **0.1.9+10** (versionName 0.1.9, versionCode 10).
- 게시 피드 스냅샷: `data/published/manifest.json` `updatedAt` **2026-10-15T12:28:23+09:00**, 지역 34.
- 프로덕션 액세스: **2026-10-16 신청**. 심사 기간은 최대 약 7일(콘솔 안내). **승인 여부는 이 감사에서 확인하지 않음.**
- 범위: 출시 전 감사와 순서. 기능 구현 없음.
- 근거: `docs/store/production-launch-checklist.md`, `docs/구현계획서.md` §11, `docs/region-expansion-plan.md`, `docs/design/CONCEPT.md` · `loond-concept-mockup.png`, 앱·워커·게시 JSON.

## 이 감사에서 확인하지 않은 것

아래는 추측하지 않는다.

- Play Console 사전 출시 보고서 원문, 테스터 수·연속 일수, 데이터 보안 설문에 이미 저장된 답.
- 0.1.9를 만든 Flutter SDK 버전. `compileSdk` / `targetSdk`는 `flutter.compileSdkVersion` / `flutter.targetSdkVersion`이라 숫자 API 레벨은 SDK에 달려 있고, 이 환경에는 Flutter가 없다.
- 병합된 release 매니페스트(`AD_ID` 권한이 라이브러리에서 실제로 붙는지).
- 업로드 키스토어가 어느 기기에 있는지. 이 체크아웃에는 `app/android/key.properties`와 `*.jks`가 없다(gitignore가 맞다).
- 2026-09-29 지역 계획서 이후 광역시 게시판 HTTP 재조사. 아래 난이도는 그 계획서와 현재 코드 기준이다.
- 2026-10-02 daily 런의 Actions 로그. 부산 시청 공고 행이 그 커밋에서 사라진 사실은 git으로 확인했고, 런타임 실패 메시지는 보지 못했다.
- 실기기 레이아웃. 넘침·시스템 바 겹침은 코드상 위험으로만 적는다.

공수: **S** 문구·한 화면·설정, **M** 여러 파일과 실기기 확인, **L** 새 수집기·외부 키·불안정 사이트. 이번 심사 대기(약 1주) 안에 L를 끝내는 전제는 두지 않는다.

---

## 0. 결론

프로덕션에 **0.1.9를 그대로 올리지 않는 쪽**이 맞다. 광고는 Google 샘플 ID이고, 부산은 카탈로그상 시청 공고 제공(`applyStatus=provided`)인데 2026-10-15 피드의 APPLY 11건은 전부 한국관광공사 TourAPI다. 더보기·설정의 앱 버전 문구는 **0.1.7**로 남아 있다.

심사 대기 동안 손댈 것은 광고 ID(또는 광고 끄기), 부산 표기, 사용자에게 보이는 내부 문구·개인정보 방침, versionCode 11 서명 AAB, 그 후보의 폰 확인이다. 서울·대구·인천·광주·대전·울산 시청 게시판과 R8 재활성화는 출시 후로 둔다.

---

## 1. UI polish

컨셉(`docs/design/CONCEPT.md`)의 4탭(홈·발견·내 기회·더보기), 라운드 카드, 소프트 블루+카테고리 색은 `AppTheme`과 `MainShell`에 반영돼 있다. 히어로는 수원만 `hero_suwon.png`이고 나머지 33도시는 `hero_default.png` 하나다. 시군별 아트는 컨셉에도 “추후”로 남아 있어 출시 차단 항목이 아니다.

### 1-1. 고쳐 둘 화면 (출시 전 후보)

| 화면 | 코드에서 본 문제 | 공수 |
|------|------------------|------|
| 더보기 `MoreTab`, 설정 `SettingsScreen` | 앱 정보가 **`로온드 0.1.7`** 로 하드코딩. pubspec는 0.1.9+10. | S |
| 설정 | 개인정보 부제 **「탭하여 보기 · 배포 시 URL 교체 가능」** 이 사용자에게 보인다. URL은 GitHub blob (`kPrivacyPolicyUrl`). | S |
| 홈 `_HeroBand` | 높이 **78** 고정. 헤드라인 `「{도시}, 지금 뭐가 있지?」` / 여행 모드의 더 긴 문장에 `maxLines`가 없다. 「서귀포시, 여행·체류 중 뭐가 있지?」는 좁은 폭에서 잘릴 수 있다. 실기기 재현은 안 함. | S |
| 홈 퀵 카테고리 4열 | `Expanded` 4개, 라벨 두 줄, `maxLines` 없음. 글자 크기 키우면 잘릴 여지. 기본 글자 크기에서의 잘림은 미확인. | S |
| 메인 셸 오류 | 최초 로드 실패 시 `데이터를 불러오지 못했어요.\n$_error` 로 **예외 문자열**을 그대로 보여 준다. | S |
| 지역 피커 안내 | 「일부 관광 도시는 신청 공고를 아직 모으지 않아요」. 레지스트리 34곳 중 `not_provided` / `preparing` 은 **0곳**. 대부분은 `national`(관광 체험). 부천만 APPLY 0건인데 상태도 `national`이라, 홈은 「지금 신청 가능한 공고가 없어요」를 쓴다. | S |
| 홈·발견·내 기회 로딩/빈 상태 | 최초 로딩은 스피너만. 지역 전환은 반투명 오버레이(`_switching`). 빈 APPLY/ENJOY/발견 문구는 있다. 서울 JSON은 약 767KB라 첫 전환이 느릴 수 있다. 디스크 캐시 상한 8지역(`FeedRemoteConfig.maxCachedRegions`). | 관찰 S, 개선은 M |
| 하단 광고 | `NavigationBar` **아래**에 「광고」+ 320×50 배너. 배너만 `SafeArea`. 제스처 내비·큰 글자에서 하단이 길다. 컨셉 목업에는 광고 자리가 없다. | S(여백) / M(적응형 배너) |
| 발견 그리드 | `crossAxisCount: 2` 고정, `childAspectRatio: 0.72`. 넓은 화면에서 카드가 가로로 늘어난다. `LayoutBuilder` 없음. | M |
| 내 기회 혜택 | BENEFIT는 수원 6건뿐(manifest). 다른 지역은 「복지 혜택 데이터 준비 중」+ 복지로·보조금24. 빈 상태는 정직하다. 데이터 확장은 출시 범위 밖(계획서 S11). | 출시 후 |
| 상세 | 「공식 원문 보기」, 비정부 한 줄, 출처 `sourceName` 있음. HWP 안내는 키워드 포함 시. 원문 URL이 길면 줄바꿈만 하고 말줄임은 없다(기능상 문제는 작음). | 유지 |

사용자에게 보이는 테스트 문자열: 위 0.1.7·「배포 시 URL 교체」. `debugShowCheckedModeBanner`는 꺼져 있다. `print` 로그(`[ads]`, `[analytics]`)는 로그캣용이고 화면 문구는 아니다. 광고 슬롯의 「광고」 라벨은 고지용으로 유지하는 편이 맞다.

### 1-2. Play 사전 출시에서 언급된 경고 (코드 대조)

콘솔 문장은 이 환경에서 다시 열지 않았다. 아래는 그 경고가 나올 만한 코드다.

**엣지 투 엣지 / 풀스크린**

- `MainActivity`는 `FlutterActivity()` 한 줄. `SystemChrome`, `WindowCompat`, `enableEdgeToEdge` 호출 없음.
- `styles.xml`의 `LaunchTheme` / `NormalTheme` 부모는 `@android:style/Theme.Light.NoTitleBar`. Android 15 엣지 투 엣지 opt-out 항목 없음.
- 홈·발견·내 기회·더보기는 제목에 `SafeArea(bottom: false)`. 상세·지역 피커는 `AppBar`.
- 하단은 내비게이션 바 + 배너 구조(위 표). targetSdk 35 이상이면 시스템 바 뒤로 콘텐츠가 그려지고, 콘솔이 inset 미처리로 경고할 수 있다. **실제 targetSdk 숫자는 미확인.**

**큰 화면**

- 매니페스트에 `screenOrientation` 잠금 없음. `resizeableActivity`도 명시 없음(API 24+ 기본값은 크기 조절 허용).
- 레이아웃은 폰 기준 단일 열·발견 2열. 태블릿용 `NavigationRail`·최대 폭 없음.
- 스토어 스크린샷 체크리스트(`listing-ko.md`)의 가로·해상도 항목은 아직 `[ ]`.

**Android 15 deprecated API**

- 앱 Kotlin/Java가 `Window.setStatusBarColor`, `setNavigationBarColor`, `setDecorFitsSystemWindows`를 호출하지는 않는다.
- 이 경고는 보통 Flutter 엔진과 `google_mobile_ads`가 낸다. 앱 로직 수정만으로는 안 사라지고, **어떤 Flutter로 0.1.9를 빌드했는지가 먼저**다. 저장소에 Flutter 버전 핀이 없다. AGP는 `app/android/settings.gradle.kts`에서 **9.1.0**, Kotlin **2.4.0**.

**R8 축소·난독화**

`app/android/app/build.gradle.kts` release:

- `isMinifyEnabled = false`
- `isShrinkResources = false`
- 주석: AdMob이 끌어오는 WorkManager를 R8이 `WorkDatabase_Impl`까지 지워 기동 크래시가 났음.
- `proguard-rules.pro`에는 그 클래스 keep이 **이미** 있다. minify가 꺼져 있어 규칙은 적용되지 않는다.
- 콘솔의 “R8 미사용” 경고와 일치한다. 같은 주에 minify를 켜면 과거 크래시가 재현될 수 있다. **출시 차단으로 보지 않고, 출시 후 실기기에서 keep 규칙을 검증한 뒤에만** 켠다. 공수 M.

---

## 2. 실제 광고 (R18)

### 2-1. 현재 상태

운영 앱 ID·광고 단위 ID는 **없다**. 들어 있는 값은 Google이 공개한 **샘플/테스트** ID다 (`app/lib/ads/ad_config.dart` 주석과 동일).

| 용도 | 위치 | 지금 값의 성격 |
|------|------|----------------|
| Android 앱 ID | `ad_config.dart` `androidAppId`, `AndroidManifest.xml` `com.google.android.gms.ads.APPLICATION_ID` | 샘플 (`~3347511713`) |
| iOS 앱 ID | `ad_config.dart`, `app/ios/Runner/Info.plist` `GADApplicationIdentifier` | 샘플 (`~1458002511`). 이번 출시는 Play Android |
| 배너 | `bannerAdUnitId` | 샘플 |
| 전면 | `interstitialAdUnitId` | 샘플. 상세를 닫은 뒤 세션당 1회 |
| 네이티브 | `nativeAdUnitId` | 샘플. 발견 그리드, 카드 인덱스 2 다음부터 4장마다 |

초기화는 `MobileAds.instance.initialize()` 뿐이다 (`ads_init_mobile.dart`). **UMP(`ConsentInformation` / `ConsentForm`) 호출 없음.** `user_messaging_platform` 패키지도 없다. `google_mobile_ads`는 **^9.0.0**.

분석은 `AnalyticsStub`의 `print`만이다. Firebase·서버 전송 없음.

앱 매니페스트에 `com.google.android.gms.permission.AD_ID`를 직접 선언하지 않았다. GMA SDK가 병합할 가능성은 있으나 **release 매니페스트로 확인하지 않음.** iOS `Info.plist`에 `NSUserTrackingUsageDescription`(ATT) **없음.** ATT는 iOS용이라 Play 바이너리의 출시 조건은 아니다. R18 문구의 ATT는 iOS를 나중에 낼 때 해당한다.

개인정보 방침 §2는 AdMob·테스트 ID·운영 ID를 문서에 적지 않는다는 점까지는 맞다. 본문 첫머리의 「수원 지역」「로컬 JSON」은 지금 앱(34지역, `https://darren83kim.github.io/loond/` 원격 피드)과 어긋난다.

### 2-2. 운영 ID를 넣는 자리 (값은 소유자가 채운다)

이 문서와 저장소 문서에 **운영 ID를 적지 않는다.** 소유자가 AdMob에서 만들어야 하는 것:

1. Android 앱 ID 1개 (`ca-app-pub-…~…`) — 패키지 `com.loond.loond`
2. 광고 단위 3개: 배너, 전면, 네이티브 (`ca-app-pub-…/…`)
3. iOS 앱 ID는 App Store 빌드를 낼 때만

코드에 넣을 곳:

- `app/lib/ads/ad_config.dart` 다섯 상수 중 Android 앱 ID와 단위 3개
- `app/android/app/src/main/AndroidManifest.xml`의 `APPLICATION_ID` (앱 ID와 단위 ID는 다른 값이다. 여기에는 **앱 ID**만)
- iOS plist는 Play 출시물과 무관. 샘플 ID를 둔 채로 두어도 Android AAB에는 안 들어간다. 혼선을 피하려면 같은 변경에서 손대도 된다.

ID를 이번 주에 못 받으면 **샘플 ID로 프로덕션을 열지 않는다.** AdMob 정책상 테스트 광고를 배포 앱에 쓰면 안 된다. 대기는 `AdConfig.adsEnabled`를 릴리스에서 끄거나, 배너·네이티브·전면 로드를 릴리스에서 건너뛰는 쪽이다. 끄면 데이터 보안의 광고 답도 그 빌드와 같아야 한다.

### 2-3. 동의(UMP)와 데이터 보안

- 앱이 **EEA·영국 사용자에게 배포되면** Google 광고는 인증 CMP(AdMob UMP)가 필요하다. `ads_init_mobile.dart`에서 `MobileAds.instance.initialize()` **앞**에 동의 정보 갱신·필요 시 폼을 띄운다.
- **한국만** 배포하는지는 콘솔 국가 설정이라 **미확인**. 한국만이면 UMP를 이번 주 필수로 단정하지 않는다. 국가를 넓히기 전에 UMP를 넣으면 된다.
- 데이터 보안(소유자가 콘솔에서 맞출 항목, 코드 기준):
  - 광고 있음(실 ID를 넣는 빌드). 광고 ID·기기 식별자는 **Google(AdMob)이 광고 목적으로 처리**. 앱이 직접 수집해 자사 서버로 보내지 않음.
  - 계정·이름·이메일 수집 없음. 문의 메일은 화면에만 있다.
  - 북마크, 선택 지역, 거주/여행 모드, 혜택 프로필(나이·동네·아이 등)은 `SharedPreferences` **기기 안** (`BenefitProfileStore` 주석: 서버 동기화 없음). 전송하지 않으면 “수집”으로 선언하지 않는 편이 맞다. 방침에는 이 로컬 프로필을 한 줄 보강하는 것이 좋다. 지금은 「설정·캐시」로만 뭉뚱그려져 있다.
  - 피드는 `FeedRemoteConfig`의 GitHub Pages HTTPS. 사용자 식별자를 쿼리에 붙이지 않는다. Pages 접속 로그를 개발자가 쓰는지 **미확인**.
  - 크래시 SDK 없음. Play Vitals는 콘솔 쪽이다.
- 테스트 광고 SDK가 이미 클로즈드 빌드에 있으므로, 설문에 광고를 “없음”으로 둔 상태라면 그 답부터 고친다. **현재 설문 저장값은 미확인.**
- 개인정보 URL: 앱 설정 링크와 콘솔 URL을 같게. GitHub blob은 임시로 문서에 적혀 있고, 프로덕션 전에는 고정 HTTPS 페이지가 낫다. 호스팅 위치는 소유자 결정(데이터용 Pages `darren83kim.github.io/loond/` 를 쓸지는 **미정**).

---

## 3. 남은 도시

34지역 레지스트리·원격 JSON은 있다. “APPLY 게시판이 없다”는 **시청·시 공식 모집 게시판 수집기** 기준이다. TourAPI 체험(`sourceName=한국관광공사 TourAPI (체험·관광)`, 요약에 시·군청 공고가 아님)은 시청 게시판으로 세지 않는다.

2026-10-15 피드에서 시청·재단·통합예약 APPLY가 있는 곳은 세 곳뿐이다.

| 지역 | 시청·기관 APPLY | 비고 |
|------|-----------------|------|
| 수원 | 12 (수원특례시 7, 수원문화재단 3, 수원시 통합예약 2) | `applyStatus=provided`. `collect.py` 새올. **daily에는 없음** (R27) |
| 성남 | 10 (성남시) | `provided`. `notice_sources.py` eminwon, `verified_list` 아님, `_REGST`. daily 없음 |
| 고양 | 1 (고양특례시) + TourAPI 3 | `provided`. eminwon 설정은 `verified=True`. daily 없음 |

부산은 아래 3-1. 그 외 APPLY는 TourAPI 체험이다. manifest 합계와 지역 파일 건수는 같다.

### 3-1. 광역·대도시 시청 APPLY

| 지역 | 앱 상태 | 2026-10-15 APPLY | 수집기 | 계획서(2026-09-29) 난이도 | 이번 주 |
|------|---------|------------------|--------|---------------------------|---------|
| 서울 | `national` | TourAPI 17. ENJOY 193 | **없음**. 계획: 공공서비스예약 OpenAPI, 인증키 필요 | 중 (키는 하). 키 발급은 소유자 | 출시 후 L |
| 부산 | **`provided`** | TourAPI **11. 시청 행 0** | `busan_collect.py` 있음. daily soft-fail 단계 있음 | 중. 2026-09-30에 occation 3건 게시(R33 Done으로 기록) | **표기 정정 S는 출시 전.** 수집 복구는 M, 로그 미확인 |
| 대구 | `national` | TourAPI 8 | **없음**. 계획: `minwon.daegu.go.kr/pssrp/list` | 중. 채용·위원 혼재 | 출시 후 M–L |
| 인천 | `national` | TourAPI 15 | **없음**. 계획: citynet 고시 | 중 | 출시 후 M–L |
| 광주 | `national` | TourAPI 4. ENJOY 40(문화포털 포함) | **없음**. R25 WAF | 상, 보류 후보 | 출시 후. 불가하면 `national` 유지 |
| 대전 | `national` | TourAPI 4 | **없음**. 계획: `MediaList.do?notiType=NOTI_06` | 중 | 출시 후 M |
| 울산 | `national` | TourAPI 7. ENJOY 22 | **없음**. 계획서에서 목록 URL이 재시도 시 500 | 중상 | 출시 후 L |
| 세종 | `national` | TourAPI 2 | **`notice_sources`에 없음**. 계획서는 eminwon 200 | 하(당시). 설정 미추가, 재조사 안 함 | 출시 후 M |
| 창원 | `national` | TourAPI 2 | **`notice_sources`에 없음**. 계획서는 eminwon 하 | 하(당시) | 출시 후 M |
| 용인 | `national` | TourAPI 3 | eminwon 있음, variant **JSP**, verified 아님. 계획서는 action으로 바꿀 것 | 하(설정 수정) | 출시 후 S–M. daily 아님 |
| 화성 | `national` | TourAPI 7 | eminwon `hscity` **verified=True**. 게시물에 시청 행 없음 | 하 | 출시 후 S–M |

부산 상세: `8aa18c9`의 `busan.json`에는 `busan-occation-` 3건이 있었다. `39b2126`(2026-10-02 daily)에서 빠졌고 HEAD에도 없다. `busan_collect.merge_publish`는 매 성공 시 기존 `busan-occation-*`를 지운 뒤 이번 수집의 게시 행만 넣는다. 0건 게시로 끝나면 이전 3건이 사라진다. `run_tour_daily.merge_and_publish`는 기존 APPLY를 유지하므로, 관광 수집만으로 시청 행이 지워지지는 않는다. **그 런이 빈 성공이었는지는 Actions 로그가 없어 미확인.** 카탈로그 `apply_status`는 행 유무와 따로 `provided`로 고정돼 있다(`region_codes.py`). 피커는 부산에 「신청·행사·발견」을 보여 준다. 이전 Misleading Claims 반려 이력을 보면, 시청 공고가 없는데 제공으로 보이는 상태가 출시 전에 더 위험하다.

정직한 선택(구현은 이 PR에 없음):

- 시청 행이 다시 게시되기 전에는 `applyStatus`를 `national`로 맞춘다. 공수 S.
- 국내망에서 `busan_collect`를 다시 돌려 행이 살아 있고 검수를 통과하면 `provided`를 유지한다. 공수 M. 해외 Actions IP 차단 여부는 미확인(워크플로가 soft-fail인 이유).

### 3-2. 얇은 ENJOY (R31)

기준 스냅샷 2026-10-15. R31이 예로 든 성남·부천은 그때(2026-09-29)보다 늘었다. 충주·단양은 그대로 얇다.

| 지역 | ENJOY | 출처 | 판정 |
|------|------:|------|------|
| 충주 | 1 | TourAPI만 (`우륵문화제`) | 여전히 얇음. eminwon 설정은 verified이나 **APPLY 파이프에 미연결**. ENJOY 보강 수집기는 없음 |
| 단양 | 2 | TourAPI만 (겨울놀이·철쭉제) | 여전히 얇음. eminwon 메모: HTTPS/TLS 불안정. 재조사 안 함 |
| 가평 | 4 | (건수만) | 얇음. eminwon verified, 시청 APPLY는 미연결 |
| 군산 | 4 | | 얇음. eminwon verified, 미연결 |
| 공주 | 5 | | 얇음. eminwon 설정 없음(계획서: 미조사) |
| 순천 | 5 | | 얇음. 계획서: 미조사 |
| 통영 | 5 | | 얇음. eminwon verified, 미연결 |
| 부여 | 6 | | 경계. eminwon 미조사 |
| 속초 | 6 | | 경계. 계획서: 목록 빈 셸, unknown |
| 성남 | 9 | TourAPI 1 + 문화포털 8 | R31의 「1건대」 설명은 **이 스냅샷과 불일치**. 레지스터 문구 갱신 대상 |
| 부천 | 11 | TourAPI 1 + 문화포털 10 | 동일. APPLY는 0 |

문화포털이 충주·단양 ENJOY를 채우지 못했다. 키워드를 더 돌리기 전에, 문화포털 시도·시군 코드가 비어 온 것인지 확인이 필요하다. 이번 감사는 API를 다시 치지 않았다. 출시 차단은 아니다. 홈은 「지금 즐길 수 있는 행사가 없어요」로 0건을 처리하고, 1–2건은 그 카드만 보여 준다.

### 3-3. §11 잔여 (R18, R20, R25–R32)

새 ID는 만들지 않는다. R33–R35는 이미 레지스터에 있어 도시 판단에 필요해 한 줄만 적는다.

| ID | 레지스터 판정 | 2026-10-16 코드·데이터 | 다음 |
|----|---------------|------------------------|------|
| R18 | Deferred | 샘플 광고 ID. UMP 없음. ATT 문구 없음(iOS). Android AD_ID는 병합 매니페스트 미확인 | 출시 빌드 전 실 ID 또는 광고 끄기. 방침·데이터 보안 동기화 |
| R20 | Open | §11에 폰 도그푸딩 결과가 아직 없다. 클로즈드 0.1.9가 그 기록을 대신하는지는 **미확인** | 출시 후보를 폰에서 보고 §11에 결과만 남긴다(별도 작업) |
| R25 | Open | 광주 수집기 없음. 피드는 `national` + TourAPI 4 | 시청 게시판은 출시 후. 정직 표기는 이미 national |
| R26 | Partial | `run_tour_daily`에 타임아웃 재시도·`API_BUDGET`(주석 900대)·workflow `timeout-minutes: 30` 있음. resultCode 22일 때 이전 피드 유지+이슈는 **코드에서 못 찾음**. 운영계정 신청 여부는 소유자 계정, **미확인** | 출시 후. 한도 소진 시 피드가 비는지 런북만 출시 전에 한 번 읽기 |
| R27 | Partial | daily: TourAPI, 문화포털, `tour_apply_collect`, `busan_collect`(soft). 수원 `collect.py`·eminwon **스텝 없음** | 출시 후. 수원 12건은 수동 반영분에 의존 |
| R28 | Deferred | 문구는 Phase 2를 `not_provided`로 두라고 함. 구현은 Phase 2가 **`national`**. `not_provided` 분기는 UI에만 있고 레지스트리 사용처 없음 | 레지스터 문구를 구현에 맞게 고치는 것은 문서 정리(S). 제품 동작 변경은 출시 후 |
| R29 | Done | 서울·광역시 단일 지역 + `districts` 칩. 구청 APPLY 미조사 유지 | 유지 |
| R30 | Done | 성남·부천 유지. 가평군·부여군·단양군 `displayName` | 유지 |
| R31 | Open | 충주 1·단양 2는 여전. 성남 9·부천 11은 문화포털로 늘음 | 출시 후 모니터링. 문구 갱신 |
| R32 | Done | 미니맵 위젯·고아 테스트 제거된 상태(레지스터). 이번 감사에서 맵 위젯 파일은 검색되지 않음 | 유지 |
| R33 | Done으로 적힘 | 수집 코드는 있음. **게시 행은 2026-10-02 이후 0** | 판정을 Partial로 되돌리는 것을 권함(구현계획서 수정은 이 계획의 후속) |
| R34 | Done | TourAPI 체험 APPLY가 대부분 지역의 신청 목록 | 유지. 카드만 보면 시청 공고와 구분이 약하고, 구분은 요약·`sourceName`·피커 `national` 문구에 있음 |
| R35 | Open | 서울·대구·인천·대전·울산·광주 시 보드 없음 | 출시 후. 순서 후보는 계획서 그대로 대구 pssrp·서울 예약 API. 둘 다 **키·재검증 미완** |

---

## 4. 릴리스 절차

### 4-1. 버전

- 지금: versionName **0.1.9**, versionCode **10**.
- 다음 업로드: versionCode **11** 이상. Play는 같은 트랙·다른 트랙 모두 더 큰 versionCode만 받는다.
- versionName 후보는 **0.1.10** (`0.1.10+11`). 이름은 소유자 선택. 이 계획 커밋은 pubspec를 바꾸지 않는다.
- 더보기·설정의 `0.1.7` 문자열은 하드코딩이라 pubspec만 올려도 화면은 안 바뀐다. 같은 변경에서 `package_info`로 읽거나 문자열을 같이 고친다.

### 4-2. 서명 (키스토어·비밀은 건드리지 않음)

`app/android/app/build.gradle.kts`:

- `key.properties`가 있으면 release 서명.
- **없으면 release가 debug 서명으로 떨어진다.** Play 업로드는 거절된다.
- `key.properties`, `*.jks`, `*.keystore`는 `app/android/.gitignore`에 있다. 이 워크스페이스에는 파일이 없다.
- 0.1.9가 클로즈드에 올라갔다면 업로드 키는 **이미 Play에 등록된 그 키**다. 새 키스토어를 만들면 서명이 달라 업로드가 거절되거나 앱 서명 재설정 절차로 간다. 재설정 절차의 현재 콘솔 상태는 **미확인**.
- 빌드는 **그 키가 있는 기기**에서. 키를 git, 이슈, 채팅에 넣지 않는다. GitHub Actions 릴리스 워크플로는 없다(`daily_worker.yml`, `pages.yml`만).

로컬 절차(비밀 값 없음):

```bash
cd app
flutter pub get
flutter build appbundle
```

산출: `app/build/app/outputs/bundle/release/app-release.aab`.

올린 뒤 Play가 서명을 받아들이는 것으로 debug 폴백이 아님을 확인한다. 키 별칭·비밀번호·스토어 경로는 `key.properties`에만 둔다.

### 4-3. 프로덕션 롤아웃

1. 액세스 신청(2026-10-16) 결과를 기다린다. 승인 전에 프로덕션 트랙은 열리지 않는다. **승인됐다고 가정하지 않는다.**
2. 승인돼도 **0.1.9(테스트 광고 ID, 부산 provided)를 프로덕션으로 승격하지 않는다.**
3. §5 필수 항목이 들어간 versionCode 11 AAB를, 기존 업로드 키로 만든다.
4. 먼저 클로즈드(또는 내부) 트랙에 올려 폰으로 §5의 확인 목록을 돈다.
5. 프로덕션 릴리스를 만들고 단계적 출시를 쓴다. 시작 비율은 콘솔에서 소유자가 정한다(이 문서에 비율을 고정하지 않음). 크래시·ANR을 본 뒤 비율을 올린다. Vitals 현재 숫자는 **미확인**.
6. 출시 노트는 한국어로, 면책(비정부·비제휴, 신청 대행 아님)과 맞는 문장만.
7. 스토어 등록정보·개인정보 URL·데이터 보안·광고 선언·콘텐츠 등급이 **그 AAB**와 같은지 콘솔에서 본다. `listing-ko.md`의 긴 설명은 수원·VisitKorea·data.go.kr URL 위주라 34지역 앱과 완전히 같지는 않다. 도시명을 URL 없이 늘어놓는 수정은 이전 반려(Misleading Claims)를 다시 부를 수 있어, 목록 문구 변경은 인앱 출처와 짝을 맞춘 뒤 한다.
8. 스크린샷에 테스트 광고 문구가 보이면 교체한다. `docs/store/screenshots/`는 과거 빌드 기준일 수 있다. 0.1.9와 픽셀이 같은지는 **대조하지 않음**.

---

## 5. 순서 (심사 대기 약 1주)

### 출시 전에 할 것

| 순서 | 항목 | 공수 | 막히는 조건 |
|------|------|------|-------------|
| 1 | 운영 광고 ID 3개+Android 앱 ID를 §2-2 자리에 넣거나, 릴리스에서 광고를 끈다. 데이터 보안·방침을 그 선택과 맞춘다. EEA 배포면 UMP까지. | M | 소유자의 AdMob ID, 콘솔 국가·설문 |
| 2 | 부산: 시청 행이 없으면 `applyStatus=national`. 행을 살릴 수 있으면 그때만 `provided`. | S 또는 M | 국내망에서 occation이 다시 열리는지 미확인 |
| 3 | 화면의 `0.1.7`, 「배포 시 URL 교체 가능」 제거. 방침의 수원 한정·로컬 JSON 전용 문장을 34지역·원격 피드·기기 내 혜택 프로필에 맞게. 개인정보 URL을 콘솔과 동일 HTTPS로. | S | 호스팅 URL은 소유자 |
| 4 | pubspec **0.1.10+11**(이름은 가변). 기존 업로드 키로 AAB. debug 서명 폴백 금지. | S | 키스토어가 있는 기기 |
| 5 | 그 AAB로 R20: 지역 전환(수원·서울·부산·충주), APPLY가 관광 체험인지 시청 공고인지, 원문 CTA, 하단 배너와 시스템 바, 빈 목록. 결과를 §11에 적는다. 겹침이 보이면 히어로 `maxLines`·하단 inset만 고친다. | S, 겹침 수정은 S–M | 실기기 |

### 같은 주에 시간이 남을 때만

- 오류 화면의 예외 문자열 숨김 (S).
- 피커 안내 문구를 `national` / 부천 0건에 맞게 (S).
- 문구가 바뀌면 Play 스크린샷 재촬영 (S).
- 히어로 78px가 폰에서 실제로 잘리면 높이·줄 수 (S).

### 출시 후

- R8 minify. keep 규칙이 있어도 과거 크래시가 있어, 프로덕션 첫 바이너리와 묶지 않는다 (M).
- 큰 화면: 발견 열 수·본문 최대 폭 (M). 콘솔 경고는 거절 사유로 확인된 바 없음.
- Flutter 업그레이드로 deprecated Window API 감소 (M). 현재 엔진 버전 미확인.
- 시청 APPLY: 대구 pssrp, 서울 예약 API(키), 인천 citynet, 대전, 용인·화성·창원·세종 eminwon, 부산 occation 복구. 광주(R25)·울산은 그 다음. 각각 M–L.
- 수원·eminwon daily 편입 (R27, M).
- 충주·단양 ENJOY가 문화포털에서 비는 이유 (R31, M). 1–2건이어도 출시 자체는 가능.
- R26 운영계정·resultCode 22 시 이전 피드 유지.
- 수원 외 BENEFIT, 도시별 히어로 아트.

한 주 안에 광역시 게시판을 새로 만드는 계획은 넣지 않는다. 키·WAF·해외 IP·검수(채용·입찰 제외)가 도시마다 따로다.

---

## 6. 권장 5개

1. **테스트 광고 ID를 프로덕션에 넣지 않기.** 운영 ID(소유자 발급, 이 문서에 값 없음) 또는 릴리스에서 광고 끄기. 데이터 보안과 방침을 그 빌드와 맞춘다.
2. **부산 `provided`와 시청 공고 0건을 맞추기.** 2026-10-02 daily 이후 `busan-occation-*`가 없다. 표기를 `national`로 내리거나, 행이 다시 게시된 뒤에만 제공으로 둔다.
3. **사용자에게 보이는 내부 문구.** `0.1.7`, 「배포 시 URL 교체 가능」, 방침의 「수원」「로컬 JSON만」.
4. **versionCode 11 AAB는 0.1.9에 쓴 업로드 키로.** 키스토어는 저장소에 없고, 없어 보이면 debug 서명이 된다.
5. **그 후보로 폰 확인(R20).** 지역 전환, 원문, 하단 배너·시스템 바. 새 도시 스크래퍼와 R8은 출시 뒤에 둔다.
