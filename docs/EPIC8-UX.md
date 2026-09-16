# EPIC 8 — UX: region-first + tabs

갱신: 2026-09-16 (KST)

## 결정

| 항목 | 내용 |
|------|------|
| 지역 | **시군 1곳 필수** 선택. 피드 = 선택 지역만. 스킵 없음. |
| 변경 | 앱바 **지역 칩** (설정에 묻지 않음). |
| 탭 | Material 3 `NavigationBar`: **신청 \| 즐기기 \| 발견** (APPLY / ENJOY / DISCOVER). |
| 기본 탭 | **신청** |
| MY CHANCE | 메인 탭 아님. 앱바 아이콘 → 기존 플레이스홀더 화면. |
| 데이터 | 레지스트리(`id`, `nameKo`, `areaCode`/`sigunguCode`) 확장 가능. **수원만** published JSON. 타 지역: 「이 지역 데이터 준비 중」. |

## Suwon-first → region-first

기획서 §4 온보딩의 “MVP는 수원 고정 가능”을 **region-first**로 전환한다.  
수원은 레지스트리·실데이터의 **첫 시군**이지, 앱 전체 고정 지역이 아니다.  
NOW/ANYTIME 단일 스크롤 스택은 제거하고 타입별 탭으로 분리한다. APPLY Empty는 탭 안에서만 보이며 ENJOY를 섞지 않는다.

## 유지

상세 → 공식 원문 CTA (`openOutboundUrl`), Hard Sort·만료 필터, AdMob(탭 셸 하단 배너 / 피드 네이티브 인덱스 규칙), 출처 신뢰 카피.
