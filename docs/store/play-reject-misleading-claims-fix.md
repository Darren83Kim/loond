# Play 정책 재제출 — Misleading Claims (혼동을 야기하는 주장)

- 일시: 2026-09-22 (KST)
- 트랙: 비공개(클로즈드) 테스트 / Alpha submission #2
- 플래그: ko-KR **긴 설명** + 스크린샷 **APP_SCREENSHOT-860.png**

## 원인 (리뷰어 지적)
1. 공식 정부 출처 링크(.go.kr)가 스토어 문구/스샷에서 충분히 명확하지 않음
2. 비공식(비정부) 소속 면책이 충분히 명확하지 않음

## 조치 요약
| 항목 | 경로 |
|------|------|
| 짧은·긴 설명 (붙여넣기용) | `docs/store/listing-ko.md` |
| 플래그 스샷 교체본 | `docs/store/screenshots/play/APP_SCREENSHOT-860-replacement.png` (= `03-more.png`) |
| 추가 면책 배너 스샷 | `01-home.png`, `04-detail.png`, `05-apply-list.png` |
| 인앱 면책 문구 | `app/lib/ui/tabs/more_tab.dart`, `settings_screen.dart`, `detail_screen.dart` |

## 콘솔 붙여넣기 — 짧은 설명
```
이 앱은 정부·지자체 공식 앱이 아닙니다. 수원 등 공고·행사를 모아 공식 원문으로 안내.
```

## 콘솔 붙여넣기 — 긴 설명
```
【중요 · 면책】이 앱은 정부·지자체 공식 앱이 아니며 공공기관을 대표하지 않습니다. 로온드는 민간에서 만든 비공식 안내 앱이며, 수원특례시·정부기관과 제휴·위탁·운영 관계가 없습니다.

로온드는 수원(수원특례시) 등 지역의 공공·지역 기회를 신청(APPLY) · 즐기기(ENJOY) · 발견(DISCOVER)으로 정리해 보여주는 비공식 안내 앱입니다. 회원가입 없이 요약만 보고, 신청·자격·일정은 반드시 각 항목의 공식 원문 링크로 확인하세요.

■ 정보 출처 (공식 · .go.kr)
• 데이터는 지자체·공공기관이 공개한 고시/공고·복지 안내 등 공개 자료를 모아 안내합니다. 앱 상세의 「공식 원문 보기」로 해당 원문 페이지로 이동합니다.
• 대표 공식 출처(수원특례시): https://www.suwon.go.kr
• 복지 안내 예시(수원 청년기본소득): https://www.suwon.go.kr/sw-www/deptHome/dep_welfare/welfare14/welfare14-04/welfare14-04-03.jsp
• 관광 연계 정보: https://korean.visitkorea.or.kr (한국관광공사 TourAPI)
• 성남·고양 등 다른 지역 고시/공고도 각 항목의 공식 원문 URL을 따릅니다.

■ 이런 분께 맞춰요
• 신청 마감이 가까운 공고를 빠르게 보고 싶을 때
• 주말에 즐길 행사·관광 정보를 한 목록에서 보고 싶을 때
• 회원가입·점수·복잡한 알림 없이 원문만 확인하고 싶을 때

■ 주요 기능
• NOW: 지금 신청·참여 가능한 기회
• ANYTIME: 언제든 둘러보는 발견 콘텐츠
• 상세에서 일정·요약·출처를 확인한 뒤 「공식 원문 보기」로 이동
• 신청 마감이 지난 공고는 목록에서 제외 (데이터에는 남을 수 있음)

■ 다시 한 번 면책
이 앱은 정부·지자체 공식 앱이 아니며 공공기관을 대표하지 않습니다. 공고·행사·복지·관광 정보는 각 공식 출처를 모아 안내할 뿐이며, 일정·자격·접수 방법·수급 여부·법적 효력은 반드시 해당 .go.kr 등 공식 원문에서 확인하세요.

■ 기타
• 광고(AdMob)가 표시될 수 있습니다.
• 개인정보처리방침: 앱 설정 또는 배포 시 고지 URL

문의: contact@loond.example (플레이스홀더)
```

## Play Console 체크리스트 (부모 에이전트/사용자)
1. [ ] **스토어 등록정보(ko-KR)** → 짧은 설명·긴 설명 위 텍스트로 **교체 후 저장**
2. [ ] **그래픽 자산 / 휴대폰 스크린샷** → 플래그된 `APP_SCREENSHOT-860.png`를  
      `docs/store/screenshots/play/APP_SCREENSHOT-860-replacement.png` 로 **교체**  
      (동일 파일: `03-more.png` — 더보기 탭에 면책 + `suwon.go.kr` URL 표시)
3. [ ] (권장) 같은 폴더의 `01-home.png`, `04-detail.png`, `05-apply-list.png` 도 함께 재업로드 (상단 면책 배너)
4. [ ] **정책** / **게시 개요**에서 변경사항 저장 후 **Alpha / 비공개 테스트 재제출**
5. [ ] 이 박스는 Play Console에 제출하지 않음 — 콘솔 업로드는 부모/사용자 수행

## 검증된 공식 URL
- `https://www.suwon.go.kr` (시 포털)
- `https://www.suwon.go.kr/sw-www/deptHome/dep_welfare/welfare14/welfare14-04/welfare14-04-03.jsp` (청년기본소득 · HTTP 200 확인)
