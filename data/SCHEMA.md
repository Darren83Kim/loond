# 로온드 정적 데이터 계약 (EPIC 2)

> Worker 출력과 Flutter 파서가 **동일한 계약**을 쓴다.  
> 실데이터: `data/published/opportunities.json`  
> 예시: `data/published/opportunities.example.json`

---

## 1. 파일

| 경로 | 용도 |
|------|------|
| `data/published/opportunities.json` | Phase A 앱이 읽는 published 피드 |
| `data/published/opportunities.example.json` | 스키마 예시 |
| `data/pending_review/` | 검증 큐 (앱 비노출) |

---

## 2. 루트 객체

```json
{
  "schemaVersion": 1,
  "region": "suwon",
  "regionLabel": "수원",
  "updatedAt": "2026-09-14T18:00:00+09:00",
  "opportunities": [ /* Opportunity[] */ ]
}
```

| 필드 | 필수 | 설명 |
|------|------|------|
| schemaVersion | ✅ | 지금 `1`. 깨는 변경 시 +1 |
| region | ✅ | `region_id` (`suwon`) |
| regionLabel | ✅ | 표시명 |
| updatedAt | ✅ | ISO-8601 (KST 권장) |
| opportunities | ✅ | 배열. **type으로 구분** (별도 enjoy.json 없음) |

앱 필터:
- NOW APPLY = `type=="APPLY" && status=="published"`
- NOW ENJOY = `type=="ENJOY" && status=="published"`
- ANYTIME = `type=="DISCOVER" && status=="published"`
- BENEFIT = MVP에서 본문 없음 (CTA만) → 배열에 없어도 됨

빈 섹션: 해당 type이 0건이면 UI Empty (기획서).

---

## 3. Opportunity (앱 필수 필드)

| 필드 | 타입 | 필수 | 비고 |
|------|------|------|------|
| id | string | ✅ | 예 `suwon-ofr-156580` |
| region | string | ✅ | `suwon` |
| title | string | ✅ | |
| type | string | ✅ | `APPLY` \| `ENJOY` \| `DISCOVER` \| `BENEFIT` |
| category | string | ✅ | APPLY는 화이트리스트 코드 |
| summary | string | ✅ | |
| description | string\|null | | |
| startDate / endDate | `YYYY-MM-DD`\|null | | ENJOY 등 |
| applicationStart / applicationEnd | `YYYY-MM-DD`\|null | APPLY는 **End 필수** | null이면 published 금지 |
| target, benefit, location, organization, thumbnail | string\|null | | |
| sourceName | string | ✅ | |
| sourceUrl | string | ✅ | https 권장 |
| sourcePublishedAt | string | ✅ | 날짜 또는 ISO |
| status | string | ✅ | 앱 피드에는 `published`만 |
| opportunityScore | number | ✅ | MVP는 0이어도 됨 (미사용) |
| createdAt / updatedAt | ISO-8601 | ✅ | |

### meta (선택 · 앱은 무시 가능)

파이프라인 감사 필드. Flutter는 없어도 동작해야 함.

```json
"meta": {
  "applicationEndSource": "body:모집기간",
  "hasHwp": true,
  "notAncmtMgtNo": "156580",
  "noticeNo": "...",
  "publishPeriod": "...",
  "pipelineNotes": "..."
}
```

---

## 4. 앱 로드 경로 (Phase A)

| 단계 | 방법 |
|------|------|
| 개발 | Flutter `assets/data/opportunities.json`에 복사 **또는** 로컬 파일/HTTP |
| 이후 | 정적 호스팅 URL + **캐시 버스팅** `...?v={updatedAt 또는 run id}` |
| 웹 | CORS 허용 필요 |

pending_review는 앱에 넣지 않는다.

---

## 5. 검증 규칙 (발행)

- `status=="published"` 이고 APPLY이면 `applicationEnd != null`
- `sourceUrl`, `sourceName`, `sourcePublishedAt` 비어 있으면 안 됨
- 날짜는 `YYYY-MM-DD` (시간 필요 시 ISO)

---

## 6. schemaVersion

- `1` = EPIC 2 확정안 (meta 선택, opportunities 단일 배열)
- 필드 삭제/의미 변경 시 major+1, 앱 파서 분기
