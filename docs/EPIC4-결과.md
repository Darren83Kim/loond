# EPIC 4 결과 — ENJOY / DISCOVER 수집

> 작성: 2026-09-15 · 작업 원본: `/home/box/projects/loond` · GitHub `Darren83Kim/loond`

## TL;DR

| 질문 | 답 |
|------|-----|
| TourAPI → published → 앱? | **됨** (앱은 JSON만 읽음, TourAPI 직접 호출 없음) |
| 제품 DoD | **PASS** (웹 미리보기 확인) |
| published | APPLY **3** · ENJOY **15** · DISCOVER **102** (총 120) |
| API | **KorService2** (KorService1은 NO_OPENAPI_SERVICE_ERROR) |
| 다음 | EPIC 5 (Actions 일 1회) · 잔여 §11 R11–R14 |

## DoD

| 조건 | 결과 |
|------|------|
| 수원 ENJOY가 JSON에 들어감 | PASS |
| 앱 NOW/ANYTIME 표시 | PASS (웹 `localhost:8080`) |
| 수원 지역코드 상수 | PARTIAL — `STRATEGY=area_filter` (areaCode=31 + 「수원」); sigungu `VERIFY_PENDING` |
| published→asset 동기화 | PASS — `scripts/sync_published_assets.*` |

## 기술 메모

- 그록컴 → `apis.data.go.kr` **HTTPS TLS 실패** → 수집은 **로컬 Windows PC**에서 수행 후 결과 병합.
- `areaCode2`는 키 스코프상 resultCode 30 가능; `searchFestival2` / `areaBasedList2` 사용.
- 개발계정 **1일 1,000회** → Worker만 호출, 앱 미호출 구조 유지 (EPIC 5에서 스케줄화).

## 잔여 → §11

R11 문화포털(4-2), R12 TourAPI 증분 동기화, R13 sigungu/ldong 최종 확정, R14 Actions에 sync step 연결.

상세 진행 로그: `docs/EPIC4-진행.md`
