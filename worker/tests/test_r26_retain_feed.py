"""R26: TourAPI fetch/quota failures must not replace the published feed."""

from __future__ import annotations

import json
import os
import tempfile
import unittest
from pathlib import Path

from loond_worker import config
from loond_worker import run_tour_daily as tour
from loond_worker import tour_apply_collect as tac


QUOTA_BODY = {
    "response": {
        "header": {
            "resultCode": "22",
            "resultMsg": "LIMITED_NUMBER_OF_SERVICE_REQUESTS_EXCEEDS_ERROR",
        }
    }
}


def _ok_page() -> dict:
    return {
        "response": {
            "header": {"resultCode": "0000", "resultMsg": "OK"},
            "body": {
                "totalCount": 250,
                "items": {"item": [{"contentid": "1", "title": "fest"}]},
            },
        }
    }


class R26ClassifyTests(unittest.TestCase):
    def test_result_code_22_is_quota(self) -> None:
        problem = tour.classify_fetch_payload(QUOTA_BODY, endpoint="searchFestival2")
        self.assertIsNotNone(problem)
        assert problem is not None
        self.assertEqual(problem.kind, "quota")
        self.assertIn("22", problem.code)

    def test_padded_0022_is_quota(self) -> None:
        payload = {
            "response": {
                "header": {"resultCode": "0022", "resultMsg": "LIMITED_NUMBER"}
            }
        }
        problem = tour.classify_fetch_payload(payload, endpoint="areaBasedList2")
        self.assertIsNotNone(problem)
        assert problem is not None
        self.assertEqual(problem.kind, "quota")

    def test_openapi_gateway_22_is_quota(self) -> None:
        payload = {
            "OpenAPI_ServiceResponse": {
                "cmmMsgHeader": {
                    "returnReasonCode": "22",
                    "returnAuthMsg": "LIMITED_NUMBER_OF_SERVICE_REQUESTS_EXCEEDS_ERROR",
                }
            }
        }
        problem = tour.classify_fetch_payload(payload, endpoint="searchKeyword2")
        self.assertIsNotNone(problem)
        assert problem is not None
        self.assertEqual(problem.kind, "quota")

    def test_korean_quota_message_is_quota(self) -> None:
        payload = {
            "response": {
                "header": {
                    "resultCode": "99",
                    "resultMsg": "서비스 요청제한횟수를 초과했습니다.",
                }
            }
        }
        problem = tour.classify_fetch_payload(payload, endpoint="searchFestival2")
        self.assertIsNotNone(problem)
        assert problem is not None
        self.assertEqual(problem.kind, "quota")

    def test_success_and_nodata_are_not_blocking(self) -> None:
        ok = tour.classify_fetch_payload(_ok_page(), endpoint="searchFestival2")
        nodata = tour.classify_fetch_payload(
            {
                "response": {
                    "header": {"resultCode": "03", "resultMsg": "NODATA_ERROR"},
                    "body": {"items": "", "totalCount": 0},
                }
            },
            endpoint="areaBasedList2",
        )
        self.assertIsNone(ok)
        self.assertIsNone(nodata)

    def test_transport_http_and_auth_are_blocking(self) -> None:
        transport = tour.classify_fetch_payload(
            {"_error": "URLError", "_msg": "timed out"}, endpoint="searchFestival2"
        )
        http = tour.classify_fetch_payload(
            {"_http_error": 500, "_body": "nope"}, endpoint="searchFestival2"
        )
        auth = tour.classify_fetch_payload(
            {
                "response": {
                    "header": {
                        "resultCode": "30",
                        "resultMsg": "SERVICE_KEY_IS_NOT_REGISTERED_ERROR",
                    }
                }
            },
            endpoint="searchFestival2",
        )
        budget = tour.classify_fetch_payload(
            {"_error": "BudgetExceeded", "_msg": "API_BUDGET=900"},
            endpoint="areaBasedList2",
        )
        assert transport and http and auth and budget
        self.assertEqual(transport.kind, "transport")
        self.assertEqual(http.kind, "http")
        self.assertEqual(auth.kind, "api")
        self.assertEqual(budget.kind, "budget")

    def test_keep_previous_on_quota_even_with_rows(self) -> None:
        problem = tour.classify_fetch_payload(QUOTA_BODY, endpoint="searchFestival2")
        assert problem is not None
        reason = tour.should_keep_previous_tour_feed(
            [problem], enjoy_assigned=40, discover_assigned=10
        )
        self.assertIsNotNone(reason)
        assert reason is not None
        self.assertIn("resultCode 22", reason)

    def test_keep_previous_on_empty_success(self) -> None:
        reason = tour.should_keep_previous_tour_feed(
            [], enjoy_assigned=0, discover_assigned=0
        )
        self.assertIsNotNone(reason)
        assert reason is not None
        self.assertIn("refusing empty invent", reason)

    def test_publish_when_sweep_succeeded(self) -> None:
        self.assertIsNone(
            tour.should_keep_previous_tour_feed(
                [], enjoy_assigned=3, discover_assigned=0
            )
        )


class R26FetchTests(unittest.TestCase):
    def setUp(self) -> None:
        self._sleep = tour.time.sleep
        tour.time.sleep = lambda *_a, **_k: None
        self._fetch = tour._fetch_json_once
        tour.reset_collect_state()

    def tearDown(self) -> None:
        tour.time.sleep = self._sleep
        tour._fetch_json_once = self._fetch
        tour.reset_collect_state()

    def test_paginate_stops_on_quota_and_records_problem(self) -> None:
        calls = {"n": 0}

        def fake(_url: str) -> dict:
            calls["n"] += 1
            if calls["n"] == 1:
                return _ok_page()
            return QUOTA_BODY

        tour._fetch_json_once = fake
        items, metas = tour.paginate(
            "searchFestival2", "test-key", {}, max_pages=5, label="t"
        )
        self.assertEqual(calls["n"], 2)
        self.assertEqual(len(items), 1)
        self.assertTrue(tour.has_blocking_fetch_failure())
        self.assertEqual(tour.fetch_problems()[0].kind, "quota")
        self.assertTrue(any(not m["ok"] for m in metas))

    def test_page1_nodata_does_not_block(self) -> None:
        tour._fetch_json_once = lambda _url: {
            "response": {
                "header": {"resultCode": "03", "resultMsg": "NODATA_ERROR"},
                "body": {"items": "", "totalCount": 0},
            }
        }
        items, _metas = tour.paginate(
            "areaBasedList2", "test-key", {}, max_pages=3, label="empty"
        )
        self.assertEqual(items, [])
        self.assertFalse(tour.has_blocking_fetch_failure())

    def test_optional_detail_failure_does_not_block(self) -> None:
        tour._fetch_json_once = lambda _url: {"_error": "URLError", "_msg": "timed out"}
        tour.fetch_json(
            "http://example.invalid/detail",
            endpoint="detailCommon2",
            retries=1,
            required=False,
        )
        self.assertFalse(tour.has_blocking_fetch_failure())
        tour.fetch_json(
            "http://example.invalid/list",
            endpoint="searchFestival2",
            retries=1,
            required=True,
        )
        self.assertTrue(tour.has_blocking_fetch_failure())
        self.assertEqual(tour.fetch_problems()[0].kind, "transport")

    def test_discover_budget_stop_is_blocking(self) -> None:
        tour._API_CALLS = tour.API_BUDGET
        orig = tour.paginate

        def boom(*_a, **_k):
            raise AssertionError("paginate should not run after the budget is spent")

        tour.paginate = boom
        try:
            disc = tour.collect_discover("test-key")
        finally:
            tour.paginate = orig
        self.assertEqual(disc["assigned"], 0)
        self.assertTrue(tour.has_blocking_fetch_failure())
        self.assertEqual(tour.fetch_problems()[0].kind, "budget")


class R26PublishTests(unittest.TestCase):
    def setUp(self) -> None:
        self._sleep = tour.time.sleep
        tour.time.sleep = lambda *_a, **_k: None
        tour.reset_collect_state()
        self._fest = tour.collect_festivals
        self._disc = tour.collect_discover
        self._merge = tour.merge_and_publish
        self._paginate = tour.paginate
        self._raw = config.RAW_DIR
        self._pub = config.PUBLISHED_JSON
        self._sync = tac.sync_published_outputs
        self._env = os.environ.get("TOUR_API_SERVICE_KEY")
        os.environ["TOUR_API_SERVICE_KEY"] = "dummy-not-a-real-key"
        self.published_before = (
            self._pub.read_bytes() if self._pub.is_file() else None
        )

    def tearDown(self) -> None:
        tour.time.sleep = self._sleep
        tour.collect_festivals = self._fest
        tour.collect_discover = self._disc
        tour.merge_and_publish = self._merge
        tour.paginate = self._paginate
        config.RAW_DIR = self._raw
        config.PUBLISHED_JSON = self._pub
        tac.sync_published_outputs = self._sync
        tour.reset_collect_state()
        if self._env is None:
            os.environ.pop("TOUR_API_SERVICE_KEY", None)
        else:
            os.environ["TOUR_API_SERVICE_KEY"] = self._env
        if self.published_before is not None and self._pub.is_file():
            if self._pub.read_bytes() != self.published_before:
                self._pub.write_bytes(self.published_before)

    def test_daily_quota_does_not_publish(self) -> None:
        calls = {"discover": 0, "merge": 0}

        def fake_fest(_key: str) -> dict:
            tour.note_fetch_problem(
                tour.FetchProblem(
                    "searchFestival2",
                    "quota",
                    "22",
                    "LIMITED_NUMBER_OF_SERVICE_REQUESTS_EXCEEDS_ERROR",
                )
            )
            return {
                "assigned": 4,
                "dropped": 0,
                "counts": {"suwon": 4},
                "sample_titles": {},
                "runs": [],
                "by_region": {},
                "eventStartDate": "20260101",
            }

        def fake_disc(_key: str) -> dict:
            calls["discover"] += 1
            raise AssertionError("discover must not run after a blocking festival fetch")

        def fake_merge(*_a, **_k):
            calls["merge"] += 1
            raise AssertionError("published feed must stay untouched")

        tour.collect_festivals = fake_fest
        tour.collect_discover = fake_disc
        tour.merge_and_publish = fake_merge
        code = tour.main()
        self.assertEqual(code, 1)
        self.assertEqual(calls["discover"], 0)
        self.assertEqual(calls["merge"], 0)
        if self.published_before is not None:
            self.assertEqual(self._pub.read_bytes(), self.published_before)

    def test_daily_empty_success_does_not_publish(self) -> None:
        def fake_fest(_key: str) -> dict:
            return {
                "assigned": 0,
                "dropped": 0,
                "counts": {},
                "sample_titles": {},
                "runs": [],
                "by_region": {},
                "eventStartDate": "20260101",
            }

        def fake_disc(_key: str) -> dict:
            return {
                "assigned": 0,
                "dropped": 0,
                "counts": {},
                "by_type": {},
                "by_region": {},
            }

        merged = {"n": 0}

        def fake_merge(*_a, **_k):
            merged["n"] += 1
            raise AssertionError("empty invent must not publish")

        tour.collect_festivals = fake_fest
        tour.collect_discover = fake_disc
        tour.merge_and_publish = fake_merge
        self.assertEqual(tour.main(), 1)
        self.assertEqual(merged["n"], 0)

    def test_daily_success_still_reaches_publish(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        config.RAW_DIR = Path(tmp.name)

        def fake_fest(_key: str) -> dict:
            return {
                "assigned": 2,
                "dropped": 0,
                "counts": {"suwon": 2},
                "sample_titles": {},
                "runs": [],
                "by_region": {},
                "eventStartDate": "20260101",
            }

        def fake_disc(_key: str) -> dict:
            return {
                "assigned": 2,
                "dropped": 0,
                "counts": {"suwon": 2},
                "by_type": {},
                "by_region": {},
            }

        merged = {"n": 0}

        def fake_merge(*_a, **_k):
            merged["n"] += 1
            return {
                "updatedAt": "2026-10-29T09:00:00+09:00",
                "counts": {"ENJOY": 2, "DISCOVER": 2},
                "total": 4,
                "culture": 0,
                "missing_required": 0,
                "per_city_tour": {},
            }

        tour.collect_festivals = fake_fest
        tour.collect_discover = fake_disc
        tour.merge_and_publish = fake_merge
        self.assertEqual(tour.main(), 0)
        self.assertEqual(merged["n"], 1)
        self.assertTrue((config.RAW_DIR / "festivals_raw.json").is_file())

    def test_tour_apply_quota_keeps_previous_rows(self) -> None:
        tmp = tempfile.TemporaryDirectory()
        self.addCleanup(tmp.cleanup)
        raw_dir = Path(tmp.name) / "raw"
        raw_dir.mkdir()
        published = Path(tmp.name) / "opportunities.json"
        original = {
            "schemaVersion": 1,
            "updatedAt": "2020-01-01T00:00:00+09:00",
            "regions": ["suwon"],
            "opportunities": [
                {
                    "id": "suwon-tour-apply-1",
                    "region": "suwon",
                    "type": "APPLY",
                    "title": "keep me",
                    "meta": {"source": "tour_api_apply"},
                }
            ],
        }
        published.write_text(
            json.dumps(original, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        config.RAW_DIR = raw_dir
        config.PUBLISHED_JSON = published
        tac.sync_published_outputs = lambda *_a, **_k: {"region_ids": []}
        calls = {"n": 0}

        def fake_paginate(endpoint, _service_key, _extra, **_kwargs):
            calls["n"] += 1
            problem = tour.classify_fetch_payload(QUOTA_BODY, endpoint=endpoint)
            assert problem is not None
            tour.note_fetch_problem(problem)
            return [{"contentid": "9", "title": "체험마을", "addr1": "수원"}], [{"ok": False}]

        tour.paginate = fake_paginate
        code = tac.main([])
        self.assertEqual(code, 1)
        self.assertEqual(calls["n"], 1)
        after = json.loads(published.read_text(encoding="utf-8"))
        self.assertEqual(after["updatedAt"], original["updatedAt"])
        self.assertEqual(after["opportunities"][0]["title"], "keep me")
        failure = json.loads((raw_dir / "tour_apply_raw.json").read_text(encoding="utf-8"))
        self.assertEqual(failure["fetchProblems"][0]["kind"], "quota")
        if self.published_before is not None:
            self.assertEqual(self._pub.read_bytes(), self.published_before)


if __name__ == "__main__":
    unittest.main()
