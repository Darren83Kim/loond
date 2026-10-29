"""R31: culture-portal city keep rules and TourAPI festival backfill guards."""

from __future__ import annotations

import json
import tempfile
import unittest
from pathlib import Path

from loond_worker import culture_collect as cc
from loond_worker import region_codes as rc
from loond_worker.run_tour_daily import select_festival_backfill_items


def _city(rid: str) -> dict:
    return rc.REGION_BY_ID[rid]


class CultureKeepTests(unittest.TestCase):
    def test_chungju_bracket_title_without_city_in_place(self) -> None:
        # Portal seq 402594: area 충북, place 탄금호…, title [충주]. Address is 충주시.
        it = {
            "seq": "402594",
            "area": "충북",
            "sigungu": "",
            "place": "탄금호 국제조정경기장",
            "title": "[충주] 호수 위 우주",
        }
        self.assertTrue(cc._keep_city(it, _city("chungju")))
        self.assertFalse(cc._keep_city(it, _city("danyang")))

    def test_chungju_place_naming_other_city_rejected(self) -> None:
        it = {
            "seq": "1",
            "area": "충북",
            "sigungu": "",
            "place": "청주시문화회관",
            "title": "[충주] 오배정",
        }
        self.assertFalse(cc._keep_city(it, _city("chungju")))

    def test_chungju_foreign_sigungu_rejected(self) -> None:
        it = {
            "seq": "1",
            "area": "충북",
            "sigungu": "청주시",
            "place": "청주시청",
            "title": "[충주] 오배정",
        }
        self.assertFalse(cc._keep_city(it, _city("chungju")))

    def test_danyang_bare_title_not_kept(self) -> None:
        # 수양개빛터널 is a title hit with no [단양] / 단양군 and no venue 시·군.
        it = {
            "seq": "190629",
            "area": "충북",
            "sigungu": "",
            "place": "",
            "title": "단양 수양개빛터널",
        }
        self.assertFalse(cc._keep_city(it, _city("danyang")))

    def test_danyang_bracket_and_place_kept(self) -> None:
        it = {
            "seq": "2",
            "area": "충북",
            "sigungu": "",
            "place": "도담삼봉",
            "title": "[단양] 겨울 음악회",
        }
        self.assertTrue(cc._keep_city(it, _city("danyang")))

    def test_tongyeong_title_particle_not_kept(self) -> None:
        it = {
            "seq": "189837",
            "area": "경남",
            "sigungu": "",
            "place": "",
            "title": "우리나라에 이런 곳이!? | 통영의 새로운 핫플레이스",
        }
        self.assertFalse(cc._keep_city(it, _city("tongyeong")))

    def test_seongnam_bundang_gu_kept_suwon_rejected(self) -> None:
        it = {
            "seq": "404370",
            "area": "경기",
            "sigungu": "분당구",
            "place": "성남아트센터 콘서트홀",
            "title": "[성남] 제6회 버디색소폰앙상블 정기연주회",
        }
        self.assertTrue(cc._keep_city(it, _city("seongnam")))
        self.assertFalse(cc._keep_city(it, _city("suwon")))

    def test_bucheon_district_kept(self) -> None:
        it = {
            "seq": "3",
            "area": "경기",
            "sigungu": "원미구",
            "place": "복사골문화센터",
            "title": "부천 성과공유회",
        }
        self.assertTrue(cc._keep_city(it, _city("bucheon")))
        self.assertFalse(cc._keep_city(it, _city("seongnam")))

    def test_goyang_cat_title_rejected(self) -> None:
        it = {
            "seq": "4",
            "area": "서울",
            "sigungu": "",
            "place": "서울 미술관",
            "title": "고양이 전시",
        }
        self.assertFalse(cc._keep_city(it, _city("goyang")))
        it_gyeonggi = dict(it, area="경기", place="일산문화공원", title="고양이 전시")
        self.assertFalse(cc._keep_city(it_gyeonggi, _city("goyang")))

    def test_hongseongnam_not_seongnam(self) -> None:
        it = {
            "seq": "5",
            "area": "경기",
            "sigungu": "",
            "place": "",
            "title": "홍성남 콘서트",
        }
        self.assertFalse(cc._keep_city(it, _city("seongnam")))
        self.assertFalse(
            cc._keep_city(
                {
                    "seq": "6",
                    "area": "경기",
                    "sigungu": "",
                    "place": "홍성남로 12",
                    "title": "콘서트",
                },
                _city("seongnam"),
            )
        )

    def test_suncheon_integrated_sido_alias(self) -> None:
        it = {
            "seq": "402756",
            "area": "전남광주통합특별시",
            "sigungu": "순천시",
            "place": "순천부 읍성 남문터광장",
            "title": "2026 순천문화기획학교",
        }
        self.assertTrue(cc._keep_city(it, _city("suncheon")))
        self.assertFalse(cc._keep_city(it, _city("gwangju")))

    def test_yeosu_under_gwangju_sido_not_stolen(self) -> None:
        it = {
            "seq": "401428",
            "area": "광주",
            "sigungu": "",
            "place": "여수시민회관",
            "title": "안중근 의사 음악연가",
        }
        self.assertTrue(cc._keep_city(it, _city("yeosu")))
        self.assertFalse(cc._keep_city(it, _city("gwangju")))

    def test_detail_address_drops_other_city(self) -> None:
        it = {
            "area": "충북",
            "sigungu": "",
            "place": "탄금호 국제조정경기장",
            "addr": "충청북도 청주시 상당구 문화동",
            "title": "[충주] 오배정",
        }
        self.assertTrue(cc._detail_conflicts_city(it, _city("chungju")))
        good = dict(it, addr="충청북도 충주시 중앙탑면 중앙탑길 150")
        self.assertFalse(cc._detail_conflicts_city(good, _city("chungju")))

    def test_sido_queries_include_integrated_and_full_names(self) -> None:
        chungju = rc.culture_sido_queries(_city("chungju"))
        self.assertEqual(chungju[0], "충북")
        self.assertIn("충청북도", chungju)
        suncheon = rc.culture_sido_queries(_city("suncheon"))
        self.assertIn("광주", suncheon)
        self.assertIn("전남광주통합특별시", suncheon)
        self.assertIn("전남", suncheon)
        self.assertLessEqual(len(suncheon), 8)
        gapyeong = rc.culture_sido_queries(_city("gapyeong"))
        self.assertIn("경기", gapyeong)
        self.assertIn("경기도", gapyeong)

    def test_address_does_not_treat_exhibition_word_as_city(self) -> None:
        self.assertIsNone(rc.address_affirms_city("개인전시회", _city("chungju")))
        self.assertIsNone(
            rc.address_affirms_city("탄금호 국제조정경기장", _city("chungju"))
        )


class LdongAssignTests(unittest.TestCase):
    def test_five_digit_signgu_maps_chungju_and_danyang(self) -> None:
        chungju = rc.assign_region(
            {"lDongRegnCd": "43", "lDongSignguCd": "43130", "title": "청주에서도 열린 행사"}
        )
        self.assertIsNotNone(chungju)
        self.assertEqual(chungju["id"], "chungju")
        danyang = rc.assign_region({"lDongRegnCd": "", "lDongSignguCd": "43800"})
        self.assertEqual(danyang["id"], "danyang")

    def test_yeosu_prefixed_code_not_gwangju(self) -> None:
        yeosu = rc.assign_region(
            {
                "lDongRegnCd": "12",
                "lDongSignguCd": "12130",
                "title": "전남광주통합특별시립교향악단",
                "addr1": "전남광주통합특별시 여수시",
            }
        )
        self.assertEqual(yeosu["id"], "yeosu")

    def test_unknown_signgu_does_not_keyword_fallback(self) -> None:
        # 12/110 is not a catalog 시군. Title must not pull it into 여수.
        missed = rc.assign_region(
            {
                "lDongRegnCd": "12",
                "lDongSignguCd": "12110",
                "title": "여수 밤바다",
                "addr1": "전남광주통합특별시 여수시",
            }
        )
        self.assertIsNone(missed)

    def test_three_digit_and_keyword_still_work(self) -> None:
        self.assertEqual(
            rc.assign_region({"lDongRegnCd": "43", "lDongSignguCd": "130"})["id"],
            "chungju",
        )
        self.assertEqual(
            rc.assign_region({"addr1": "충청북도 충주시 중앙탑면", "title": "우륵"})["id"],
            "chungju",
        )
        self.assertEqual(
            rc.assign_region({"lDongRegnCd": "11", "lDongSignguCd": "680"})["id"],
            "seoul",
        )
        self.assertEqual(
            rc.assign_region({"lDongSignguCd": "36110"})["id"],
            "sejong",
        )
        self.assertIsNone(
            rc.assign_region({"title": "홍성남 콘서트", "addr1": "충청남도 홍성군"})
        )


class FestivalBackfillTests(unittest.TestCase):
    def test_keyword_rows_must_be_type_15_and_same_city(self) -> None:
        seen: set[str] = set()
        items = [
            {"contentid": "food", "contenttypeid": "39", "title": "충주 맛집", "addr1": "충주시"},
            {
                "contentid": "fest",
                "contenttypeid": "15",
                "lDongRegnCd": "43",
                "lDongSignguCd": "43130",
                "title": "탄금대 축제",
            },
            {
                "contentid": "other",
                "contenttypeid": "15",
                "lDongRegnCd": "11",
                "lDongSignguCd": "110",
                "title": "서울 축제",
            },
            {
                "contentid": "cheongju",
                "contenttypeid": "15",
                "lDongRegnCd": "43",
                "lDongSignguCd": "110",
                "title": "충주 이름이 들어간 청주 행사",
                "addr1": "충청북도 청주시",
            },
            {
                "contentid": "title-only-wrong-addr",
                "contenttypeid": "15",
                "title": "충주 축제",
                "addr1": "충청북도 청주시 상당구",
            },
            {
                "contentid": "addr-ok",
                "contenttypeid": "15",
                "title": "국제조정경기장 축제",
                "addr1": "충청북도 충주시 중앙탑면",
            },
        ]
        got = select_festival_backfill_items(
            items,
            target_region_id="chungju",
            seen_ids=seen,
            require_content_type_15=True,
            limit=30,
        )
        self.assertEqual([it["contentid"] for it in got], ["fest", "addr-ok"])
        again = select_festival_backfill_items(
            items,
            target_region_id="chungju",
            seen_ids=seen,
            require_content_type_15=True,
            limit=30,
        )
        self.assertEqual(again, [])

    def test_festival_endpoint_allows_missing_content_type(self) -> None:
        got = select_festival_backfill_items(
            [{"contentid": "dy", "lDongRegnCd": "43", "lDongSignguCd": "800", "title": "온달"}],
            target_region_id="danyang",
            seen_ids=set(),
            require_content_type_15=False,
            limit=30,
        )
        self.assertEqual(len(got), 1)
        rejected = select_festival_backfill_items(
            [{"contentid": "shop", "contenttypeid": "38", "lDongRegnCd": "43", "lDongSignguCd": "800"}],
            target_region_id="danyang",
            seen_ids=set(),
            require_content_type_15=False,
            limit=30,
        )
        self.assertEqual(rejected, [])


class CultureMergeTests(unittest.TestCase):
    def test_partial_replace_preserves_other_cities_and_apply(self) -> None:
        doc = {
            "opportunities": [
                {"id": "seoul-apply-1", "region": "seoul", "type": "APPLY", "title": "서울 신청"},
                {
                    "id": "seoul-culture-1",
                    "region": "seoul",
                    "type": "ENJOY",
                    "title": "서울 공연",
                    "meta": {"source": "culture_portal"},
                },
                {
                    "id": "chungju-culture-old",
                    "region": "chungju",
                    "type": "ENJOY",
                    "title": "옛 충주",
                    "meta": {"source": "culture_portal"},
                },
                {
                    "id": "chungju-tour-1",
                    "region": "chungju",
                    "type": "ENJOY",
                    "title": "우륵문화제",
                    "meta": {"source": "tour_api"},
                },
            ]
        }
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "opportunities.json"
            path.write_text(json.dumps(doc), encoding="utf-8")
            stats = cc.merge_into_published(
                path,
                [
                    {
                        "id": "chungju-culture-new",
                        "region": "chungju",
                        "type": "ENJOY",
                        "title": "[충주] 호수 위 우주",
                        "meta": {"source": "culture_portal"},
                    }
                ],
                replace_region_ids={"chungju"},
            )
            out = json.loads(path.read_text(encoding="utf-8"))
        ids = [o["id"] for o in out["opportunities"]]
        self.assertIn("seoul-apply-1", ids)
        self.assertIn("seoul-culture-1", ids)
        self.assertIn("chungju-tour-1", ids)
        self.assertIn("chungju-culture-new", ids)
        self.assertNotIn("chungju-culture-old", ids)
        self.assertEqual(stats["culture_enjoy"], 1)

    def test_failed_list_preserves_that_city(self) -> None:
        doc = {
            "opportunities": [
                {
                    "id": "danyang-culture-old",
                    "region": "danyang",
                    "type": "ENJOY",
                    "title": "단양 기존",
                    "meta": {"source": "culture_portal"},
                }
            ]
        }
        with tempfile.TemporaryDirectory() as tmp:
            path = Path(tmp) / "opportunities.json"
            path.write_text(json.dumps(doc), encoding="utf-8")
            cc.merge_into_published(
                path,
                [],
                replace_region_ids={"danyang"},
                preserve_region_ids={"danyang"},
            )
            out = json.loads(path.read_text(encoding="utf-8"))
        self.assertEqual(out["opportunities"][0]["id"], "danyang-culture-old")


if __name__ == "__main__":
    unittest.main()
