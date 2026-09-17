# pending_review → published 검증 체크리스트

> EPIC 5-4 / §11 R15 · 약 1쪽 · 기획서 §6 검증 항목과 동일 기준  
> 산출물: `data/pending_review/pending_review.json` (· `.csv`) → `data/published/opportunities.json`

운영자가 **같은 규칙**으로 승인한다. 맘대로 큐레이션이 아니라 데이터 처리.

## 승격 전 (건별)

- [ ] **마감일** `applicationEnd`가 있다 (YYYY-MM-DD). **없으면 published 금지** → pending만.
- [ ] 게재기간 종료일만으로 채우지 않았다 (`publish_period_proxy`는 published 불가).
- [ ] **화이트리스트 APPLY**인가? (`course_local` / `support_apply` / `experience_apply` / `tourism_stay` / `youth_program` / `contest_apply`)
- [ ] **채용·기간제·입찰·용역·B2B·공람·선정결과** 등이 아닌가? (블랙리스트 → rejected)
- [ ] 지금 **신청·접수 가능**한가? (결과·종료 공고 아님)
- [ ] **`sourceUrl`** 이 공식 원문으로 열리는가? (`sourceName`·`sourcePublishedAt` 필수)
- [ ] 제목·요약이 원문과 어긋나지 않는가?
- [ ] **HWP/HWPX**: 첨부가 있으면 원문에서 일정 확인. 워커는 존재 여부만 기록 — 마감은 본문 추출 또는 **사람이 HWP 보고 기입**.

## 승격 후 (배치)

1. pending에서 승인 건을 `status=published`로 `data/published/opportunities.json`에 넣는다 (거절은 `rejected`).
2. 에셋 동기화:

```bash
# 저장소 루트 (/home/box/projects/loond 또는 클론 루트)
python3 scripts/sync_published_assets.py
# 또는: ./scripts/sync_published_assets.sh
```

3. 커밋·푸시(또는 daily Actions가 TourAPI 쪽에서 sync). APPLY 수동 승격 후에도 sync를 빼먹지 않는다.
4. 앱에서 APPLY 카드·D-Day·원문 CTA가 보이는지 한 번 확인.

## 빠른 참조

| 경로 | 용도 |
|------|------|
| `data/pending_review/` | 검증 큐 |
| `data/published/opportunities.json` | 앱 노출본 |
| `app/assets/data/opportunities.json` | sync 대상 에셋 |
| `docs/기획서.md` §5–§6 | 화이트리스트·전체 체크 원문 |
| `worker/README.md` | 워커 실행·규칙 요약 |

TourAPI ENJOY/DISCOVER는 일일 Actions가 published에 병합한다. **시민 APPLY**만 이 체크리스트로 사람 승격한다.

## 자동화 경로 (규칙 엔진)

전량 수동이 아니라, 규칙으로 1차 분기할 수 있다.

```bash
cd worker
.venv/bin/python -m loond_worker.apply_review \
  --in ../data/pending_review/eminwon_goyang_pending.json
# 안전: 기본은 publish 안 함. auto_publish만 merge하려면 --publish
```

| 결과 | 다음 행동 |
|------|-----------|
| `reject` | 폐기 (블랙리스트·행정공고·비후보) |
| `needs_review` | **이 체크리스트**로 사람 검증 후 승격 |
| `auto_publish` | 규칙 전부 충족 시에만 `--publish`로 published merge |

상세 결정표·행정 블랙리스트: [`apply-review-rules.md`](./apply-review-rules.md)

> 1차 고양 eminwon 배치는 대부분 reject/needs_review 예상 (마감일·시민 모집 신호 부족). North Star: 가짜 마감으로 카드 채우지 않기.

