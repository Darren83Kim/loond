# Play 정책 재제출 — Misleading Claims (혼동을 야기하는 주장)

## 2026-10-21 거절 — 0.1.10 (versionCode 11) → 0.1.11+12

- 일시: **2026-10-21**
- 거절 빌드: **0.1.10** (versionCode **11**)
- 앱: **로온드** (`com.loond.loond`)
- 정책: Misleading Claims
- 원인: 리뷰어(한국 밖으로 추정)가 스토어·앱에 적은 정부 출처 링크에 접속하지 못함. 해외 네트워크에서 `.go.kr` 사이트가 모두 타임아웃되고, `korean.visitkorea.or.kr`과 `data.go.kr`도 타임아웃. 열린 주소는 `https://english.visitkorea.or.kr`과 `https://api.visitkorea.or.kr`뿐.
- 조치:
  - 인앱 「서비스 안내 / 데이터 출처」(`app/lib/legal/service_disclaimer.dart`)의 나열 URL을 VisitKorea 영문·TourAPI 두 개로 교체
  - `suwon.go.kr`, 수원 복지 딥링크, `korean.visitkorea.or.kr`, `data.go.kr`을 그 화면과 설정 출처 문구에서 제거
  - 지역 고시·공고·복지 항목은 각 상세의 「공식 원문 보기」로 발행 기관 원문 페이지에 연결된다고 한 줄 추가
  - 비제휴·비공식 면책은 그대로 앞에 유지
  - 아래 스토어 긴 설명(ko-KR·en)을 같은 출처로 교체
  - 앱 버전 `0.1.11+12` (`app/pubspec.yaml`)
- 바꾸지 않음: 데이터에서 오는 항목별 원문 링크, 내 기회 빈 상태의 복지로·보조금24 버튼, 서명·R8·minSdk

### 콘솔 붙여넣기 — 짧은 설명 (변경 없음)
```
민간 비제휴 안내 앱입니다. 공개 공고를 모아 「공식 원문 보기」로만 안내합니다.
```

### 콘솔 붙여넣기 — 긴 설명 (ko-KR)
```
【중요 · 면책】로온드는 민간이 만든 비제휴·비공식 안내 앱입니다. 정부·지자체·공공기관을 대표하지 않으며, 제휴·위탁·운영 관계가 없습니다. 공공 프로그램 신청·접수를 이 앱에서 대행하지 않습니다.

로온드는 공개된 고시·공고·행사·복지·관광 정보를 모아 요약만 보여 드립니다. 회원가입 없이 훑어보고, 일정·자격·접수 방법은 각 항목 상세 화면의 「공식 원문 보기」로 이동해 해당 기관의 원문 페이지에서 확인·신청하세요.

■ 데이터 출처 (실제로 사용하는 공식 출처)
• 한국관광공사 VisitKorea (관광·행사 정보): https://english.visitkorea.or.kr
• 한국관광공사 TourAPI (관광 정보 공개 API): https://api.visitkorea.or.kr
• 지역별 고시·공고·복지 항목은 각 상세 화면의 「공식 원문 보기」에 해당 기관(지자체 등)의 원문 페이지 링크가 표시되며, 모든 항목은 그 원문을 따릅니다.

■ 이런 분께 맞춰요
• 신청 마감이 가까운 공고를 빠르게 보고 싶을 때
• 주말에 즐길 행사·관광 정보를 한 목록에서 보고 싶을 때
• 회원가입·점수·복잡한 알림 없이 원문만 확인하고 싶을 때

■ 주요 기능
• NOW: 지금 신청·참여 가능한 기회
• ANYTIME: 언제든 둘러보는 발견 콘텐츠
• 상세에서 일정·요약·출처를 확인한 뒤 「공식 원문 보기」로 해당 기관 원문 페이지로 이동
• 더보기 → 「서비스 안내 / 데이터 출처」에서 면책·출처 확인
• 신청 마감이 지난 공고는 목록에서 제외 (데이터에는 남을 수 있음)

■ 다시 한 번 면책
로온드는 정부·지자체 공식 앱이 아니며 공공기관을 대표하지 않습니다. 정보는 공개 자료를 모아 안내할 뿐이며, 일정·자격·접수 방법·수급 여부·법적 효력은 반드시 각 항목에 연결된 해당 기관의 공식 원문에서 확인·신청하세요.
```

### Console paste — full description (en)
```
[IMPORTANT · DISCLAIMER] Loond is a private, unofficial information app. It is NOT affiliated with, endorsed by, or operated on behalf of any government, local government, or public institution, and it does not represent them. Loond does not process or submit applications for any public program.

Loond collects publicly available notices, events, welfare and tourism information in Korea and shows short summaries. Browse without signing up, then confirm schedules, eligibility and how to apply on the original institution page via "View official source" on each item's detail screen.

■ Data sources (official sources the app actually uses)
• Korea Tourism Organization – VisitKorea (tourism & events): https://english.visitkorea.or.kr
• Korea Tourism Organization – TourAPI (open tourism data API): https://api.visitkorea.or.kr
• Local notices, announcements and welfare items: each item's detail screen links to the original page of the issuing institution (e.g. the local government), and every item follows that original source.

■ Good for
• Quickly checking notices with approaching deadlines
• Seeing weekend events and tourism info in one list
• Checking the original source without sign-up, points or complex notifications

■ Features
• NOW: opportunities you can apply for or join right now
• ANYTIME: discovery content to browse any time
• Check schedule, summary and source on the detail screen, then open the original institution page via "View official source"
• More → "Service info / Data sources" shows the disclaimer and sources
• Notices past their deadline are hidden from lists (data may remain)

■ Disclaimer (again)
Loond is not an official government or local government app and does not represent any public institution. It only aggregates public information. Always confirm schedules, eligibility, application methods, benefits and legal effect on the official original page linked from each item, and apply there.
```

### 이번 제출 체크리스트
1. [ ] **스토어 등록정보** → 짧은 설명은 유지, 긴 설명은 위 ko-KR(및 en 로케일이 있으면 en) 텍스트로 **교체 후 저장**
2. [ ] versionName **0.1.11** / versionCode **12** AAB를 업로드 (인앱 출처 화면이 바뀌므로 바이너리 필요)
3. [ ] 서명·R8·minSdk는 이 수정에서 건드리지 않음

## 이전 기록 — 2026-09-24 (4차)

- 일시: **2026-09-24 (KST)** — 4차 수정 (이전: 2026-09-22 / Alpha #2)
- 앱: **로온드** (`com.loond.loond`)
- 트랙: 비공개(클로즈드) 테스트 / Alpha
- 아래 긴 설명·URL 표는 **당시 제출본**이다. 2026-10-21 이후 콘솔에는 쓰지 않는다.

## 원인 (이번 리뷰어 지적)
1. ko-KR **긴 설명**에 「성남·고양 등 다른 지역 고시/공고도 각 항목의 공식 원문 URL을 따릅니다.」 — **도시명을 적었으나 해당 공식 URL이 옆에 없음**
2. 앱이 **2개 이상 정보 출처**를 쓰는 것처럼 보이는데, **모든 출처가 명확한 공식·작동 URL로 나열되지 않음**
3. 정부·공공 정보 앱(제휴 여부 무관)은 **공식 출처 URL + 찾기 쉬운 비정부 면책**이 필요

## 조치 요약
| 항목 | 경로 |
|------|------|
| 짧은·긴 설명 (붙여넣기용) | `docs/store/listing-ko.md` |
| 플래그 스샷 교체본 | `docs/store/screenshots/play/APP_SCREENSHOT-860-replacement.png` (= `03-more.png`) |
| 인앱 「서비스 안내 / 데이터 출처」 | `app/lib/ui/service_info_screen.dart`, `more_tab.dart`, `settings_screen.dart` |
| 공유 면책·출처 상수 | `app/lib/legal/service_disclaimer.dart` |
| 앱 버전 | `0.1.7+8` (`app/pubspec.yaml`) |
| 문의 | `mongyang83@gmail.com` (플레이스홀더 제거) |

## 금지·준수 규칙 (다음 제출)
- ❌ 성남·고양·기타 도시명을 **공식 URL 없이** 출처 문단에 적지 않음
- ❌ 정부·지자체 **제휴·공식 앱·대행 신청**처럼 읽히는 표현 금지
- ✅ 면책을 **맨 앞**에 (민간 비제휴 · 대표하지 않음 · 신청은 원문)
- ✅ 실제로 쓰는 출처만, **검증된 공식 URL**과 함께 나열
- ✅ 다중 지역은 「각 항목 상세의 공식 원문 링크」로만 표현

## 당시 콘솔 붙여넣기 — 짧은 설명
```
민간 비제휴 안내 앱입니다. 공개 공고를 모아 「공식 원문 보기」로만 안내합니다.
```

## 당시 콘솔 붙여넣기 — 긴 설명 (폐기 · 2026-10-21에 교체)
```
【중요 · 면책】로온드는 민간이 만든 비제휴·비공식 안내 앱입니다. 정부·지자체·공공기관을 대표하지 않으며, 제휴·위탁·운영 관계가 없습니다. 공공 프로그램 신청·접수를 이 앱에서 대행하지 않습니다.

로온드는 공개된 고시·공고·행사·복지·관광 정보를 모아 요약만 보여 드립니다. 회원가입 없이 훑어보고, 일정·자격·접수 방법은 각 항목의 「공식 원문 보기」로 이동한 해당 기관 원문에서 확인·신청하세요.

■ 데이터 출처 (실제로 사용하는 공식 출처)
• 수원특례시 포털: https://www.suwon.go.kr
• 수원 복지 안내 예시(청년기본소득): https://www.suwon.go.kr/sw-www/deptHome/dep_welfare/welfare14/welfare14-04/welfare14-04-03.jsp
• 한국관광공사 VisitKorea(관광·행사, TourAPI 연계): https://korean.visitkorea.or.kr
• 공공데이터포털(TourAPI 제공): https://www.data.go.kr
• 그 밖의 항목도 각 상세 화면의 「공식 원문 보기」에 표시된 해당 기관 원문 URL을 따릅니다. 원문 링크 없이 지역명만 출처로 적지 않습니다.

■ 이런 분께 맞춰요
• 신청 마감이 가까운 공고를 빠르게 보고 싶을 때
• 주말에 즐길 행사·관광 정보를 한 목록에서 보고 싶을 때
• 회원가입·점수·복잡한 알림 없이 원문만 확인하고 싶을 때

■ 주요 기능
• NOW: 지금 신청·참여 가능한 기회
• ANYTIME: 언제든 둘러보는 발견 콘텐츠
• 상세에서 일정·요약·출처를 확인한 뒤 「공식 원문 보기」로 이동
• 더보기 → 「서비스 안내 / 데이터 출처」에서 면책·출처 URL 확인
• 신청 마감이 지난 공고는 목록에서 제외 (데이터에는 남을 수 있음)

■ 다시 한 번 면책
로온드는 정부·지자체 공식 앱이 아니며 공공기관을 대표하지 않습니다. 정보는 공개 자료를 모아 안내할 뿐이며, 일정·자격·접수 방법·수급 여부·법적 효력은 반드시 해당 .go.kr 등 공식 원문에서 확인·신청하세요.

■ 기타
• 광고(AdMob)가 표시될 수 있습니다.
• 개인정보처리방침: 앱 설정 또는 배포 시 고지 URL

문의: mongyang83@gmail.com
```

## Play Console 체크리스트 (부모 에이전트/사용자)
1. [ ] **스토어 등록정보(ko-KR)** → 짧은 설명·긴 설명 위 텍스트로 **교체 후 저장**
2. [ ] **그래픽 자산 / 휴대폰 스크린샷** → 플래그된 스샷을  
      `docs/store/screenshots/play/APP_SCREENSHOT-860-replacement.png` 로 **교체**  
      (동일 파일: `03-more.png` — 「서비스 안내 / 데이터 출처」+ 공식 URL)
3. [ ] (권장) `01-home.png`, `04-detail.png`, `05-apply-list.png` 도 면책 배너가 보이면 함께 유지/재업로드
4. [ ] **인앱 면책을 리뷰어가 보려면** versionName **0.1.7** / versionCode **8** AAB(또는 APK)를 Alpha에 업로드  
      — 리스팅 문구만 고치면 콘솔 저장만으로 가능하나, **인앱 출처 화면은 새 바이너리 필요**
5. [ ] **정책** / **게시 개요**에서 변경사항 저장 후 **Alpha / 비공개 테스트 재제출**
6. [ ] 이 박스는 Play Console에 제출하지 않음 — 콘솔·Windows AAB 빌드는 부모/사용자 수행

## 검증된 공식 URL (2026-09-24 curl, 당시 기록)
| URL | HTTP |
|-----|------|
| `https://www.suwon.go.kr` | 200 |
| `https://www.suwon.go.kr/sw-www/deptHome/dep_welfare/welfare14/welfare14-04/welfare14-04-03.jsp` | 200 |
| `https://korean.visitkorea.or.kr` | 200 |
| `https://www.data.go.kr` | 200 |

2026-10-21 Play 리뷰(해외 네트워크)에서는 위 주소와 다른 `.go.kr`이 타임아웃됐다. 그 이후 나열 출처는 `https://english.visitkorea.or.kr`, `https://api.visitkorea.or.kr`만 쓴다.

## 바이너리 노트
- 리스팅 문구만: 콘솔 붙여넣기 → APK 재빌드 **불필요**
- 인앱 「서비스 안내 / 데이터 출처」반영: **AAB/APK 재빌드·업로드 필요** (`0.1.7+8`)
- 부모 에이전트가 Windows에서 `flutter build appbundle` / `apk` 수행 가능
