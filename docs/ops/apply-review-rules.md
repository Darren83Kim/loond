# APPLY pending → publish 규칙 엔진 (PoC)

날짜: 2026-09-17  
목적: eminwon/수원 pending을 **전부 조용히 publish하지 않고**, 명시 규칙으로  
`reject` / `needs_review` / `auto_publish` 세 갈래로 나눈다.  
코드: `worker/loond_worker/apply_rules.py` · CLI `python -m loond_worker.apply_review`

## North Star

- 상세 → **공식 원문 보기** CTR. 가짜·추정 마감으로 카드를 채우지 않는다.
- `applicationEnd` 없거나 `applicationEndSource`에 `publish_period_proxy`만 있으면 **auto_publish 금지**.
- 1차 고양 eminwon 배치: 대부분 reject/needs_review 예상 (마감·시민 모집 신호 부족).

## 결정 표

| 결과 | 조건 (요약) |
|------|-------------|
| **reject** | `EMINWON_ADMIN_BLACKLIST` / `BLACKLIST_PATTERNS` / `STRONG_NEGATIVE` / `RESULT_CLOSED_PATTERNS` 히트, 또는 키워드 후보 아님 (`not_keyword_candidate`) |
| **needs_review** | 시민 APPLY처럼 보임(화이트리스트 카테고리 **또는** 강한 긍정 키워드)이나 `applicationEnd` 없음 · proxy 마감 · 만료 · `sourceUrl` 불량 · 제목/카테고리 모호 |
| **auto_publish** | **전부** 충족: 화이트리스트 `classify_category` · 필터 후보(title+summary scoring) · `sourceUrl` http(s) · `applicationEnd` YYYY-MM-DD 이고 source에 `publish_period_proxy` 없음 · 마감 ≥ 오늘(KST) · 결과/종료 문구 아님 |

재사용: `filter.score_title` / `apply_filters` 패턴, `classify_category` / `is_whitelist`.

## eminwon 행정 블랙리스트 (한곳)

`worker/loond_worker/config.py` → **`EMINWON_ADMIN_BLACKLIST`**  
(Suwon `BLACKLIST_PATTERNS`와 **분리** — 수원 collect→filter 동작 유지)

등록 공고, 직권말소, 영업신고, 과태료 처분, 건설업 등록, 전문건설업, 공시송달, 송달, 인가 고시, 지형도면, 도시관리계획, 지적재조사, 이동제한, 행정명령

## CLI

```bash
cd worker
# 기본: 분류만 (publish 안 함) — 안전
.venv/bin/python -m loond_worker.apply_review \
  --in ../data/pending_review/eminwon_goyang_pending.json

# auto_publish만 published에 upsert + app asset sync
.venv/bin/python -m loond_worker.apply_review \
  --in ../data/pending_review/eminwon_goyang_pending.json --publish
```

### 입력
- `{meta, items}` 또는 list, 또는 `{opportunities}`
- Suwon-style 필드: `title`, `summary`/`description`, `sourceUrl`, `applicationEnd`, `applicationEndSource`, `region`

### 출력 (`data/pending_review/`)
- `{prefix}_rejected.json`
- `{prefix}_needs_review.json`
- `{prefix}_auto_publish.json`

각 item에 `reviewDecision`, `reviewReasons[]`, `category`, filter 점수 필드 부여.

`--publish`: **auto_publish만** `data/published/opportunities.json`에 id upsert (`status=published`). TourAPI/culture/curated·타 지역 유지. auto_publish 0건이면 no-op 메시지. 기본은 `--publish` 없음.

## 사람 경로 vs 자동화

| 경로 | 언제 |
|------|------|
| 자동화 (`apply_review`) | 규칙이 명확히 reject / (드문) auto_publish |
| 사람 체크리스트 | `needs_review` → [`pending-publish-checklist.md`](./pending-publish-checklist.md) |

관련: [`notice-source-types.md`](./notice-source-types.md) (수집), 본 문서 (검토 규칙).
