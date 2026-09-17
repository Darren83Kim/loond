# 문화포털 ENJOY 스파이크 (R11)

날짜: 2026-09-17

## API
- 한국문화정보원 **한눈에보는문화정보조회서비스** (data.go.kr `B553457`)
- 사용 엔드포인트 (구 `nopenapi/.../period` **폐기**):
  - `http://apis.data.go.kr/B553457/cultureinfo/period2`
  - `http://apis.data.go.kr/B553457/cultureinfo/area2`
- Secret: `CULTURE_API_SERVICE_KEY` (Decoding 키)
- 이 환경에서 `https://apis.data.go.kr` TLS EOF → **HTTP + curl HTTP/1.1**

## 수원 수집
1. `period2` + `keyword=수원`, 기간 오늘~+120일
2. `area2` + `sido=경기` + `gugun=수원시` (타 시군 혼입 가능 → 후필터)
3. title/place/sigungu에 「수원」포함만 유지, 종료일 지난 건 제외

## 매핑
- id: `suwon-culture-{seq}`
- type: `ENJOY`
- sourceName: `문화포털(한눈에보는문화정보)`
- sourceUrl: `https://www.culture.go.kr/oneclt/oneCltView.do?seq={seq}`
- meta.source: `culture_portal`

## 결과
- 문화포털 ENJOY **17건**을 published/app assets에 병합 (TourAPI ENJOY와 병존)
- Worker: `worker/loond_worker/culture_collect.py`
