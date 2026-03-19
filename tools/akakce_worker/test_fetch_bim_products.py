from __future__ import annotations

import unittest

import fetch_bim_products


class FetchBimProductsTest(unittest.TestCase):
    def test_extracts_structured_products_from_html(self) -> None:
        html = """
        <div class="productArea">
          <div class="product col-12">
            <div class="inner">
              <div class="imageArea">
                <a href="/aktuel-urunler/tat-domates-salcasi/aktuel.aspx">
                  <div class="image">
                    <img src="https://cdn1.bim.com.tr/uploads/aktuel-urunler/tat.jpg" class="img-fluid" />
                  </div>
                </a>
              </div>
              <div class="descArea">
                <h2 class="subTitle">Tat</h2>
                <h2 class="title">Domates Salçası 4300 gr</h2>
                <div class="textArea">
                  <ul>
                    <li><span class="text">Cam kavanoz</span></li>
                  </ul>
                </div>
                <div class="priceArea">
                  <div class="text quantify">349,</div>
                  <div class="kusurArea"><span class="number">00</span></div>
                </div>
              </div>
            </div>
          </div>
          <div class="product justImage col-12"></div>
        </div>
        """

        items = fetch_bim_products.extract_products_from_html(
            html,
            brochure_id="bim-aktuel-14-mart",
            brochure_url="https://www.bim.com.tr/Categories/100/aktuel-urunler.aspx?Bim_AktuelTarihKey=9999",
            market_name="BİM",
            valid_from="2026-03-14",
            valid_until="2026-03-14",
        )

        self.assertEqual(1, len(items))
        self.assertEqual("Domates Salçası 4300 gr", items[0]["productName"])
        self.assertEqual("Tat", items[0]["brand"])
        self.assertEqual(349.0, items[0]["discountPrice"])
        self.assertEqual(
            "https://cdn1.bim.com.tr/uploads/aktuel-urunler/tat.jpg",
            items[0]["imageUrl"],
        )
        self.assertEqual(
            "https://www.bim.com.tr/aktuel-urunler/tat-domates-salcasi/aktuel.aspx",
            items[0]["detailUrl"],
        )
        self.assertEqual(["Cam kavanoz"], items[0]["tags"])


if __name__ == "__main__":
    unittest.main()
