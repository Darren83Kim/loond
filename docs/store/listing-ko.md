# 로온드 — 스토어 리스팅 초안 (한국어)

## 앱 이름
**로온드**

## Play 앱 만들기 필드
- 패키지 이름: `com.loond.loond` (변경 불가 · applicationId와 동일)
- 기본 언어: 한국어(ko-KR)
- 앱 / 무료
- 그래픽: `docs/store/play/icon-512.png`, `feature-graphic.png`
- 스크린샷: `docs/store/screenshots/play/` (업로드용) · 원본 `docs/store/screenshots/phone/`

## 짧은 설명 (≈80자 이내) — 콘솔 붙여넣기용
```
민간 비제휴 안내 앱입니다. 공개 공고를 모아 「공식 원문 보기」로만 안내합니다.
```

## 긴 설명 (ko-KR) — 콘솔 붙여넣기용
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

## Full description (en) — console paste
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

## 키워드 (초안)
수원, 수원특례시, 공고, 신청, 행사, 축제, 관광, 청년, 시민, 공공, 모집, 로온드, loond, 기회, 문화, 비공식, 민간, 비제휴

## 카테고리 제안
라이프스타일 / 뉴스 및 잡지 / 여행 및 지역정보 (스토어 정책에 맞게 1개 선택)

## 스크린샷 체크리스트
- [x] 홈 NOW — APPLY 섹션
- [x] 내 기회 / 더보기
- [x] 상세 — 제목, D-Day, 원문 버튼
- [x] 더보기 — 「서비스 안내 / 데이터 출처」면책·공식 URL 표시 (`play/03-more.png`)
- [ ] 가로·세로 비율·스토어 권장 해상도 준수 (Play 가이드)

### Play 정책 재제출 (Misleading Claims) — 2026-10-21
- 거절: **0.1.10** (versionCode **11**). 리뷰어가 정부 출처 링크에 접속하지 못함. 해외 네트워크에서 `.go.kr` 사이트와 `korean.visitkorea.or.kr`, `data.go.kr`이 타임아웃. `https://english.visitkorea.or.kr`, `https://api.visitkorea.or.kr`만 열림.
- 조치: 인앱 「서비스 안내 / 데이터 출처」와 위 스토어 설명의 나열 URL을 그 두 주소로 교체. 지역 고시·공고·복지는 각 상세의 「공식 원문 보기」로 발행 기관 원문에 연결된다고 명시. 비제휴 면책은 앞에 그대로 둠. 앱 버전 **0.1.11+12**.
- 상세: `docs/store/play-reject-misleading-claims-fix.md`

### Play 정책 재제출 (Misleading Claims) — 2026-09-24 (4차)
- 신고: 긴 설명의 「성남·고양 등 …」문구 — 출처 URL 없이 다중 지역 언급
- 조치: 도시명 단독 나열 제거 · 검증된 .go.kr/공식 URL만 열거 · 문의 메일 실주소 · 인앱 출처 화면 강화
- 상세: `docs/store/play-reject-misleading-claims-fix.md`

## 내부 테스트 메모
- [ ] Play Console **비공개(클로즈드) 테스트 / Alpha** 트랙 재제출
- [ ] 스토어 등록정보: 짧은·긴 설명 붙여넣기 후 저장
- [ ] 플래그된 스크린샷을 `APP_SCREENSHOT-860-replacement.png`(= `play/03-more.png`)로 교체
- [ ] 인앱 면책 반영 바이너리(AAB/APK) — versionName 0.1.7 / versionCode 8
- [ ] 개인정보처리방침 URL 일치 확인

## 비고
- 스토어 개인정보 URL: 당분간 GitHub `docs/legal/privacy-policy.md` 가능, **배포 시 전용 HTTPS 페이지로 교체**
- AdMob **운영(프로덕션) 유닛 ID는 문서·리스팅에 기재하지 않음**
- **정부·지자체 제휴/공식 앱임을 암시하는 표현 금지**

## 촬영본
- Play 업로드: `docs/store/screenshots/play/`
- 실기기 원본: `docs/store/screenshots/phone/`
