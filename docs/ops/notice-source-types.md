# 시 공고(APPLY) 소스 타입 초안

날짜: 2026-09-17  
목적: Deep 도시 APPLY를 시마다 스크래퍼 복제하지 않고, **유사 CMS끼리 타입 어댑터**로 묶기 위한 1차 택소노미.  
범위: 사용자가 언급한 거점·관광 도시 + 현재 레지스트리(경기 6) 표본. **코드 구현 전 조사 문서.**

## 타입 요약

| type id | 이름 | 식별 힌트 | 1차 판단 | PoC 우선 |
|---------|------|-----------|----------|----------|
| `eminwon_ofr` | 새올전자민원 고시공고(NTIS) | `eminwon.*.go.kr` + `/emwp/.../OfrAction.do` + `OfrNotAncmtEJB` | **가장 흔함** | **1순위** |
| `saeall_openworks` | 시청 포털 새올공고(Openworks) | `*/web/saeallOfr/BD_ofrList.do` | 수원 현재 파이프 | 2순위(이미 보유) |
| `portal_custom` | 광역/시 자체 공고 게시판 | `*.ulsan` 등 전용 path | 소수·개별 | 후순위 |
| `planweb_bbs` | planweb/일반 게시판 | `planweb/board/list.9is` | 전주 등 | 후순위 |
| `portal_bbs_openworks` | 포털 Openworks 일반 BBS | `BD_selectBbsList.do` / `q_bbsCode=` | 분야별 보드(고시 전체가 아님) | APPLY 본선 비추천 |
| `unknown` | 미분류 | — | 추가 조사 | — |

### 공통 운영 규칙 (타입과 무관)
- 목록 수집 ≠ publish. pending → **원문 CTA·모집성·마감** 검증 후 publish (수원 체크리스트 재사용).
- 채용·입찰·단순 송달/과태료 공고는 제품 블랙리스트로 제외.
- HWP 마감 자동추출은 여전히 Deferred(R2) — 타입 어댑터와 별개.

---

## 도시별 초안 표

신뢰도: **A**=목록 URL·스택 확인, **B**=동일 eminwon 패턴으로 강하게 추정, **C**=포털만 확인·추가 클릭 필요.

| region_id | 표시명 | 권역 | 추정 type | 신뢰 | 목록/진입 URL (조사 시점) | 비고 |
|-----------|--------|------|-----------|------|---------------------------|------|
| suwon | 수원 | 경기 | `saeall_openworks` | A | https://www.suwon.go.kr/web/saeallOfr/BD_ofrList.do | **현행 Worker 소스** |
| yongin | 용인 | 경기 | `eminwon_ofr` | A | https://eminwon.yongin.go.kr/…/OfrAction.do | 포털에도 고시 메뉴; 본선은 eminwon |
| seongnam | 성남 | 경기 | `eminwon_ofr` | A | https://eminwon.seongnam.go.kr/…/OfrAction.do | `selectOfrNotAncmtRegst` |
| goyang | 고양 | 경기 | `eminwon_ofr` | A | https://eminwon.goyang.go.kr/…/OfrAction.do | `selectListOfrNotAncmtHomepage` |
| bucheon | 부천 | 경기 | `eminwon_ofr` | A | https://eminwon.bucheon.go.kr/…/OfrAction.do | |
| hwaseong | 화성 | 경기 | `eminwon_ofr` | B | `eminwon.hwaseong.go.kr` 계열 추정 | 목록 파라미터 재확인 필요 |
| cheongju | 청주 | 충북 | `eminwon_ofr` (+ 포털 래퍼) | A | https://eminwon.cheongju.go.kr/…/OfrAction.do | 시청 `selectEminwonNoticeView` 래퍼 있음 |
| chungju | 충주 | 충북 | `eminwon_ofr` | B | eminwon 패턴 추정 | 미탭 |
| jecheon | 제천 | 충북 | `eminwon_ofr` | B | eminwon 패턴 추정 | 미탭 |
| danyang | 단양 | 충북 | `eminwon_ofr` | B | 군 단위도 eminwon 다수 | |
| jeonju | 전주 | 전북 | `planweb_bbs` | A | https://www.jeonju.go.kr/planweb/board/list.9is?… | 원스톱 민원 ≠ 고시 목록 |
| naju | 나주 | 전남 | `unknown` | C | — | 조사 필요 |
| mokpo | 목포 | 전남 | `unknown` | C | — | |
| yeosu | 여수 | 전남 | `unknown` | C | — | |
| gunsan | 군산 | 전북 | `unknown` | C | — | |
| gyeongju | 경주 | 경북 | `unknown` | C | — | |
| ulsan | 울산 | 광역 | `portal_custom` | A | https://www.ulsan.go.kr/u/rep/transfer/notice/list.ulsan | 시 본청 커스텀; 구는 eminwon 별도 |
| pohang | 포항 | 경북 | `unknown` | C | — | |
| gimhae | 김해 | 경남 | `unknown` | C | — | |
| tongyeong | 통영 | 경남 | `unknown` | C | — | |
| geoje | 거제 | 경남 | `unknown` | C | — | |
| andong | 안동 | 경북 | `unknown` | C | — | |
| gangneung | 강릉 | 강원 | `unknown` | C | — | |
| wonju | 원주 | 강원 | `unknown` | C | — | |
| sokcho | 속초 | 강원 | `unknown` | C | — | |
| yangyang | 양양 | 강원 | `eminwon_ofr` | B | 군 단위 eminwon 다수 | |
| gapyeong | 가평 | 경기 | `eminwon_ofr` | B | 군 | ※ 강원이 아님 |
| mungyeong | 문경 | 경북 | `unknown` | C | — | ※ 충청이 아님 |

> 표본에서 **확인된 다수결은 `eminwon_ofr`**. 수원만 `saeall_openworks`로 이미 구현됨.

---

## 타입별 어댑터 스케치

### `eminwon_ofr` (1순위 PoC)
- **host**: `eminwon.{slug}.go.kr`
- **list**: `OfrAction.do` + `jndinm=OfrNotAncmtEJB`
- **method 변형** (시마다 다름 → config):
  - `selectListOfrNotAncmt` / `selectListOfrNotAncmtHomepage`
  - `selectOfrNotAncmt` / `selectOfrNotAncmtRegst`
- **city config 예**: `base`, `list_method`, `list_methodnm`, `not_ancmt_se_code`, `detail_id_param`
- **기대 ROI**: 경기·충북 등 Deep-B 후보 상당수를 **한 어댑터 + YAML** 로 커버

### `saeall_openworks` (현행)
- 수원 `collect.py` 유지
- 동일 path를 쓰는 다른 시가 있으면 config만 추가

### `portal_custom` / `planweb_bbs`
- 도시 수 적을 때 개별 어댑터
- 울산·전주가 대표 표본

---

## Deep 정의와의 연결

| 목표 | 타입 전략 |
|------|-----------|
| 수원 수준 APPLY를 여러 시에 | **`eminwon_ofr` PoC → city config 양산** 이 본체 |
| TourAPI·문화만 두껍게 | 공고 타입 불필요 (이미 multi-city) |
| 예약 체험 큐레이션 | 스크래퍼 밖 (별도 트랙) |

권장 다음 스텝:
1. Deep-B/거점 도시 중 **미탭(C)** 15곳 eminwon DNS·목록 URL만 추가 확인 (반나절 조사)
2. `eminwon_ofr` 어댑터 PoC: 성남·고양·부천 중 1곳 end-to-end pending JSON
3. city registry YAML 초안 (`region_id`, `type`, `list_url`, `se_codes`)

---

## 한계 (정직하게)
- 같은 `eminwon_ofr`여도 method명·세션·캡차·첨부 정책이 시마다 조금씩 다름 → **100% 무설정 복제 불가**, config + 소수 분기.
- 목록 파싱 성공 ≠ 수원 품질. publish 검증 인력/반자동이 Deep 속도를 가름.
- 광역시 구 단위 eminwon(울산 남구 등)은 시 본청 보드와 분리될 수 있음.

