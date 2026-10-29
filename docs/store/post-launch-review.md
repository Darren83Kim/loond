# 출시 후 리뷰 — 0.1.10(11) 프로덕션 제출 이후

> 0.1.12+13 내용과 실기기 확인 항목은 아래 **§3**이다. §1–§2는 0.1.10 제출 직후(2026-10-18) 기록이다.

> 작성 2026-10-18 (KST). 근거: `docs/store/production-launch-checklist.md`, `docs/구현계획서.md` §11, `app/android/app/build.gradle.kts`, `app/android/app/proguard-rules.pro`, `app/lib/ads/*`, `app/ios/Runner/Info.plist`.
> 참고: 요청에 있던 `docs/store/production-launch-plan.md`는 저장소에 없다. 체크리스트를 기준으로 삼았다.

## 1. 출시 직후 해야 할 일 (우선순위 순)

1. **심사 결과 확인과 거부 대응 준비.** 거부되면 `docs/store/play-reject-misleading-claims-fix.md`의 방식대로 대응한다. 승인되면 국가(한국)와 전체 출시 상태를 확인한다. 체크리스트 §1의 「12명·14일」 항목도 콘솔 기록으로 닫는다.
2. **비정상 종료·ANR 모니터링 (Play Console → Android vitals).** 앱에 Crashlytics 같은 크래시 SDK가 없다(`app/pubspec.yaml`에 firebase 없음). 그래서 vitals가 유일한 관측 수단이다. 출시 후 72시간은 매일 본다. 특히 시작 직후 크래시를 본다. 예전 R8 빌드에서 `WorkDatabase_Impl`가 제거돼 시작 시 크래시가 났다(`build.gradle.kts` 주석). UMP→`canRequestAds`→SDK 초기화 경로의 ANR도 본다(`app/lib/ads/ads_consent_mobile.dart`). 지금은 minify가 꺼져 있어 스택이 읽힌다. 매핑 경고는 당장 무시해도 된다.
3. **AdMob 앱을 Play 스토어 등록정보에 연결.** 공개된 뒤 AdMob → 앱 설정 → 「앱 스토어 추가」에서 `com.loond.loond`를 연결한다. 연결 전 unlisted 상태에서는 광고 게재가 제한될 수 있다. 연결 뒤 app-ads.txt 크롤 상태를 확인한다. 기대하는 줄은 `google.com, pub-8022343674155817, DIRECT, f08c47fec0942fa0`(체크리스트 §3)이다. Play 등록정보의 개발자 웹사이트가 `darren83kim.github.io`(루트)인지도 다시 확인한다.
4. **광고 실게재·정책 확인.** 실기기에서 배너, 전면(세션당 1회·상세를 닫은 뒤, `interstitial_ad_manager_mobile.dart`), 네이티브가 나오는지 본다. 개인정보 옵션 타일(`app/lib/ui/widgets/privacy_options_tile.dart`)도 확인한다. AdMob 정책 센터 위반 알림과 노출·fill rate를 확인한다. 체크리스트 §3의 R18 항목(AD_ID 고지 실기기 확인)을 닫는다.
5. **데이터 보안·광고 선언이 빌드와 맞는지 확인.** 콘솔의 「앱 콘텐츠」에서 광고 ID·앱 활동·진단 공유를 확인한다(체크리스트 §3 「데이터 보안」, §5). 개인정보처리방침 URL(`docs/legal/privacy-policy.md`)도 확인한다.
6. **리뷰·평점 응답.** 처음 2주는 리뷰에 24–48시간 안에 답한다. 자주 나올 만한 질문은 세 가지다. ① 「우리 시 신청 정보가 없다」: 부산 등은 national(관광 체험) 표시이고 시 게시판은 순차 적용 중이라고 답한다(§11 R28/R35). ② 「광고가 많다」: 전면 광고는 세션당 1회라고 답한다. ③ 데이터가 얇은 도시(충주·단양 등, R31). 템플릿 문구를 미리 만들어 둔다.
7. **데이터 파이프라인 감시.** 일일 Actions(`.github/workflows/daily_worker.yml`)는 실패하면 이슈를 연다(R16). 공개 사용자가 Pages 피드를 바로 쓰므로 실패 이슈를 당일 처리한다. TourAPI 한도(R26 Partial)도 확인한다. 2026-10-29 이후: resultCode 22·수집 실패·호출 예산 중단이면 워커가 이전 published 피드를 유지하고, 작업은 실패해서 이슈가 열린다. 운영계정 신청은 여전히 사용자 작업이다.
8. **R20 폰 도그푸딩(여러 날).** 공개 빌드를 실제 휴대폰에서 3일 이상 쓴다. 도시 전환, APPLY/ENJOY/DISCOVER, 원문 CTA, 광고 빈도를 보고 결과를 §11에 기록한다(체크리스트 §2, §6).
9. **Windows PC의 미커밋 변경 정리.** `minSdk = 21` → `flutter.minSdkVersion`은 **0.1.12**에서 반영했다(§3). 0.1.11 당시 main은 `minSdk = 21`이었고, 실제 APK minSdk 24는 플러그인 병합 결과였다.

## 2. 첫 업데이트(0.1.11) 후보

| # | 후보 | 왜 | 노력 | 위험 |
|---|------|----|------|------|
| A | **minSdk 정리 + 빌드 위생** | main(21)과 실제 APK(24)가 다르고 PC에 미커밋 변경이 있다. 기기 지원 범위가 바뀌는지 명확히 해야 한다 | S | 낮음. 단, 24 미만으로 바뀌는지 병합 결과를 확인해야 한다 |
| B | **R8 재활성화 + 매핑 업로드** | Play 경고를 해소하고 APK 크기를 줄인다. 이미 `proguard-rules.pro`에 WorkManager/Room/GMA keep 규칙이 있다 | M | **높음.** 과거 시작 시 크래시 전례가 있다. 내부 트랙에서 cold start와 광고 3종을 검증한 뒤에만 낸다 |
| C | **대도시 시 게시판 APPLY 1–2곳** (R35: 대구 pssrp·서울 예약 API 우선) | 「신청 정보 없음」 불만을 줄이는 핵심 가치다. 앱 변경 없이 워커·피드만으로 배포할 수 있다 | M–L | 중간. 가짜 마감 금지 규칙(`docs/ops/apply-review-rules.md`)과 검수 부담이 있다. 광주(R25)는 WAF 때문에 제외한다 |
| D | **피드 실패 시 이전 데이터 유지·한도 처리** (R26 잔여) | 공개 사용자에게 빈 화면이 나오는 것을 막는다 | S–M | 낮음 (워커 쪽) |
| E | **약한 ENJOY 도시 보강** (R31) | 충주·단양 등 1–2건 도시의 첫인상을 개선한다 | S–M | 낮음 |

iOS 운영 광고 ID(`app/lib/ads/ad_config.dart`, `Info.plist`의 샘플 ID)는 iOS를 출시할 때 처리한다. 0.1.11 범위가 아니다.

**권장 범위 (당시):** 0.1.11 앱 빌드는 **A + B**만 한다. B는 내부/클로즈드 트랙에서 1–2일 vitals를 확인한 뒤 프로덕션에 올린다. 문제가 생기면 B를 빼고 A만 출시한다. **C·D·E는 앱 업데이트 없이 워커·Pages 피드로 병행**한다. 0.1.10 vitals와 리뷰가 안정된 뒤(출시 후 약 1주) 착수한다.

0.1.11은 출처 URL 수정(Misleading Claims)만 나갔다. **A(minSdk)와 B(R8)는 0.1.12로 넘어갔다.** §3을 본다.

## 따로 판단할 항목 (출시 후)

1. **0.1.12 전후에, 내 기회 빈 상태의 복지로·보조금24 버튼을 되돌릴지 결정한다.** 버튼은 0.1.11에서 뺐다. 해외 Play 리뷰어가 `.go.kr`을 열지 못했고, 그 때문에 2026-10-21 Misleading Claims 거절이 났다. 대상은 복지로(`bokjiro.go.kr`)와 보조금24(`gov.kr`)다. **0.1.12에서는 되돌리지 않았다.** 선택지는 그대로다.
   - 업데이트마다 다시 심사받는다.
   - 스토어 설명에 적는 출처는 해외에서 열리는 주소만 쓴다.
   - 선택지: (a) 버튼을 다시 넣는다. (b) 각 항목의 「공식 원문 보기」로만 연결한다.

## 3. 0.1.12+13 (versionCode 13)

앱 버전 `0.1.12+13` (`app/pubspec.yaml`). 머지하지 않고 리뷰 대기. 서명·keystore·`key.properties`는 바꾸지 않았다.

### 포함

1. **광고 위치**
   - 메인 셸 하단 배너를 제거했다. 그 배너는 홈 탭만이 아니라 하단 내비게이션 아래(홈·발견·내 기회·더보기)에 붙어 자리를 많이 차지했다. 셸에서 통째로 뺐다.
   - 목록 중간 네이티브는 그대로다. 신청할 수 있는 기회·곧 열리는 행사(`OpportunityTab` / `buildFeedWithAds`)와 발견 그리드(`DiscoverTab`) 모두.
   - 상세에서 목록으로 돌아온 뒤의 전면 광고(세션당 1회, `InterstitialAdManager.maybeShowAfterDetailPop`)는 그대로다.
   - 상세 화면 「공식 원문 보기」 바로 위에 **배너**를 넣었다. 유닛은 기존 배너 `ca-app-pub-8022343674155817/1620279320`이다. 디버그는 구글 샘플 ID(`AdConfig.bannerAdUnitId`). 네이티브 카드는 로드 전에는 높이가 0이라 버튼이 아래로 밀린다. 배너는 동의 후 320×50과 「광고」 라벨을 먼저 잡고, 스크롤 열 안에 있어 버튼을 덮지 않는다. `canRequestAds`가 거짓이면 슬롯 자체가 없다(기존 UMP 경로).
2. **minSdk** = `flutter.minSdkVersion`. Flutter 3.47 기준 값은 **24**다. 하드코드 21을 대체한다. 플러그인 병합으로 실제 APK는 이미 24였으므로, 21로 설치되던 기기가 이번에 빠지지는 않는다.
3. **R8** 릴리스 `isMinifyEnabled` + `isShrinkResources`. 매핑 파일은 `app/build/app/outputs/mapping/release/mapping.txt`다. Play에 이 파일을 올린다. keep 규칙은 `app/android/app/proguard-rules.pro`(WorkManager `WorkDatabase_Impl`, Room, GMA, UMP, Flutter 플러그인). Flutter Gradle 플러그인도 `flutter_proguard_rules.pro`를 릴리스에 붙인다.

### 폰에서 확인할 것

- 릴리스 빌드 콜드 스타트. 예전 R8은 `WorkDatabase_Impl`을 지워 시작 직후 크래시가 났다.
- 홈을 포함한 하단 탭에 배너 자리가 없는지. 목록 네이티브와 상세를 닫은 뒤 전면 광고는 이전과 같은지.
- 상세에서 배너가 버튼 위에 있고 버튼을 가리지 않는지. 디버그 빌드는 테스트 광고, 릴리스·프로파일은 운영 유닛.
- 동의 거부 또는 `canRequestAds == false`이면 상세 배너 없이 버튼만 보이는지.
- 발견 그리드를 스크롤할 때 사진이 이전과 같은 크기로 보이는지. 디코드만 표시 크기로 줄였다.
- Play Console에 `mapping.txt`를 업로드했는지. 내부 트랙 vitals를 본 뒤에 프로덕션으로 올린다.

### 메모리

`RemoteOrPlaceholderImage`의 네트워크 이미지는 표시 크기 × `devicePixelRatio`로 디코드한다. `ResizeImagePolicy.fit`이라 가로세로 비율은 유지되고, 원본보다 크게 키우지는 않는다. 발견 탭은 `shrinkWrap` 그리드 대신 `CustomScrollView` + `SliverGrid.builder`라 화면에 있는 칸만 만든다. 2열, 간격, `childAspectRatio` 0.72, 네이티브 광고 위치(카드 인덱스 2, 6, 10… 뒤)는 이전과 같다. `IndexedStack`이 홈과 발견의 현재 화면은 같이 유지한다.
