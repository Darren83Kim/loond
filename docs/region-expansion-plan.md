# 지역 확장 계획서 (Phase 1 대도시 13 · Phase 2 관광도시 19)

작성: 2026-09-29 (KST) · 상태: **초안 — 사용자 검토 대기 (코드 미구현)**  
관련: [`구현계획서.md`](구현계획서.md) §11 · [`ops/multi-city.md`](ops/multi-city.md) · [`ops/notice-source-types.md`](ops/notice-source-types.md) · [`ops/remote-region-load.md`](ops/remote-region-load.md)

> 승인된 결정: 테스터 모집 전에 지역을 확장한다.  
> 순서: **① 본 문서(검토) → ② Phase 2 관광도시(ENJOY/DISCOVER) → ③ Phase 1 도시별 APPLY.**  
> Play 스토어 등록정보는 **변경하지 않는다** (Misleading Claims 대응으로 도시명 비노출 유지). 앱 내부 도시 라벨은 무관.

---

## 0. 요약 (TL;DR)

1. **현재**: 경기 6개 시(수원·용인·성남·고양·부천·화성)만. TourAPI는 `areaCode=31` 한 번 수집 → **주소/제목 키워드**로 시 배정. APPLY는 수원(상시 파이프, 12건) + 성남 10·고양 1 (eminwon 1회성 merge). **APPLY 수집은 daily Actions에 편입돼 있지 않다.**
2. **지역코드 체계**: 기존 `id`(영문 slug)는 유지하되, 시 배정 키를 **TourAPI 법정동 코드**(`lDongRegnCd` + `lDongSignguCd`, = 행정표준 5자리 시군구코드)로 바꾼다. 2026-09-29 `ldongCode2` 실조회로 전 도시 코드 확정(§1).
3. **2026 행정구역 변경 3건 발견 (중요)**  
   - **광주광역시 → 전남광주통합특별시(2026-07-01)**: 시도코드 `29`/`46` 소멸 → `12`. 광주 = `12` 의 5개 구(동·서·남·북·광산). 구 광주시청 고시공고는 "(구)" 아카이브로 전환.  
   - **인천 구 개편**: 중구·동구·서구 → 제물포구(`28125`)·영종구(`28155`)·서해구(`28275`)·검단구(`28290`). 인천 `중구 110` 조회 결과 0건.  
   - **화성시 4개 구 신설**(만세·효행·병점·동탄 `591~597`): 데이터가 부모코드 `590`(302건)과 신규 구(81건)에 **혼재** → 부모+하위 코드 모두 조회해야 함.
4. **서울**: **단일 지역 `seoul`** + 앱 내 **자치구 필터 칩**(수원 구 칩과 같은 방식, `lDongSignguCd` 기반) 권장. 자치구 25개 분리는 하지 않음(§2).
5. **APPLY 소스(Phase 1)**: eminwon 5곳(고양·용인·화성·창원·세종)은 기존 어댑터로 **하**. 광역시는 대부분 **자체 게시판** → 신규 어댑터 필요. 서울은 **서울시 공공서비스예약 OpenAPI**가 최선(구조화·접수상태 포함). 광주는 통합특별시 게시판이 **WAF 차단** → **상/보류 후보**.
6. **블로커/리스크**: TourAPI **개발계정 1,000건/일/오퍼레이션** 한도(현 키가 개발/운영 중 무엇인지 확인 필요) · 서울 열린데이터광장 인증키 신규 발급 필요 · GitHub Actions(해외 IP)에서 지자체 게시판 차단 가능성 · 서울 피드 크기(원천 8,003건).

---

## 1. 전체 도시 표

### 1-1. 코드 체계 (기존 → 제안)

| 항목 | 기존 | 제안 |
|------|------|------|
| 지역 id | 영문 slug (`suwon`) | **유지** (앱 SharedPreferences·manifest·파일명 호환) |
| TourAPI 필터 | `areaCode=31`(legacy) + addr/title 키워드 | **`lDongRegnCd` + `lDongSignguCd[]`** (KorService2 법정동 코드). 키워드는 fallback |
| 시군구 코드 | `sigunguCode='13'`(관측값, 수원만) | 행정표준 5자리 = `lDongRegnCd`(2) + `lDongSignguCd`(3). 예: 수원 장안구 `41111` |
| legacy areaCode | `31` | 참고용으로만 보관 (searchFestival2 `areaCode=31` → 2건뿐, 이미 전국 fallback으로 수집 중) |

검증 사실 (2026-09-29, 박스에서 KorService2 실호출):
- `ldongCode2` 시도 목록 16개: 11 서울, **12 전남광주통합특별시**, 26 부산, 27 대구, 28 인천, 30 대전, 31 울산, 36110 세종, 41 경기, 43 충북, 44 충남, 47 경북, 48 경남, 50 제주, 51 강원, 52 전북.
- **구가 있는 시는 부모 시코드로 조회하면 0건**(수원 `41/110` → 0, `41/111` → 144). 화성은 예외적으로 부모 `590`에 데이터 잔존. → 설정에 **부모+하위 코드 모두** 넣고 조회 결과를 합친다.
- 세종은 `lDongRegnCd=36110` 단독(205건).

### 1-2. 도시 표 (32개 + 기존 유지 2개)

- **TourAPI 건수** = `areaBasedList2` 전체 콘텐츠타입 totalCount 합(2026-09-29). 게시 대상(12/14/25/28/38/39)과 캡 적용 전 원천 규모 참고치.
- **현재 상태**: 있음 = `RegionRegistry` + `regions/{id}.json` 게시 중.
- 카테고리: A=APPLY, E=ENJOY(축제·행사), D=DISCOVER(명소·맛집 등), B=BENEFIT(현재 수원만 6건).

#### Phase 1 — 대도시 13 (full depth, APPLY 포함)

| id | 표시명 | 시도 | lDongRegnCd | lDongSignguCd (조회 대상) | 5자리 코드 | legacy areaCode | 제공 카테고리 | TourAPI 건수 | 현재 상태 |
|----|--------|------|------|------|------|------|------|------:|------|
| seoul | 서울 | 서울특별시 | 11 | (시도 전체) 자치구 25: 110~740 | 11110~11740 | 1 | A·E·D | 8,003 | 없음 |
| busan | 부산 | 부산광역시 | 26 | (시도 전체) 16 구·군 | 26110~26710 | 6 | A·E·D | 2,227 | 없음 |
| daegu | 대구 | 대구광역시 | 27 | (시도 전체) 9 구·군 (군위군 720 포함) | 27110~27720 | 4 | A·E·D | 1,195 | 없음 |
| incheon | 인천 | 인천광역시 | 28 | (시도 전체) 11 — **2026 개편 구**: 125 제물포·155 영종·177·185·200·237·245·275 서해·290 검단·710·720 | 28125~28720 | 2 | A·E·D | 1,981 | 없음 |
| gwangju | 광주 | **전남광주통합특별시** | 12 | 210 동·240 서·270 남·300 북·330 광산 | 12210~12330 | 5 | A(난이도 상)·E·D | 625 | 없음 |
| daejeon | 대전 | 대전광역시 | 30 | (시도 전체) 110~230 | 30110~30230 | 3 | A·E·D | 843 | 없음 |
| ulsan | 울산 | 울산광역시 | 31 | (시도 전체) 110~200, 710 울주 | 31110~31710 | 7 | A·E·D | 654 | 없음 |
| sejong | 세종 | 세종특별자치시 | 36110 | (단일) | 36110 | 8 | A·E·D | 205 | 없음 |
| suwon | 수원 | 경기도 | 41 | 111·113·115·117 (+부모 110) | 41111~41117 | 31 | A·E·D·B | 706 | **있음 (deep)** A12/E36/D98/B6 |
| goyang | 고양 | 경기도 | 41 | 281·285·287 (+280) | 41281~41287 | 31 | A·E·D | 704 | **있음** A1/E12/D86 |
| yongin | 용인 | 경기도 | 41 | 461·463·465 (+460) | 41461~41465 | 31 | A·E·D | 659 | **있음** E9/D164 (A 없음) |
| changwon | 창원 | 경상남도 | 48 | 121·123·125·127·129 (+120) | 48121~48129 | 36 | A·E·D | 516 | 없음 |
| hwaseong | 화성 | 경기도 | 41 | **590(부모, 302건)**·591·593·595·597 | 41590~41597 | 31 | A·E·D | 383 (302+81) | **있음** E/D (A 없음) |

#### Phase 2 — 관광도시 19 (E·D만, APPLY는 "미제공" 명시)

| id | 표시명 | 시도 | lDongRegnCd | lDongSignguCd | 5자리 | legacy areaCode | 제공 | TourAPI 건수 | 현재 | 참고: eminwon config (후속 APPLY 후보) |
|----|--------|------|------|------|------|------|------|------:|------|------|
| gangneung | 강릉 | 강원 | 51 | 150 | 51150 | 32 | E·D | 997 | 없음 | 있음(verified) |
| sokcho | 속초 | 강원 | 51 | 210 | 51210 | 32 | E·D | 265 | 없음 | unknown(목록 빈 셸) |
| chuncheon | 춘천 | 강원 | 51 | 110 | 51110 | 32 | E·D | 412 | 없음 | 미조사 |
| gyeongju | 경주 | 경북 | 47 | 130 | 47130 | 35 | E·D | 622 | 없음 | 있음(verified) |
| andong | 안동 | 경북 | 47 | 170 | 47170 | 35 | E·D | 260 | 없음 | portal_custom |
| tongyeong | 통영 | 경남 | 48 | 220 | 48220 | 36 | E·D | 421 | 없음 | 있음(verified) |
| geoje | 거제 | 경남 | 48 | 310 | 48310 | 36 | E·D | 466 | 없음 | 있음(verified) |
| jeonju | 전주 | 전북 | 52 | 111·113 (+110) | 52111~52113 | 37 | E·D | 473 | 없음 | planweb_bbs |
| gunsan | 군산 | 전북 | 52 | 130 | 52130 | 37 | E·D | 331 | 없음 | 있음(verified) |
| yeosu | 여수 | **전남광주통합** | 12 | 130 | 12130 | 38 | E·D | 464 | 없음 | portal_custom |
| suncheon | 순천 | **전남광주통합** | 12 | 150 | 12150 | 38 | E·D | 200 | 없음 | 미조사 |
| gongju | 공주 | 충남 | 44 | 150 | 44150 | 34 | E·D | 222 | 없음 | 미조사 |
| buyeo | 부여 | 충남 | 44 | 760 | 44760 | 34 | E·D | 199 | 없음 | 미조사 |
| danyang | 단양 | 충북 | 43 | 800 | 43800 | 33 | E·D | 160 | 없음 | 있음(HTTPS 불안정) |
| chungju | 충주 | 충북 | 43 | 130 | 43130 | 33 | E·D | 289 | 없음 | 있음(verified) |
| jeju | 제주 | 제주 | 50 | 110 | 50110 | 39 | E·D | 1,256 | 없음 | 미조사 |
| seogwipo | 서귀포 | 제주 | 50 | 130 | 50130 | 39 | E·D | 864 | 없음 | 미조사 |
| gapyeong | 가평 | 경기 | 41 | 820 | 41820 | 31 | E·D | 410 | 없음 | 있음(verified) |
| paju | 파주 | 경기 | 41 | 480 | 41480 | 31 | E·D | 735 | 없음 | 미조사 |

> 군 단위(부여·단양·가평)는 `chipLabel`이 `…시`로 붙지 않도록 `nameKo`를 `부여군`/`단양군`/`가평군`으로 두거나 `displaySuffix` 필드를 추가한다(현재 `chipLabel`은 `시/군/구`로 끝나지 않으면 `시`를 붙임 → "부여시" 오표기 위험).

#### 기존 유지 (Phase 목록 밖)

| id | 표시명 | lDong | 현재 | 제안 |
|----|--------|------|------|------|
| seongnam | 성남 | 41 / 131·133·135 (+130) | 있음 A10/E8/D90 | **유지 권장** (이미 게시 중, 선택한 사용자 존재 가능. 삭제 시 저장된 `selected_region_id` 깨짐). 결정 필요 → R30 |
| bucheon | 부천 | 41 / 192·194·196 (+190) | 있음 E9/D68 | 동일 |

데이터 소스 공통:
- **ENJOY**: TourAPI `searchFestival2` (전국 1회 수집 ≈ 759건/8페이지 → 법정동 코드로 배정) + 문화포털(공연·전시) 도시별 조회.
- **DISCOVER**: TourAPI `areaBasedList2` contentTypeId 12/14/25/28/38/39 (+`detailCommon2` 홈페이지 보강, 회당 40건 한도).
- **APPLY**: Phase 1만, 도시별 공식 게시판(§1-3).

### 1-3. Phase 1 APPLY 수집 난이도

URL 응답 검증: 2026-09-29 박스에서 `curl` (HTTP 코드 / 목록 행 존재 여부). GitHub Actions(해외 IP)에서의 응답은 **미검증**.

| id | 1차 소스 (URL) | 타입 | 응답 | 보조 소스 | 난이도 | 비고 |
|----|---------------|------|------|-----------|:---:|------|
| suwon | https://www.suwon.go.kr/web/saeallOfr/BD_ofrList.do | `saeall_openworks` | 200 | — | — (보유) | 현행 파이프. daily 미편입 |
| goyang | http://eminwon.goyang.go.kr/emwp/gov/mogaha/ntis/web/ofr/action/OfrAction.do?method=selectListOfrNotAncmt&methodnm=selectListOfrNotAncmtHomepage&jndinm=OfrNotAncmtEJB&context=NTIS&homepage_pbs_yn=Y&not_ancmt_se_code=01%2C04%2C05&ofr_pageSize=10&subCheck=Y | `eminwon_ofr` | 200, 행 있음 | — | **하** | PoC 완료, 게시 1건 |
| yongin | http://eminwon.yongin.go.kr (동일 OfrAction 경로) | `eminwon_ofr` | 200, 행 있음 | — | **하** | `notice_sources.py`는 `_JSP` 변형 → **action 변형으로 교체** 필요 |
| hwaseong | http://eminwon.hscity.go.kr (동일 경로) | `eminwon_ofr` | 200, 행 있음 | — | **하** | host=`hscity` |
| changwon | http://eminwon.changwon.go.kr (동일 경로) | `eminwon_ofr` | 200, 행 있음 | https://www.changwon.go.kr/cwportal/10310/10438/10439.web (고시공고, 200) | **하** | config 신규 추가 |
| sejong | http://eminwon.sejong.go.kr (동일 경로) | `eminwon_ofr` | 200, 행 있음 | https://www.sejong.go.kr/bbs/R0071/list.do (공지사항, 200 — "참가자 모집" 다수) | **하** | 공지사항이 시민 모집 신호가 더 좋음 → 2차 어댑터 |
| seoul | **서울시 공공서비스예약 OpenAPI** `http://openapi.seoul.go.kr:8088/{KEY}/json/ListPublicReservationEducation/1/100/` (교육 399건, 접수상태·기간·URL·자치구 필드) | `open_api` (신규) | 200 (sample 키) | 고시공고 https://www.seoul.go.kr/news/news_notice.do (200, 서버렌더 `fnTbbsView`) | **중** (API는 하, 키 발급 필요) | 문화행사·체육시설 예약 등 동류 서비스 추가 가능. 고시공고는 행정공고 비중 높음 |
| busan | **부산민원120 행사/모집 신청** https://www.busan.go.kr/minwon/occation | `portal_custom` | 200, 시민 모집 행 확인("시민 참가자 모집", "열린강좌") | 고시공고 https://www.busan.go.kr/nbgosi (200) | **중** | 시민 대상 모집이 분리돼 있어 필터 부담 작음 |
| daegu | **대구 민원 공모·모집** https://minwon.daegu.go.kr/pssrp/list | `portal_custom` | 200 | 고시공고 https://www.daegu.go.kr/index.do?menu_id=00940170 (200) | **중** | 채용·위원 모집 혼재 → 블랙리스트 필수 |
| incheon | **citynet 고시/공고** http://announce.incheon.go.kr/citynet/jsp/sap/SAPGosiBizProcess.do?command=searchList&flag=gosiGL&svp=Y&sido=ic | `citynet_gosi` (신규 타입) | 200, 행 있음 | 포털 https://www.incheon.go.kr/IC010205 (JS 셸) | **중** | 동일 citynet 스택이 전남광주에도 있음 → 어댑터 재사용 |
| daejeon | 고시공고 https://www.daejeon.go.kr/drh/MediaList.do?notiType=NOTI_06&menuSeq=2564 | `portal_custom` | 200, 행 있음 | — | **중** | 구청·동 공고(통장 모집 등) 혼재 → 필터. eminwon.daejeon 없음 |
| ulsan | https://www.ulsan.go.kr/u/rep/transfer/notice/list.ulsan | `portal_custom` | 200 → 재시도 시 **500(서비스 장애)** | — | **중상** | 불안정. 입찰·평가위원 공고 비중 높음 |
| gwangju | 통합특별시 고시공고 https://www.jeonnam-gwangju.go.kr/contentsView.do?pageId=jngj24 → iframe `https://sido.jeonnam.go.kr/citynet/...SAPGosiBizProcess.do` | `citynet_gosi` | 페이지 200 / **iframe 목록 WAF 차단** | (구) https://www.gwangju.go.kr/contentsView.do?pageId=www791 (아카이브) | **상 (보류 후보)** | 임시 누리집 → 개편 가능성. 자치구 eminwon 대안 미조사 → R25 |

eminwon 공통 경로: `/emwp/gov/mogaha/ntis/web/ofr/action/OfrAction.do?method=selectListOfrNotAncmt&methodnm=selectListOfrNotAncmtHomepage&jndinm=OfrNotAncmtEJB&context=NTIS&homepage_pbs_yn=Y&not_ancmt_se_code=01%2C04%2C05&ofr_pageSize=10&subCheck=Y`  
광역시 `eminwon.{seoul,busan,daegu,incheon,gwangju,daejeon,ulsan}.go.kr` 는 모두 **접속 불가(DNS/연결 실패)** — 광역 본청은 eminwon을 쓰지 않는다(구청은 별도 eminwon 보유 가능).

---

## 2. 서울 처리 — 권장: **단일 지역 + 자치구 필터 칩**

| 안 | 장점 | 단점 |
|----|------|------|
| A. `seoul` 단일 지역 (권장) | 수집 1회(`lDongRegnCd=11`), 피드 1개, 피커 항목 1개. APPLY 소스(공공서비스예약 API·시 고시공고)가 **시 단위**라 자연스러움 | 원천이 커서(8,003건) 캡 필요. "우리 동네" 체감은 약함 → 칩으로 보완 |
| B. 자치구 25개 지역 | 동네 밀착 | 피커 25항목, 구별 데이터 편차 큼(일부 구 수십 건), APPLY는 구청 eminwon 25개 별도, manifest·Actions·검수 부담 25배. **스코프 과다** |
| C. 권역 5개(도심·동북·서북·서남·동남) | 절충 | 공식 행정단위가 아니라 출처 표기·사용자 인지 애매 |

**권장 = A**, 이유:
1. 테스터 모집 전 단계에서 서울만 25배 운영비를 쓰는 건 과함. 광역시(부산 16·대구 9·인천 11 구군)도 같은 원칙으로 **시 단위 1지역**.
2. 모든 TourAPI 항목에 `lDongSignguCd`가 붙어 있어, 앱에서 **자치구 칩 필터**(현재 수원 `DiscoverDistrict.suwonGus`를 코드 기반으로 일반화)로 구 단위 탐색이 가능 — 데이터 분리 없이 체감 확보.
3. 서울 공공서비스예약 API 행에 자치구/장소 필드가 있어 APPLY도 칩 필터에 태울 수 있음.
4. 피드 크기: DISCOVER를 타입별 캡(예: 12=120, 14=80, 28=40, 38=30, 39=40)으로 제한해 `seoul.json` ≤ ~400KB(gzip ~40KB) 목표.
5. 추후 피드백으로 필요하면 `seoul-gangnam` 같은 하위 지역을 **추가**(기존 `seoul` 유지)하는 방식으로 확장 → R29.

---

## 3. 구현 계획

### 3-1. 단계별 작업 · 공수 (1인 기준, d=작업일)

| 단계 | 작업 | 산출/변경 파일 | 공수 |
|------|------|---------------|-----:|
| **S0** | 본 문서 검토·확정 (서울 A안, 성남·부천 유지, 광주 APPLY 보류 여부) | 본 문서 | 사용자 |
| **S1** | **Worker 지역 카탈로그 v2**: `REGIONS`에 `sido`, `ldong_regn`, `ldong_signgu[]`(부모+하위), `legacy_area_code`, `tier`(phase1/phase2/legacy), `apply_mode`(`full`/`none`), `culture_sido`/`culture_gugun` 추가. 34개 등록. `assign_region()`을 **법정동 코드 우선 → 키워드 fallback**으로 교체(고양이·홍성남·수원화성 가드 불필요해짐) | `region_codes.py`, `docs/ops/multi-city.md` | 1d |
| **S2** | **TourAPI 수집 전략 변경**: ENJOY=전국 `searchFestival2` 1회(현행 fallback과 동일, 8p) → 코드 배정. DISCOVER=`areaBasedList2`를 **시도 단위 스윕**(경기처럼 대상 시가 많은 시도) 또는 **시군구 단위 조회**(그 외) 중 호출 수가 적은 쪽으로 계획 생성. 밀집 타입(38/39)은 `arrange=Q`(수정일순) **1페이지**만. 타입별 캡 per region. `max_pages` 상한·전체 호출 예산 카운터(예산 초과 시 stop + 로그) | `run_tour_daily.py` | 1.5d |
| **S3** | **문화포털 다시도화**: 현재 `sido="경기"` 하드코딩 → 지역별 `culture_sido`. 전남광주 통합 후 문화포털의 시도명(광주/전남) 표기 실측 필요. 도시당 호출 2회 × 34 | `culture_collect.py` | 0.5d |
| **S4** | **publish/manifest**: manifest 항목에 `sido`, `tier`, `applyStatus`(`provided`/`not_provided`/`preparing`), `depth`(`deep`/`tour`) **추가 필드**(schemaVersion 1 유지, 앱 구버전은 무시). 34개 `regions/*.json` 생성. Pages sanity check에 신규 파일 존재 확인 추가 | `publish_regions.py`, `pages.yml` | 0.5d |
| **S5** | **앱**: `Region`에 `sido`, `applyMode`, `displaySuffix` 추가, `RegionRegistry` 34개(시도 순서). **피커 시도별 그룹핑**(섹션 헤더 `서울·경기·강원…`, 검색은 도시명+시도명), "현재 실제 데이터가 있는 지역은 수원입니다" 문구 제거, 행 서브텍스트를 "신청·행사·발견" / "행사·발견 (신청 공고 미제공)"으로. **APPLY 미제공 상태**: 홈 신청 섹션·신청 탭에서 빈 목록 대신 "이 지역은 아직 신청 공고를 모으지 않아요. 행사·발견을 확인해 보세요" + 발견 탭 이동 CTA (빈 상태 `이 지역 데이터 준비 중`과 구분). 자치구 칩 일반화(`lDongSignguCd` → 구 이름 맵, 서울·광역시·구 있는 시). 인기 칩은 Phase 1 우선. 위젯 테스트(`region_gate_test`, `home_empty_apply_test`) 갱신 | `models/region.dart`, `ui/region_picker_screen.dart`, `ui/tabs/home_tab.dart`, `opportunity_tab.dart`, `util/discover_district.dart`, tests | 1.5–2d |
| **S6** | **Actions**: `timeout-minutes: 30`, 호출 예산 로그(오퍼레이션별 호출 수 → 로그/`data/raw` 메타), TourAPI resultCode 22(한도 초과) 시 **이전 피드 유지 + 이슈 생성**(현재는 실패 시 이슈만). 9/28 TourAPI 단계 실패 1회 원인 점검 | `daily_worker.yml`, `run_tour_daily.py` | 0.5d |
| — | **② Phase 2 출시 컷** = S1~S6 (관광 19 + 대도시 13의 E·D가 동시에 열림. Phase 1 도시는 APPLY 준비 전까지 `applyStatus=preparing`) | | **≈5.5–6d** |
| **S7** | **Phase 1 APPLY — eminwon 5곳** (고양·용인·화성·창원·세종): `notice_sources` config(용인 action 변형, 창원·세종 추가) → `eminwon_collect` → `apply_review` → publish merge | `notice_sources.py`, pending_review | 0.5d/도시 ≈ 2.5d |
| **S8** | **APPLY daily 편입**: 현재 APPLY는 수동·1회성. `run_apply_daily`(수원 collect + eminwon 도시 + review `--publish` auto_publish만) 추가. needs_review는 사람 검수(체크리스트). **해외 IP 차단 시** 박스 cron 또는 국내 self-hosted runner로 분리 | `worker/…`, workflow | 1–1.5d |
| **S9** | **신규 어댑터**: 서울 공공서비스예약 API(`open_api`, 1d) · 인천 `citynet_gosi`(1d, 광주 재사용 가능) · 부산 occation(0.5–1d) · 대구 pssrp(0.5–1d) · 대전 NOTI_06(0.5–1d) · 울산(1d, 불안정) | 신규 모듈 + config | ≈5–6d |
| **S10** | 광주 APPLY: citynet 어댑터 + WAF 우회가 아닌 **정상 접근 경로** 확인(Actions/국내망에서 재시도, 자치구 eminwon 조사). 불가 시 `applyStatus=not_provided`로 정직 표기 | — | 조사 0.5d, 구현 미정 |
| **S11** | 도시별 BENEFIT (수원만 존재) — 본 확장 범위 밖 | — | 이월 |

합계(추정): ②까지 ≈ 6d, ③ APPLY 전체 ≈ 9–10d (검수 인력 시간 별도).

### 3-2. TourAPI 호출 예산 (일 1회 실행 기준 추정)

현재(경기 6시): `areaBasedList2` ≈ 42p · `searchFestival2` ≈ 9p · `detailCommon2` ≤ 40 → 총 ~90건/일.

확장 후(S2 전략 적용 시 추정):

| 오퍼레이션 | 산식 | 추정 |
|-----------|------|-----:|
| searchFestival2 | 전국 1회 (759건 / 100) | ~8 |
| areaBasedList2 | 경기 시도 스윕(현행 ~42) + 그 외 조회 타깃 ~40개 × 6타입 × 평균 1.3p (38/39는 1p 고정) | ~350–450 |
| detailCommon2 | 회당 한도 40 (신규 항목 우선 + 결과 캐시) | ≤40 |
| ldongCode2 | 코드 확인 시에만 (평시 0) | 0 |

- 공공데이터포털 KorService2 **개발계정 = 오퍼레이션별 1,000건/일**, 운영계정은 활용사례 등록 후 증설(권장 100,000). `areaBasedList2` ~450은 한도 안이지만 재시도·수동 실행·박스 테스트가 겹치면 여유가 얇다.
- **조치**: (1) 현 키의 계정 유형 확인 → 개발계정이면 **운영계정 신청**(활용사례: Loond 앱) — 사용자 작업. (2) 증분 동기화 `areaBasedSyncList2`(R12) 도입 시 호출 대폭 감소. (3) 서울처럼 큰 시도는 타입별 1~3p 상한.
- 문화포털: 도시당 2회 × 34 ≈ 70건/일 (별도 키, 한도 확인 필요).
- Actions 런타임: 현재 2~7분. 호출 간 0.1~0.15s sleep + curl 지연(~0.3~1s) 기준 +500건 ≈ +5~10분 → **예상 10~20분**, `timeout-minutes: 30`.

### 3-3. 리스크

| # | 리스크 | 영향 | 대응 |
|---|--------|------|------|
| 1 | TourAPI 일 한도(개발계정 1,000/오퍼레이션) | 수집 중단(resultCode 22) | 예산 카운터·이전 피드 유지·운영계정 신청 |
| 2 | 행정구역 변경(전남광주 통합·인천 구 개편·화성 구 신설)으로 코드/사이트 변동 | 오배정·0건 | `ldongCode2`로 코드 주기 점검(월 1회 스크립트), 부모+하위 코드 병행 조회, 0건 도시 경고 로그 |
| 3 | GitHub Actions(해외 IP)에서 지자체 게시판 차단/지연 | APPLY 수집 실패 | APPLY는 TourAPI와 분리 실행, 실패 soft-skip, 필요 시 국내 러너 |
| 4 | 광역시 자체 게시판 = 행정공고(입찰·위원·채용) 비중 큼 | 검수 부담·오게시 | 시민 모집 전용 보드 우선(부산 occation·대구 pssrp·서울 예약 API), 기존 블랙리스트 + review 엔진 |
| 5 | 서울 피드 크기 | 앱 로드 지연 | 타입별 캡, gzip, 자치구 칩은 클라이언트 필터 |
| 6 | Phase 2 도시의 APPLY 부재가 "빈 앱"처럼 보임 | 이탈 | APPLY 미제공 전용 상태 + 발견 탭 유도, 피커에 사전 고지 |
| 7 | 스토어 등록정보 | 반려 재발 | **변경 금지**(앱 내 라벨만). 앱 내 출처 고지(`service_disclaimer.dart`)는 수원 URL만 → 도시별 출처 표기는 데이터 `source`/`sourceUrl` 기준으로 표시(인앱) |
| 8 | 전남광주 통합으로 문화포털 시도명·TourAPI 주소 문자열 혼재(광주광역시/전남광주통합특별시) | 키워드 fallback 오작동 | 코드 우선 배정으로 회피 |
| 9 | 인천 구 개편 전후 데이터 혼재(구 코드 잔존 가능) | 일부 누락 | 인천은 시도 전체 조회(구 코드 무관) |

### 3-4. 이번 단계에서 하지 않은 것
- 코드 구현 없음(문서만). 서울 열린데이터광장 키 발급·TourAPI 운영계정 신청은 사용자 계정 작업이라 미실행.
- Phase 2 도시 공고 URL은 기존 `notice-source-types.md` 기록을 참고로만 표기(재검증 안 함).
- 광주 자치구 eminwon, 서울 자치구 eminwon 조사는 안 함(R25/R29).

---

## 4. 잔여 레지스터 연결
[`구현계획서.md`](구현계획서.md) §11 "지역 확장 계획 등록분 (2026-09-29)"에 R25–R30 추가. R12·R13은 본 계획의 S2/S1에서 함께 해소 예정(상태 변경은 구현 시).
