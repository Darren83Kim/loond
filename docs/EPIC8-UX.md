# EPIC 8 — UX: region-first + concept mockup shell

갱신: 2026-09-16 (KST)

## 결정

| 항목 | 내용 |
|------|------|
| 지역 | **시군 1곳 필수** 선택. 피드 = 선택 지역만. 스킵 없음. |
| 변경 | 홈 앱바 **지역 칩** + 더보기「지역 변경」. 피커는 **검색 + 인기/최근 칩**. |
| 탭 | Material 3 `NavigationBar`: **홈 \| 발견 \| 내 기회 \| 더보기** (컨셉 목업). |
| 기본 탭 | **홈** — 히어로, 퀵 카테고리, NOW 신청(APPLY), 곧 시작(ENJOY 가로). 퀵 APPLY/ENJOY·섹션 타이틀 → 전체 목록 화면. |
| 발견 | 검색 + 카테고리·**구(수원)** 필터 칩(AND) + **2열 그리드** 카드. 개략 지도는 폰 피드백으로 제거. 실좌표 핀은 deferred. |
| 내 기회 | **저장한 기회**(로컬 `BookmarkStore` ids → bundle resolve) + BENEFIT 얇게 + 관심 키워드 UI(로컬). |
| 데이터 | 레지스트리 확장 가능. **수원만** published JSON. 타 지역: 「이 지역 데이터 준비 중」. |
| 비주얼 | 소프트 블루 시드, 카드 radius ~14, 여백 많은 밝은 UI. `docs/design/CONCEPT.md` + mockup. |

## Suwon-first → region-first

기획서 §4 온보딩의 “MVP는 수원 고정 가능”을 **region-first**로 전환한다.  
수원은 레지스트리·실데이터의 **첫 시군**이지, 앱 전체 고정 지역이 아니다.  
구 3탭(신청\|즐기기\|발견) 셸은 홈·발견 등 4탭 IA로 교체했다. APPLY Empty는 홈 NOW 섹션에서만 보이며 ENJOY를 섞지 않는다.

## 유지

상세 → 공식 원문 CTA (`openOutboundUrl`), Hard Sort·만료 필터, AdMob(탭 셸 하단 배너 / 피드 네이티브 인덱스 규칙), 출처 신뢰 카피.

## Polish (2026-09-16)

| 영역 | 내용 |
|------|------|
| 상세 | 대형 히어로 이미지(`displayImageUrl`) + AppBar **공유**(share_plus) · **북마크**(로컬 SharedPreferences `BookmarkStore`). 서버 동기화 없음. CTA「공식 원문 보기」유지. |
| 내 기회 | 「저장한 기회」섹션: bookmark id를 bundle 전 타입(APPLY/ENJOY/DISCOVER/BENEFIT)에 resolve, 저장 순서 유지. 빈 상태 안내. 상세 토글 후 pop 시 MainShell `setState`로 목록 갱신. |
| 발견 | **구 칩** 전체\|장안\|권선\|팔달\|영통 — `meta.lDongSignguCd`(111/113/115/117) 우선, 없으면 location/summary/description/title 문자열. 카테고리 칩과 AND. **2열 그리드**(`DiscoverGridCard`). 결과 건수 유지. **개략 지도 제거**(폰 피드백). **실좌표 핀 deferred**. 별점·가짜 평점 없음. |
| 홈 | 히어로(~78)·퀵 카테고리·섹션 타이틀 주변 세로 여백 추가 축소. **오디언스 세그먼트**(`살고 있어요` \| `여행·체류 중`, prefs `home_audience_mode`). 거주=NOW APPLY 우선+곧 열려요; 여행=곧 열려요→발견 미리보기→APPLY 보조. 같은 지역 데이터·순서/카피만 변경. |
| 브랜딩·히어로 | 홈 헤더 Material pin → **커스텀 Loond pin 로고** (`assets/images/loond_pin_logo.png`). 지역 히어로: 수원 `hero_suwon.png`(화성 성곽 배너), 기타 레지스트리 지역 `hero_default.png`. `Region.heroAsset` 우선, 없으면 `heroImageUrl`/플레이스홀더. 레퍼런스 카피: `docs/design/`. |


## Home audience mode (idea A)

| 항목 | 내용 |
|------|------|
| UI | 홈 히어로 아래 Material 3 `SegmentedButton`: **살고 있어요** \| **여행·체류 중** |
| Persist | SharedPreferences `home_audience_mode` = `resident` \| `traveler` (기본 `resident`). `HomeAudienceStore` |
| Resident | 현재 홈과 유사: APPLY(NOW·신청·참여 강조) → ENJOY(곧 열려요) |
| Traveler | ENJOY → **발견 미리보기** → APPLY 보조「이 지역에서 신청할 수 있는 것」(**방문객·체류 적합만**; 주민센터·심리상담·자원봉사 등 거주자 전용 제외, 없으면 empty copy) |
| 범위 | 새 API·멀티지역·지도·Discover 탭 구조 변경 없음. BENEFIT 데이터 발명 없음. |

## Discover map phases

| Phase | 내용 | 상태 |
|-------|------|------|
| 1 | 구 칩 + 2열 그리드 | Done (`74828a5`) |
| 2 | 수원 4구 **개략 지도**(CustomPainter) → 동일 구 필터. SDK/핀 없음 | Removed — 폰 피드백으로 칩만 유지 |
| 3 | 실좌표 핀 (Worker mapx/mapy 등) | Deferred — 좌표·멀티지역 준비 후 |

## 11. Residual / Open / Deferred

| 항목 | 상태 | 이유 |
|------|------|------|
| 시군별 **고유** 히어로 아트 (용인·성남·고양·부천·화성 등) | Open / Deferred | 현재는 수원 전용 + 공용 default 배너만 번들. 도시별 커스텀 일러스트/사진은 아트 제작·라이선스 후 `Region.heroAsset`에 개별 경로로 확장. |
| 발견 **실좌표 핀 / 멀티지역 Worker** | Deferred | phase 2는 수원 4구 개략 지도(칩과 동일 필터). phase 3 핀·좌표·타 시군 Worker는 별도. |

