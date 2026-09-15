# EPIC 1 PoC 결과 — 수원 APPLY 파이프라인

> 작성: 2026-09-14 · 갱신(정리): 2026-09-14  
> 기획: `docs/기획서.md` · 계획: `docs/구현계획서.md` · 스파이크: `docs/참고.md`  
> 환경(당시 Windows 기록): `E:\DsDevelop_Loond` · Python 3.12 · Windows  
> **현재 기준 경로:** GitHub `Darren83Kim/loond` · 체크아웃 `/home/box/projects/loond` (그록컴)

---

## TL;DR

| 질문 | 답 |
|------|-----|
| 파이프라인이 끝까지 도나? | **돈다.** 수집 → 필터 → pending → published |
| DoD | **전부 PASS** |
| published 실데이터 | **3건** (수강 `course_local`, 본문에서 진성 마감일) |
| 전자동으로 올려도 되나? | **아니다.** HWP·노이즈 → **자동 후보 + 사람 검증** 유지 |
| 다음 | EPIC 2(JSON 계약) → EPIC 3(Flutter가 이 JSON 읽기) |

한 줄: **“앱에 넣을 APPLY JSON을 만들 수 있음”을 증명했다. 다만 마감일·적합도는 사람이 한 번 봐야 한다.**

---

## 1. DoD

| 조건 | 결과 |
|------|------|
| 후보 자동 추출 | PASS — 90일 **608건** → 후보 **72건** |
| 화이트/블랙리스트 | PASS — rejected **536건** |
| 5~10건 마감 확인 | PASS — 상세 10건, 본문 마감 **7/10** |
| published ≥ 1 | PASS — **3건** |
| 마감 없으면 published 금지 | PASS |
| HWP·운영 비중 기록 | PASS — 아래 §3 |

---

## 2. 숫자

| 단계 | 건수 |
|------|------|
| 목록 스크랩 | 650 |
| 90일 창 (게재일 ≥ 2026-06-16) | **608** |
| 후보 (whitelist) | **72** |
| rejected | 536 |
| pending_review 큐 | 72 |
| **published** | **3** |

```bash
# 현재: /home/box/projects/loond (또는 클론 루트)
cd worker
python -m loond_worker.run_poc
```

> 참고: 최초 PoC는 Windows `E:\DsDevelop_Loond\worker`에서 실행됨(역사 기록).

---

## 3. 마감일 · HWP — 운영에 남길 규칙

### 무엇을 배웠나
- **게재기간** 종료일 ≠ 신청 마감 → published에 쓰면 안 됨. (pending에 proxy 표기만 가능)
- 상세 HTML **본문**에 `모집기간`/`접수기간`이 있으면 종료일을 뽑을 수 있음 (이번 샘플 **7/10**).
- 그래도 첨부 **HWP/HWPX가 9/10** → 정확·완전한 일정은 여전히 파일 쪽인 경우가 많음.

### 확정 운영 규칙 (재확인)
1. `applicationEnd` **null이면 published 금지** → `pending_review`만.
2. published는 **본문 추출 또는 사람이 HWP 보고 기입**한 마감만.
3. 검증은 기획서 체크리스트 (적합·신청가능·마감·원문 URL·요약 일치).

### 스파이크와의 차이
- 스파이크: 목록/게재기간 위주 → 진성 마감 ≈0%처럼 보임.
- PoC: **본문 파싱 추가** → 샘플 일부 성공.  
→ “완전 불가”가 아니라 **“일부 자동 + 다수는 검증”**.

---

## 4. published 3건 (앱에 넣을 첫 실데이터)

| id | 제목 (요약) | category | 마감 | 출처 |
|----|-------------|----------|------|------|
| `suwon-ofr-156580` | 조원2동 가을 힐링원예 수강 | course_local | 2026-09-23 | 본문 모집기간 (HWP 없음) |
| `suwon-ofr-156622` | 평동 4분기 수강 | course_local | 2026-09-30 | 본문 접수기간 (+HWP) |
| `suwon-ofr-156538` | 파장동 10월 수강 | course_local | 2026-09-30 | 본문 접수기간 (+HWP) |

파일: `data/published/opportunities.json`

**제품 함의:** 지금 수원 NOW APPLY는 **주민자치 수강**이 먼저 채워진다. 관광/체류형 APPLY는 공고가 올라올 때만 등장 (화이트리스트는 이미 열어 둠). APPLY가 적어도 ENJOY와 **섹션을 섞지 않음** (기획 확정).

---

## 5. 산출물

| 구분 | 경로 |
|------|------|
| Worker | `worker/` · `python -m loond_worker.run_poc` |
| README | `worker/README.md` |
| raw | `data/raw/` (`notices_window`, `notices_filtered`, `detail_sample`, `poc_summary`) |
| pending | `data/pending_review/pending_review.{json,csv}` |
| published | `data/published/opportunities.json` |

---

## 6. 아직 안 한 것 / 다음 에픽으로

| 항목 | 어디로 |
|------|--------|
| 경계 노이즈 추가 차단 (업소지정·B2B성 등) | Worker 규칙 튜닝 (EPIC 5 전에도 가능) |
| HWP 본문 자동 파서 | **후순위** (PoC 범위 밖) |
| JSON 스키마·부가 필드 정리 (`applicationEndSource`, `has_hwp`…) | **EPIC 2** |
| Flutter가 published JSON 로드 | **EPIC 3** |
| TourAPI ENJOY/DISCOVER | **EPIC 4** |
| Actions 일 1회 | **EPIC 5** |

---

## 7. 게이트

- [x] EPIC 1 DoD  
- [ ] EPIC 2: Worker↔앱 **동일 JSON 계약**  
- [ ] EPIC 3: 메인 APPLY/ENJOY 분리 + 이 published(또는 샘플)로 원문 CTA  

**결론:** EPIC 1은 여기서 닫아도 된다. 데이터 증명 완료.
