# 시 공고(APPLY) 소스 타입 초안

날짜: 2026-09-17  
목적: Deep 도시 APPLY를 시마다 스크래퍼 복제하지 않고, **유사 CMS끼리 타입 어댑터**로 묶기 위한 1차 택소노미.  
범위: 사용자가 언급한 거점·관광 도시 + 현재 레지스트리(경기 6) 표본. 조사 + **`eminwon_ofr` PoC** 반영.

## 타입 요약

| type id | 이름 | 식별 힌트 | 1차 판단 | PoC 우선 |
|---------|------|-----------|----------|----------|
| `eminwon_ofr` | 새올전자민원 고시공고(NTIS) | `eminwon.*.go.kr` + `/emwp/.../OfrAction.do` + `OfrNotAncmtEJB` | **가장 흔함** | **1순위 (PoC Done)** |
| `saeall_openworks` | 시청 포털 새올공고(Openworks) | `*/web/saeallOfr/BD_ofrList.do` | 수원 현재 파이프 | 2순위(이미 보유) |
| `portal_custom` | 광역/시 자체 공고 게시판 | `*.ulsan` / 시청 포털 path | 소수·개별 | 후순위 |
| `planweb_bbs` | planweb/일반 게시판 | `planweb/board/list.9is` | 전주 등 | 후순위 |
| `portal_bbs_openworks` | 포털 Openworks 일반 BBS | `BD_selectBbsList.do` / `q_bbsCode=` | 분야별 보드(고시 전체가 아님) | APPLY 본선 비추천 |
| `unknown` | 미분류 | — | 추가 조사 | — |

### 공통 운영 규칙 (타입과 무관)
- 목록 수집 ≠ publish. pending → **원문 CTA·모집성·마감** 검증 후 publish (수원 체크리스트 재사용).
- 채용·입찰·단순 송달/과태료 공고는 제품 블랙리스트로 제외.
- HWP 마감 자동추출은 여전히 Deferred(R2) — 타입 어댑터와 별개.

---

## 도시별 초안 표

신뢰도: **A**=목록 URL·스택 확인(박스 curl 또는 공개 인덱스), **B**=동일 eminwon 패턴으로 강하게 추정, **C**=포털만 확인·추가 클릭 필요.

목록 URL은 조사 시점(2026-09-17) 기준. `OfrAction` 공통 path:  
`/emwp/gov/mogaha/ntis/web/ofr/action/OfrAction.do`

| region_id | 표시명 | 권역 | 추정 type | 신뢰 | 목록/진입 URL (조사 시점) | 비고 |
|-----------|--------|------|-----------|------|---------------------------|------|
| suwon | 수원 | 경기 | `saeall_openworks` | A | https://www.suwon.go.kr/web/saeallOfr/BD_ofrList.do | **현행 Worker 소스** |
| yongin | 용인 | 경기 | `eminwon_ofr` | A | http://eminwon.yongin.go.kr/…/OfrAction.do | 포털에도 고시 메뉴; JSP 셸 존재 |
| seongnam | 성남 | 경기 | `eminwon_ofr` | A | http://eminwon.seongnam.go.kr/…/OfrAction.do | `selectOfrNotAncmtRegst` |
| goyang | 고양 | 경기 | `eminwon_ofr` | A | http://eminwon.goyang.go.kr/emwp/gov/mogaha/ntis/web/ofr/action/OfrAction.do?method=selectListOfrNotAncmt&methodnm=selectListOfrNotAncmtHomepage&jndinm=OfrNotAncmtEJB&context=NTIS&homepage_pbs_yn=Y&not_ancmt_se_code=01%2C04%2C05&ofr_pageSize=10&subCheck=Y | **PoC 검증** |
| bucheon | 부천 | 경기 | `eminwon_ofr` | A | http://eminwon.bucheon.go.kr/…/OfrAction.do | |
| hwaseong | 화성 | 경기 | `eminwon_ofr` | A | http://eminwon.hscity.go.kr/emwp/gov/mogaha/ntis/web/ofr/action/OfrAction.do?method=selectListOfrNotAncmt&methodnm=selectListOfrNotAncmtHomepage&jndinm=OfrNotAncmtEJB&context=NTIS&homepage_pbs_yn=Y&not_ancmt_se_code=01%2C04%2C05&ofr_pageSize=10&subCheck=Y | host=`hscity` (hwaseong DNS 없음) |
| cheongju | 청주 | 충북 | `eminwon_ofr` (+ 포털 래퍼) | A | https://eminwon.cheongju.go.kr/…/OfrAction.do | 시청 `selectEminwonNoticeView` 래퍼 있음 |
| chungju | 충주 | 충북 | `eminwon_ofr` | A | http://eminwon.chungju.go.kr/emwp/gov/mogaha/ntis/web/ofr/action/OfrAction.do?method=selectListOfrNotAncmt&methodnm=selectListOfrNotAncmtHomepage&jndinm=OfrNotAncmtEJB&context=NTIS&homepage_pbs_yn=Y&not_ancmt_se_code=01%2C04%2C05&ofr_pageSize=10&subCheck=Y | 박스 curl 목록 OK |
| jecheon | 제천 | 충북 | `portal_bbs` / `unknown` | C | https://jclib.jecheon.go.kr/www/selectBbsNttList.do?bbsNo=18&key=5233 | `eminwon.jecheon.go.kr` DNS 실패 |
| danyang | 단양 | 충북 | `eminwon_ofr` | B | http://eminwon.danyang.go.kr/…/OfrAction.do (→ https) | HTTPS 타임아웃 빈번 |
| jeonju | 전주 | 전북 | `planweb_bbs` | A | https://www.jeonju.go.kr/planweb/board/list.9is?… | 원스톱 민원 ≠ 고시 목록 |
| naju | 나주 | 전남 | `eminwon_ofr` | A | http://eminwon.naju.go.kr/emwp/gov/mogaha/ntis/web/ofr/action/OfrAction.do?method=selectListOfrNotAncmt&methodnm=selectListOfrNotAncmtHomepage&jndinm=OfrNotAncmtEJB&context=NTIS&homepage_pbs_yn=Y&not_ancmt_se_code=01%2C04%2C05&ofr_pageSize=10&subCheck=Y | |
| mokpo | 목포 | 전남 | `eminwon_ofr` | A | http://eminwon.mokpo.go.kr/emwp/gov/mogaha/ntis/web/ofr/action/OfrAction.do?method=selectListOfrNotAncmt&methodnm=selectListOfrNotAncmtHomepage&jndinm=OfrNotAncmtEJB&context=NTIS&homepage_pbs_yn=Y&not_ancmt_se_code=01%2C04%2C05&ofr_pageSize=10&subCheck=Y | 시청 포털 보드도 병행 |
| yeosu | 여수 | 전남 | `portal_custom` | A | https://www.yeosu.go.kr/www/govt/news/notify | eminwon 502; 시청 게시판 사용 |
| gunsan | 군산 | 전북 | `eminwon_ofr` | A | http://eminwon.gunsan.go.kr/emwp/gov/mogaha/ntis/web/ofr/action/OfrAction.do?method=selectListOfrNotAncmt&methodnm=selectListOfrNotAncmtHomepage&jndinm=OfrNotAncmtEJB&context=NTIS&homepage_pbs_yn=Y&not_ancmt_se_code=01%2C04%2C05&ofr_pageSize=10&subCheck=Y | |
| gyeongju | 경주 | 경북 | `eminwon_ofr` | A | http://eminwon.gyeongju.go.kr/emwp/gov/mogaha/ntis/web/ofr/action/OfrAction.do?method=selectListOfrNotAncmt&methodnm=selectListOfrNotAncmtHomepage&jndinm=OfrNotAncmtEJB&context=NTIS&homepage_pbs_yn=Y&not_ancmt_se_code=01%2C04%2C05&ofr_pageSize=10&subCheck=Y | |
| ulsan | 울산 | 광역 | `portal_custom` | A | https://www.ulsan.go.kr/u/rep/transfer/notice/list.ulsan | 시 본청 커스텀; 구는 eminwon 별도 |
| pohang | 포항 | 경북 | `eminwon_ofr` | B | http://eminwon.pohang.go.kr/emwp/jsp/ofr/OfrNotAncmtLSub.jsp?not_ancmt_se_code=01%2C04%2C05 | host OK; OfrAction 목록은 환경에 따라 빈 셸 |
| gimhae | 김해 | 경남 | `eminwon_ofr` | B | http://eminwon.gimhae.go.kr/emwp/jsp/ofr/OfrNotAncmtLSub.jsp?not_ancmt_se_code=01%2C04%2C05 | 시청 포털 보드도 있음 |
| tongyeong | 통영 | 경남 | `eminwon_ofr` | A | http://eminwon.tongyeong.go.kr/emwp/gov/mogaha/ntis/web/ofr/action/OfrAction.do?method=selectListOfrNotAncmt&methodnm=selectListOfrNotAncmtHomepage&jndinm=OfrNotAncmtEJB&context=NTIS&homepage_pbs_yn=Y&not_ancmt_se_code=01%2C04%2C05&ofr_pageSize=10&subCheck=Y | |
| geoje | 거제 | 경남 | `eminwon_ofr` | A | http://eminwon.geoje.go.kr/emwp/gov/mogaha/ntis/web/ofr/action/OfrAction.do?method=selectListOfrNotAncmt&methodnm=selectListOfrNotAncmtHomepage&jndinm=OfrNotAncmtEJB&context=NTIS&homepage_pbs_yn=Y&not_ancmt_se_code=01%2C04%2C05&ofr_pageSize=10&subCheck=Y | |
| andong | 안동 | 경북 | `portal_custom` | A | https://www.andong.go.kr/portal/saeol/gosi/list.do?mId=0401020000 | 시청 포털 새올 래퍼; eminwon DNS 실패 |
| gangneung | 강릉 | 강원 | `eminwon_ofr` | A | http://eminwon.gangneung.go.kr/emwp/gov/mogaha/ntis/web/ofr/action/OfrAction.do?method=selectListOfrNotAncmt&methodnm=selectListOfrNotAncmtHomepage&jndinm=OfrNotAncmtEJB&context=NTIS&homepage_pbs_yn=Y&not_ancmt_se_code=01%2C04%2C05&ofr_pageSize=10&subCheck=Y | |
| wonju | 원주 | 강원 | `eminwon_ofr` | B | http://eminwon.wonju.go.kr/emwp/jsp/ofr/OfrNotAncmtLSub.jsp?not_ancmt_se_code=01%2C04%2C05 | host OK; 목록 파라미터 재확인 |
| sokcho | 속초 | 강원 | `unknown` | C | — | `eminwon.sokcho.go.kr` 응답은 있으나 고시 목록 비어 있음 |
| yangyang | 양양 | 강원 | `eminwon_ofr` | A | http://eminwon.yangyang.go.kr/emwp/gov/mogaha/ntis/web/ofr/action/OfrAction.do?method=selectListOfrNotAncmt&methodnm=selectListOfrNotAncmtHomepage&jndinm=OfrNotAncmtEJB&context=NTIS&homepage_pbs_yn=Y&not_ancmt_se_code=01%2C04%2C05&ofr_pageSize=10&subCheck=Y | 군 |
| gapyeong | 가평 | 경기 | `eminwon_ofr` | A | http://eminwon.gp.go.kr/emwp/gov/mogaha/ntis/web/ofr/action/OfrAction.do?method=selectListOfrNotAncmt&methodnm=selectListOfrNotAncmtHomepage&jndinm=OfrNotAncmtEJB&context=NTIS&homepage_pbs_yn=Y&not_ancmt_se_code=01%2C04%2C05&ofr_pageSize=10&subCheck=Y | ※ 강원이 아님 · host=`gp` |
| mungyeong | 문경 | 경북 | `eminwon_ofr` | B | http://eminwon.gbmg.go.kr/emwp/jsp/ofr/OfrNotAncmtLSub.jsp?not_ancmt_se_code=01%2C04%2C05 | ※ 충청이 아님 · host=`gbmg` |

> 표본에서 **확인된 다수결은 `eminwon_ofr`**. 수원만 `saeall_openworks`로 이미 구현됨. 여수·안동은 시청 포털 커스텀/래퍼.

---

## 타입별 어댑터 스케치

### `eminwon_ofr` (1순위 PoC)
- **host**: `eminwon.{slug}.go.kr` (예외: 화성 `hscity`, 가평 `gp`, 문경 `gbmg`)
- **list**: `OfrAction.do` + `jndinm=OfrNotAncmtEJB` (일부는 `OfrNotAncmtLSub.jsp`)
- **method 변형** (시마다 다름 → config):
  - `selectListOfrNotAncmt` / `selectListOfrNotAncmtHomepage`
  - `selectOfrNotAncmt` / `selectOfrNotAncmtRegst`
- **city config**: `worker/loond_worker/notice_sources.py`
- **collector**: `python -m loond_worker.eminwon_collect --region goyang --pages 2`
- **기대 ROI**: 경기·충북 등 Deep-B 후보 상당수를 **한 어댑터 + config** 로 커버

### `saeall_openworks` (현행)
- 수원 `collect.py` 유지
- 동일 path를 쓰는 다른 시가 있으면 config만 추가

### `portal_custom` / `planweb_bbs`
- 도시 수 적을 때 개별 어댑터
- 울산·전주·여수·안동이 대표 표본

---

## PoC 상태 (`eminwon_ofr`)

| 항목 | 내용 |
|------|------|
| 코드 | `worker/loond_worker/eminwon_collect.py` + `notice_sources.py` |
| 검증 도시 | **goyang** (2026-09-17) |
| 산출 | `data/raw/eminwon_{region}_list.json`, `data/pending_review/eminwon_{region}_pending.json` |
| publish | **자동 merge 안 함** (pending_review만) |
| TLS | https 시도 후 실패 시 http (수원 collect와 동일 계열) |
| 실행 | 아래 How to run |

### How to run

```bash
cd worker
python3 -m venv .venv && .venv/bin/pip install -r requirements.txt
.venv/bin/python -m loond_worker.eminwon_collect --region goyang --pages 2 --details 3
# 설정만 확인
.venv/bin/python -m loond_worker.eminwon_collect --list-regions
```

옵션: `--pages N`, `--details N`(상세 0이면 목록만), `--delay SEC`.

HTML이 JS 의존/빈 셸이면 meta.`empty_hint`에 남기고, config의 method/methodnm·`list_variant=jsp` 를 바꿔 재시도.

---

## Deep 정의와의 연결

| 목표 | 타입 전략 |
|------|-----------|
| 수원 수준 APPLY를 여러 시에 | **`eminwon_ofr` PoC → city config 양산** 이 본체 |
| TourAPI·문화만 두껍게 | 공고 타입 불필요 (이미 multi-city) |
| 예약 체험 큐레이션 | 스크래퍼 밖 (별도 트랙) |

권장 다음 스텝:
1. verified 도시(고양·화성·충주·나주·목포·군산 등) config 스모크
2. pending → 수원과 동일한 필터/마감 검증 파이프 연결
3. 여수·안동 `portal_custom` 어댑터 여부 결정

---

## 한계 (정직하게)
- 같은 `eminwon_ofr`여도 method명·세션·캡차·첨부 정책이 시마다 조금씩 다름 → **100% 무설정 복제 불가**, config + 소수 분기.
- 목록 파싱 성공 ≠ 수원 품질. publish 검증 인력/반자동이 Deep 속도를 가름.
- 광역시 구 단위 eminwon(울산 남구 등)은 시 본청 보드와 분리될 수 있음.
- 일부 host는 HTTP만 안정 / HTTPS 타임아웃 (박스·CI에서 http fallback 필수).
