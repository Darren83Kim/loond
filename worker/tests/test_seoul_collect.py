"""Seoul public-reservation APPLY: parse, filter, merge retain."""

from __future__ import annotations

import json
import os
import tempfile
import unittest
from datetime import date
from pathlib import Path

from loond_worker import config
from loond_worker import seoul_collect as seoul
from loond_worker.publish_regions import build_region_feed, resolve_apply_status


EDU_PAGE = {
    "ListPublicReservationEducation": {
        "list_total_count": 3,
        "RESULT": {"CODE": "INFO-000", "MESSAGE": "정상 처리되었습니다"},
        "row": [
            {
                "SVCID": "S-EDU-OPEN",
                "MAXCLASSNM": "교육강좌",
                "MINCLASSNM": "역사",
                "SVCSTATNM": "접수중",
                "SVCNM": "2026년 하반기 &#39;우리 가족 경희궁 탐험대&#39; 교육생 모집",
                "PAYATNM": "무료",
                "PLACENM": "서울역사박물관",
                "USETGTINFO": "가족",
                "SVCURL": "https://yeyak.seoul.go.kr/web/reservation/selectReservView.do?rsv_svc_id=S-EDU-OPEN",
                "RCPTBGNDT": "2026-08-24 10:00:00.0",
                "RCPTENDDT": "2099-11-15 17:00:00.0",
                "AREANM": "종로구",
                "IMGURL": "https://yeyak.seoul.go.kr/img/edu.png",
            },
            {
                "SVCID": "S-EDU-CLOSED",
                "SVCSTATNM": "예약마감",
                "SVCNM": "끝난 강좌 모집",
                "SVCURL": "https://yeyak.seoul.go.kr/closed",
                "RCPTENDDT": "2099-01-01 00:00:00.0",
                "AREANM": "중구",
            },
            {
                "SVCID": "S-EDU-PARK",
                "MAXCLASSNM": "교육강좌",
                "SVCSTATNM": "접수중",
                "SVCNM": "공영주차장 이용 교육",
                "SVCURL": "https://yeyak.seoul.go.kr/park",
                "RCPTENDDT": "2099-05-01 00:00:00.0",
                "AREANM": "마포구",
            },
        ],
    }
}


def _row(**overrides: object) -> dict:
    base = {
        "svcId": "S1",
        "title": "영어회화 수강생 모집",
        "status": "접수중",
        "maxClass": "교육강좌",
        "minClass": "외국어",
        "place": "구민회관",
        "area": "마포구",
        "target": "성인",
        "pay": "무료",
        "url": "https://yeyak.seoul.go.kr/web/reservation/selectReservView.do?rsv_svc_id=S1",
        "image": "",
        "applicationStart": "2026-10-01",
        "applicationEnd": "2099-12-31",
        "service": "education",
        "phone": "",
    }
    base.update(overrides)
    return base


class ParseTests(unittest.TestCase):
    def test_parse_education_page_unescapes_and_reads_receipt_end(self) -> None:
        page = seoul.parse_body(EDU_PAGE, "ListPublicReservationEducation")
        self.assertEqual(page["code"], "INFO-000")
        self.assertEqual(page["total"], 3)
        rows = [
            seoul.normalize_api_row(raw, "education") for raw in page["rows"]
        ]
        self.assertIn("우리 가족 경희궁 탐험대", rows[0]["title"])
        self.assertNotIn("&#39;", rows[0]["title"])
        self.assertEqual(rows[0]["applicationEnd"], "2099-11-15")
        self.assertEqual(rows[0]["applicationStart"], "2026-08-24")
        kept = seoul.select_open(rows, today=date(2026, 10, 29))
        self.assertEqual([r["svcId"] for r in kept], ["S-EDU-OPEN"])

    def test_xml_sample_window_is_not_a_full_scan(self) -> None:
        raw = (
            "<RESULT><CODE>ERROR-335</CODE><MESSAGE><![CDATA["
            "샘플데이터(샘플키:sample) 는 한번에 최대 5건을 넘을 수 없습니다.\n"
            "요청시작위치와  요청종료위치 값은 1 ~ 5 사이만 가능합니다."
            "]]></MESSAGE></RESULT>"
        ).encode()
        payload = seoul.decode_response(raw)
        page = seoul.parse_body(payload, "ListPublicReservationEducation")
        self.assertTrue(seoul.is_sample_window(page["code"], page["message"]))
        self.assertEqual(seoul.max_rows_per_call(page["message"]), 5)

    def test_single_row_object_is_a_list(self) -> None:
        payload = {
            "ListPublicReservationCulture": {
                "list_total_count": 1,
                "RESULT": {"CODE": "INFO-000", "MESSAGE": "OK"},
                "row": {"SVCID": "ONLY", "SVCNM": "단독 행사", "SVCSTATNM": "접수중"},
            }
        }
        page = seoul.parse_body(payload, "ListPublicReservationCulture")
        self.assertEqual(len(page["rows"]), 1)
        self.assertEqual(page["rows"][0]["SVCID"], "ONLY")


class SelectTests(unittest.TestCase):
    def test_sport_court_dropped_program_kept(self) -> None:
        rows = [
            _row(
                svcId="COURT",
                service="sport",
                title="테니스장1(평일)-2026년 응봉공원",
                maxClass="체육시설",
                minClass="테니스장",
            ),
            _row(
                svcId="CLASS",
                service="sport",
                title="성인 수영 강습 모집",
                maxClass="체육시설",
                minClass="수영장",
            ),
        ]
        kept = seoul.select_open(rows, today=date(2026, 10, 29))
        self.assertEqual([r["svcId"] for r in kept], ["CLASS"])

    def test_institution_hall_dropped_recruitment_kept(self) -> None:
        rows = [
            _row(
                svcId="HALL",
                service="institution",
                title="서울역사박물관 야주개홀(강당) (27. 1월)",
                maxClass="공간시설",
                minClass="강당",
            ),
            _row(
                svcId="RECRUIT",
                service="institution",
                title="[월드컵공원] 유아숲체험원 참여기관 모집",
                maxClass="공간시설",
                minClass="광장",
            ),
        ]
        kept = seoul.select_open(rows, today=date(2026, 10, 29))
        self.assertEqual([r["svcId"] for r in kept], ["RECRUIT"])

    def test_jobs_bids_and_missing_or_past_end_dropped(self) -> None:
        rows = [
            _row(svcId="JOB", title="기간제근로자 채용 공고"),
            _row(svcId="BID", title="청소 용역 입찰 공고"),
            _row(svcId="NOEND", applicationEnd=None),
            _row(svcId="PAST", applicationEnd="2020-01-01"),
            _row(svcId="WAIT", status="접수대기"),
            _row(svcId="OK", title="시민 체험 프로그램 모집"),
        ]
        kept = seoul.select_open(rows, today=date(2026, 10, 29))
        self.assertEqual([r["svcId"] for r in kept], ["OK"])

    def test_medical_service_is_not_collected(self) -> None:
        names = {name for _sid, name, _mode in seoul.SERVICES}
        self.assertNotIn("ListPublicReservationMedical", names)
        self.assertIn("ListPublicReservationEducation", names)
        self.assertIn("ListPublicReservationCulture", names)


class OpportunityTests(unittest.TestCase):
    def test_opportunity_labels_city_reservation_not_tourapi(self) -> None:
        item = seoul.to_opportunity(
            _row(area="종로구"),
            now="2026-10-29T12:00:00+09:00",
        )
        self.assertEqual(item["id"], "seoul-yeyak-S1")
        self.assertEqual(item["region"], "seoul")
        self.assertEqual(item["type"], "APPLY")
        self.assertEqual(item["sourceName"], "서울시 공공서비스예약")
        self.assertNotIn("TourAPI", item["sourceName"])
        self.assertIn("TourAPI", item["summary"])
        self.assertEqual(item["applicationEnd"], "2099-12-31")
        self.assertEqual(item["applicationEndSource"], "api_rcpt_period")
        self.assertEqual(item["meta"]["source"], "seoul_reservation")
        self.assertEqual(item["meta"]["lDongSignguCd"], "110")
        self.assertTrue(item["sourceUrl"].startswith("https://yeyak.seoul.go.kr/"))


class MergeRetainTests(unittest.TestCase):
    def setUp(self) -> None:
        self._pub = config.PUBLISHED_JSON
        self._pending = config.PENDING_DIR
        self._sync = seoul.sync_published_outputs
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        root = Path(self.tmp.name)
        self.published = root / "opportunities.json"
        self.pending = root / "pending"
        self.pending.mkdir()
        config.PUBLISHED_JSON = self.published
        config.PENDING_DIR = self.pending
        seoul.sync_published_outputs = lambda **_k: {"region_ids": ["seoul", "busan"]}

    def tearDown(self) -> None:
        config.PUBLISHED_JSON = self._pub
        config.PENDING_DIR = self._pending
        seoul.sync_published_outputs = self._sync

    def test_merge_replaces_seoul_yeyak_and_keeps_other_apply(self) -> None:
        original = {
            "updatedAt": "2020-01-01T00:00:00+09:00",
            "regions": ["seoul", "busan"],
            "opportunities": [
                {
                    "id": "seoul-yeyak-OLD",
                    "region": "seoul",
                    "type": "APPLY",
                    "title": "old reservation",
                    "meta": {"source": "seoul_reservation"},
                },
                {
                    "id": "seoul-tour-apply-9",
                    "region": "seoul",
                    "type": "APPLY",
                    "title": "tour experience",
                    "meta": {"source": "tour_api_apply"},
                },
                {
                    "id": "seoul-tour-1",
                    "region": "seoul",
                    "type": "ENJOY",
                    "title": "festival",
                },
                {
                    "id": "busan-occation-3",
                    "region": "busan",
                    "type": "APPLY",
                    "title": "busan class",
                    "meta": {"source": "busan_occation"},
                },
            ],
        }
        self.published.write_text(
            json.dumps(original, ensure_ascii=False) + "\n",
            encoding="utf-8",
        )
        fresh = seoul.to_opportunity(_row(svcId="NEW", title="역사 강좌 수강생 모집"))
        stats = seoul.merge_publish([fresh])
        self.assertEqual(stats["published"], 1)
        self.assertEqual(stats["rejected"], 0)
        after = json.loads(self.published.read_text(encoding="utf-8"))
        ids = [o["id"] for o in after["opportunities"]]
        self.assertNotIn("seoul-yeyak-OLD", ids)
        self.assertIn("seoul-yeyak-NEW", ids)
        self.assertIn("seoul-tour-apply-9", ids)
        self.assertIn("seoul-tour-1", ids)
        self.assertIn("busan-occation-3", ids)
        self.assertNotEqual(after["updatedAt"], original["updatedAt"])

    def test_feed_apply_status_provided_only_when_seoul_rows_exist(self) -> None:
        empty = build_region_feed("seoul", [], updated_at="2026-10-29T00:00:00+09:00")
        self.assertEqual(empty["applyStatus"], "national")
        tour_only = build_region_feed(
            "seoul",
            [
                {
                    "id": "seoul-tour-apply-1",
                    "type": "APPLY",
                    "meta": {"source": "tour_api_apply"},
                }
            ],
            updated_at="2026-10-29T00:00:00+09:00",
        )
        self.assertEqual(tour_only["applyStatus"], "national")
        with_city = build_region_feed(
            "seoul",
            [
                {
                    "id": "seoul-yeyak-1",
                    "type": "APPLY",
                    "meta": {"source": "seoul_reservation"},
                }
            ],
            updated_at="2026-10-29T00:00:00+09:00",
        )
        self.assertEqual(with_city["applyStatus"], "provided")
        busan = resolve_apply_status(
            "busan",
            [{"id": "busan-occation-1", "type": "APPLY"}],
            "national",
        )
        self.assertEqual(busan, "national")


class RetainOnFailureTests(unittest.TestCase):
    def setUp(self) -> None:
        self._pub = config.PUBLISHED_JSON
        self._raw = config.RAW_DIR
        self._env = os.environ.get(seoul.ENV_KEY)
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        root = Path(self.tmp.name)
        self.published = root / "opportunities.json"
        self.raw = root / "raw"
        self.raw.mkdir()
        original = {
            "updatedAt": "2020-01-01T00:00:00+09:00",
            "opportunities": [
                {"id": "seoul-yeyak-KEEP", "type": "APPLY", "title": "keep"}
            ],
        }
        self.published.write_text(json.dumps(original) + "\n", encoding="utf-8")
        self._before = self.published.read_bytes()
        config.PUBLISHED_JSON = self.published
        config.RAW_DIR = self.raw

    def tearDown(self) -> None:
        config.PUBLISHED_JSON = self._pub
        config.RAW_DIR = self._raw
        if self._env is None:
            os.environ.pop(seoul.ENV_KEY, None)
        else:
            os.environ[seoul.ENV_KEY] = self._env

    def test_missing_key_does_not_touch_published(self) -> None:
        os.environ.pop(seoul.ENV_KEY, None)
        code = seoul.main([])
        self.assertEqual(code, 0)
        self.assertEqual(self.published.read_bytes(), self._before)

    def test_fetch_failure_does_not_replace_rows(self) -> None:
        os.environ[seoul.ENV_KEY] = "not-a-real-key"
        def boom(*_a, **_k):
            raise seoul.SeoulCollectError("timeout")

        orig = seoul.collect_open
        seoul.collect_open = boom
        try:
            code = seoul.main([])
        finally:
            seoul.collect_open = orig
        self.assertEqual(code, 1)
        self.assertEqual(self.published.read_bytes(), self._before)

    def test_sample_without_dry_run_does_not_publish(self) -> None:
        os.environ[seoul.ENV_KEY] = "ignored"
        code = seoul.main(["--sample"])
        self.assertEqual(code, 2)
        self.assertEqual(self.published.read_bytes(), self._before)

    def test_env_sample_dry_run_does_not_publish(self) -> None:
        os.environ[seoul.ENV_KEY] = seoul.SAMPLE_KEY
        orig = seoul.collect_sample_window
        seoul.collect_sample_window = lambda **_k: {
            "sampleWindowOnly": True,
            "services": [],
        }
        try:
            code = seoul.main(["--dry-run"])
        finally:
            seoul.collect_sample_window = orig
        self.assertEqual(code, 0)
        self.assertEqual(self.published.read_bytes(), self._before)


if __name__ == "__main__":
    unittest.main()
