# 서울시 공공서비스예약 APPLY (R35)

수집기: `worker/loond_worker/seoul_collect.py`  
지역 id: `seoul`  
표시 출처: `sourceName=서울시 공공서비스예약` (한국관광공사 TourAPI 체험 정보가 아님)

## 키

환경변수 이름: **`SEOUL_OPEN_API_KEY`**

이 저장소에는 서울 키가 없고, GitHub Actions secret도 아직 없다. 키는 커밋하지 않는다.

1. [서울 열린데이터광장](https://data.seoul.go.kr)에서 공공서비스예약(교육·문화행사·체육·시설대관) 인증키를 신청한다.
2. GitHub 저장소 → Settings → Secrets and variables → Actions → New repository secret
   - Name: `SEOUL_OPEN_API_KEY`
   - Value: 발급 키
3. secret이 없으면 일일 워크플로는 서울 단계를 건너뛰고, 이전에 게시된 `seoul-yeyak-*` 행을 그대로 둔다.

## 로컬 dry-run

```bash
cd worker
export SEOUL_OPEN_API_KEY='your-key'   # 커밋 금지
python -m loond_worker.seoul_collect --dry-run
```

실키는 한 호출에 최대 1000건. `--dry-run`은 `data/published`를 고치지 않는다.

문서에 있는 공개 샘플 키(`sample`)는 인덱스 **1~5만** 반환한다. 도시 전체 건수가 아니므로 게시하지 않는다.

```bash
cd worker
python -m loond_worker.seoul_collect --sample --dry-run
```

## 무엇을 게시하나

- 상태 `접수중`이고 `RCPTENDDT`(접수 종료)가 오늘(KST) 이후인 행만.
- 운영 종료일 `SVCOPNENDDT`는 신청 마감으로 쓰지 않는다. 마감이 없으면 게시하지 않는다.
- 교육·문화는 열린 행 전부. 체육·시설대관은 제목/분류에 모집·수강·강좌·강습·교실·체험·교육·프로그램·참가가 있을 때만.
- 진료 예약, 주차, 채용, 입찰, 용역은 제외.
- 조회가 실패하거나 목록이 끝까지 안 오면 기존 서울 예약 행을 지우지 않는다. TourAPI 행과 다른 지역 APPLY는 항상 유지한다.

## applyStatus

시청 예약 행이 피드에 없으면 카탈로그는 `national`이다 (부산과 같은 규칙).  
행이 게시되면 `publish_regions`가 서울 피드와 manifest의 `applyStatus`를 `provided`로 올린다.  
앱 피커 문구는 `app/lib/models/region.dart`의 `applyStatus`를 본다. 첫 게시 뒤에 그 값과 `region_codes.py`의 `apply_status`를 `provided`로 맞춘다.
