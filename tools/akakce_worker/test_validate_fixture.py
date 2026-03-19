from __future__ import annotations

import unittest

import validate_fixture


class ValidateFixtureTest(unittest.TestCase):
    def test_brochure_ids_for_fixture_filters_title_and_market(self) -> None:
        fixture = {
            "marketName": "BIM",
            "brochureTitleContains": "10 Mart Salı",
        }
        source_manifest = {
            "brochures": [
                {
                    "brochure_id": "bim-10-mart",
                    "title": "Aktüel | 10 Mart Salı",
                    "market_name": "BİM",
                },
                {
                    "brochure_id": "bim-13-mart",
                    "title": "Aktüel | 13 Mart Cuma",
                    "market_name": "BİM",
                },
            ]
        }

        brochure_ids = validate_fixture.brochure_ids_for_fixture(fixture, source_manifest)

        self.assertEqual({"bim-10-mart"}, brochure_ids)

    def test_match_fixture_products_uses_price_and_similarity(self) -> None:
        expected = [
            {"productName": "Dana Kangal Sucuk Torku 500 g", "price": 299.0},
            {"productName": "Tereyağı Torku 500 g", "price": 349.0},
        ]
        actual = [
            {"id": "1", "productName": "DANA KANGAL SUCUK", "discountPrice": 299.0},
            {"id": "2", "productName": "TEREYAĞI", "discountPrice": 349.0},
            {"id": "3", "productName": "Ayran", "discountPrice": 14.5},
        ]

        matches, missing = validate_fixture.match_fixture_products(
            expected_products=expected,
            actual_items=actual,
            min_score=0.45,
        )

        self.assertEqual(2, len(matches))
        self.assertEqual([], missing)


if __name__ == "__main__":
    unittest.main()
