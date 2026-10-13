# 프로덕션 액세스 신청 답변 초안 (Loond / 로온드)

- 앱: 로온드 (Loond) · 패키지 `com.loond.loond` · 개발자 **몽양**
- 클로즈드 테스트: Alpha 트랙 · 빌드 0.1.9 (versionCode 10) · 테스터 소스 Google 그룹 `loond-app-testers`
- 작성일: 2026-10-14 (KST) · **제출 전 초안. Play Console에는 아무것도 입력·제출하지 않았음.**

## ⚠️ 동수님 확인 필요 (제출 전)
1. **14일 게이트**: 2026-10-02 옵트인 시작 기준이라 **10/16 이후**(14일 연속 + 12명 유지)에 신청. 콘솔 대시보드의 연속 일수 카운터로 확인.
2. **[동수님 확인: 실제 받은 피드백 입력]** — Q4(피드백 요약)에 들어갈 실제 내용. 출처 후보: 퍼플콣 카페 「비공개테스트 풀앗이해요」 글 댓글·쪽지, Play Console → 테스트 → 비공개 테스트 피드백(비공개 의견), 그룹 메일, 지인 메신저.
3. **[동수님 확인: 테스터 사용 행태]** — Q3에서 어떤 기능(지역 전환·APPLY·ENJOY/DISCOVER·원문 보기)을 실제로 썼는지 근거(Play Console 통계/Vitals, 피드백)로 보정. 모르면 해당 문장 삭제.
4. **Q2 모집 난이도 선택지** — 초안 추천: "보통(Neutral)" 또는 "쉬움". 실제 체감대로 선택.
5. **Q7 예상 설치 수** — 사용자 결정. 추천: **보수적 1K–10K** (대안: 0–1K).
6. **피드백 반영 변경사항** — Q8에 테스트 기간 중 변경을 "테스터 피드백 때문"이라고 쓰려면 실제 연결되는 피드백이 있어야 함. 없으면 "자체 도그푸딩/정책 심사 결과"로 표기(초안은 이렇게 작성).
7. **Q9 준비 판단 근거** — 체크리스트(UI polish·실제 AdMob·남은 광역시 APPLY) 완료 여부, Vitals 크래시/ANR 수치 확인 후 반영.
8. 글자 수: 공식 제한 미공개. 개발자 보고상 **약 300자 카운터** → 콘솔 카운터를 기준으로 줄일 것. 한국어 초안은 대체로 300자 안쪽으로 작성.

## 출처 (질문 목록)
- 공식: Play Console 고객센터 "App testing requirements for new personal developer accounts" — https://support.google.com/googleplay/android-developer/answer/14151465 (3개 섹션·프롬프트 설명, 문항 번호/글자 제한은 미공개)
- 개발자 보고 문항 문구·~300자 카운터: https://getclosedtesting.com/blog/google-play-production-access-form-questions (2026-10-05 확인 기사), 보조: https://primetestlab.com/blog/production-access-questionnaire-answers
- 실제 문구·선택지는 계정마다 다를 수 있음 → 대시보드의 **Preview questions(질문 미리보기)** 로 최종 확인.

---

## 1부. 클로즈드 테스트에 관하여 (About your closed test)

### Q1. 클로즈드 테스트 사용자를 어떻게 모집했나요?
EN: *How did you recruit users for your closed test?* · 자유 서술 · 제한 미공개(~300자 보고)

**KO 초안**
> 네이버 카페 '퍼플콣'(cafe.naver.com/devsharing)의 「비공개테스트 풀앗이해요」 게시판에 모집 글을 올렸습니다. 글에는 ①Google 그룹(loond-app-testers) 가입 ②테스트 참여(옵트인) ③Play 설치 링크 3개를 순서대로 안내했습니다. 2026-10-02경부터 12명이 연속 옵트인 상태이며 약 14회 설치되었습니다.

**EN**
> Posted a recruitment thread on the Naver Cafe "퍼플콣" (cafe.naver.com/devsharing) closed-test exchange board with 3 links: join Google Group loond-app-testers, opt in, install from Play. 12 testers have stayed opted in since ~Oct 2, 2026 (~14 installs).

### Q2. 테스터 모집은 얼마나 쉬웠나요?
EN: *How easy was it to recruit testers for your app?* · **선택형**(매우 어려움~매우 쉬움 5단계 보고)

**추천**: [동수님 확인: 체감 난이도 선택] — 카페 품앗이로 수일 내 12명 확보 → "보통" 또는 "쉬움". Q1 서술과 모순되지 않게 선택.

### Q3. 테스터 참여도(engagement)를 설명해 주세요
EN: *Describe the engagement you received from testers during your closed test* (공식 하위 프롬프트: 모든 기능 사용 여부 / 실제 프로덕션 사용 행태와 일치 여부·차이점)

**KO 초안**
> 12명이 14일 이상 연속 옵트인했고 약 14회 설치되었습니다. 테스터는 지역 선택, 신청 공고(APPLY), 축제·명소(ENJOY/DISCOVER), 공식 원문 보기를 사용했습니다. [동수님 확인: 테스터 사용 행태] 차이점: 테스터 다수가 타 지역 거주자라 실사용자보다 여러 지역을 넘겨보는 경향이 있었습니다. [동수님 확인: 사실이면 유지, 아니면 삭제]

**EN**
> 12 testers stayed opted in for 14+ days (~14 installs). They used region selection, apply notices, festivals/places and "view official source". Difference: many testers live outside the target regions, so they browsed multiple regions more than typical users would. [TO CONFIRM]

### Q4. 테스터 피드백 요약 및 수집 방법
EN: *Provide a summary of the feedback that you received from testers* (+ *describe how feedback was collected*)

**KO 초안**
> 수집 방법: 카페 모집 글 댓글·쪽지, Play Console 비공개 테스트 피드백, 문의 메일(mongyang83@gmail.com).
> 요약: [동수님 확인: 실제 받은 피드백 입력 — 예: 받은 의견 2~3건과 해당 반영 버전]

**EN**
> Collected via comments/DMs on the cafe recruitment thread, Play Console private tester feedback, and support email. Summary: [TO FILL: actual feedback received]

> ※ 피드백이 전혀 없었다면 지어내지 말고 "피드백은 적었고, 자체 실기기 점검 결과를 반영했다"고 정직하게 기재.

---

## 2부. 앱에 관하여 (About your app)

### Q5. 앱의 대상 사용자는 누구인가요?
EN: *Who is the intended audience for your app?* · "가능한 한 구체적으로"

**KO 초안**
> 국내 34개 지역(서울·광역시는 자치구 칩으로 구분) 주민과 여행자 중, 내 지역의 신청 가능한 공고·행사와 주말 축제·명소를 한곳에서 빠르게 확인하려는 성인 사용자. 정부·지자체 공식 앱이 아니며 신청 대행도 하지 않습니다.

**EN**
> Adults living in or visiting 34 Korean regions (Seoul/metros split by district chips) who want local apply notices, festivals and places in one list. Not a government app; no application proxying.

### Q6. 앱이 사용자에게 어떤 가치를 제공하나요?
EN: *Describe how your app provides value to the users*

**KO 초안**
> 흩어진 공개 정보를 지역별 한 화면으로 모읍니다. 시청 게시판을 제공하는 지역(예: 수원, 부산)은 신청 공고를, 그 외 지역은 한국관광공사 예약형 체험(시청 공고 아님으로 표시)을, 전 지역에 축제·명소를 보여 줍니다. 신청 공고가 없으면 '미제공'으로 정직하게 표시하고, 모든 항목은 「공식 원문 보기」로 원문에서 확인하게 합니다. 회원가입 없음. 비제휴 민간 앱입니다.

**EN**
> Aggregates public local info per region: city-board apply notices where available (e.g., Suwon, Busan), Korea Tourism Organization bookable experiences elsewhere (labelled as not city hall), and festivals/places everywhere. Shows "not available" honestly; every item links to the official source. No sign-up. Independent, not affiliated with any government body.

### Q7. 첫해 예상 설치 수
EN: *How many installs do you expect in your first year?* · **선택형**(범위)

**[동수님 결정 필요]** 추천: **1K–10K** (보수적). 대안: 0–1K (마케팅 계획 없을 때). Q5의 대상 규모와 일관되게.

---

## 3부. 프로덕션 준비 (Production readiness)

### Q8. 클로즈드 테스트를 통해 무엇을 변경했나요?
EN: *What changes did you make based on your closed test?* (*Describe any changes made to your app based on what you learned from your closed test*)

**KO 초안**
> 테스트 중 0.1.9(versionCode 10)까지 개선: ①지역을 34개 도시로 확장 ②서울·광역시를 한 지역+자치구 칩으로 통합 ③부산 신청 게시판 추가 ④그 외 지역은 한국관광공사 체험을 '시청 공고 아님'으로 표시 ⑤신청 공고 미제공 상태 화면 추가 ⑥Play 정책 검토 후 비정부 면책 문구·원문 출처 URL 수정. [동수님 확인: 피드백으로 바뀐 항목이 있으면 명시]

**EN**
> Up to 0.1.9 (vc 10): expanded to 34 cities; Seoul/metros as one region with district chips; added Busan apply board; national tourism experiences labelled "not city hall"; added an "apply notices unavailable" state; fixed non-government disclaimer and source URLs after Play policy review. [TO CONFIRM which came from tester feedback]

### Q9. 프로덕션 준비가 되었다고 어떻게 판단했나요?
EN: *How did you decide that your app is ready for production?*

**KO 초안**
> 12명이 14일 이상 사용하는 동안 핵심 흐름(지역 전환, 신청·축제·명소 목록, 원문 보기)을 실기기에서 점검했고, 출시 체크리스트로 UI 다듬기, 실제 AdMob 광고 연동, 남은 광역시 신청 게시판 적용(또는 '미제공' 표시)을 확인했습니다. 스토어 면책 문구·출처가 실제 동작과 일치하고 데이터 보안·콘텐츠 등급 설문을 완료했습니다. [동수님 확인: 체크리스트 완료 여부·Vitals 크래시/ANR 수치]

**EN**
> Core flows (region switching, apply/festival/place lists, official-source links) were checked on real devices during 14+ days with 12 testers. Launch checklist covers UI polish, live AdMob ads, remaining metro apply boards (or honest "unavailable" state). Store disclaimer/sources match the app; Data safety and content rating done. [TO CONFIRM checklist status & Vitals]

### (조건부) Q10. 이번에는 무엇을 다르게 했나요?
EN: *What did you do differently this time?* — "테스트 계속" 판정 후 재신청 시에만 표시. 현재 해당 없음.
