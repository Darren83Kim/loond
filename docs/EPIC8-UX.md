# EPIC 8 — UX: region-first + concept mockup shell

갱신: 2026-09-16 (KST)

## 결정

| 항목 | 내용 |
|------|------|
| 지역 | **시군 1곳 필수** 선택. 피드 = 선택 지역만. 스킵 없음. |
| 변경 | 홈 앱바 **지역 칩** + 더보기「지역 변경」. 피커는 **검색 + 인기/최근 칩**. |
| 탭 | Material 3 `NavigationBar`: **홈 \| 발견 \| 내 기회 \| 더보기** (컨셉 목업). |
| 기본 탭 | **홈** — 히어로, 퀵 카테고리, NOW 신청(APPLY), 곧 시작(ENJOY 가로). |
| 발견 | 검색 + 필터 칩, DISCOVER 이미지 카드. |
| 내 기회 | BENEFIT 얇게 + 관심 키워드 UI(로컬). |
| 데이터 | 레지스트리 확장 가능. **수원만** published JSON. 타 지역: 「이 지역 데이터 준비 중」. |
| 비주얼 | 소프트 블루 시드, 카드 radius ~14, 여백 많은 밝은 UI. `docs/design/CONCEPT.md` + mockup. |

## Suwon-first → region-first

기획서 §4 온보딩의 “MVP는 수원 고정 가능”을 **region-first**로 전환한다.  
수원은 레지스트리·실데이터의 **첫 시군**이지, 앱 전체 고정 지역이 아니다.  
구 3탭(신청\|즐기기\|발견) 셸은 홈·발견 등 4탭 IA로 교체했다. APPLY Empty는 홈 NOW 섹션에서만 보이며 ENJOY를 섞지 않는다.

## 유지

상세 → 공식 원문 CTA (`openOutboundUrl`), Hard Sort·만료 필터, AdMob(탭 셸 하단 배너 / 피드 네이티브 인덱스 규칙), 출처 신뢰 카피.
