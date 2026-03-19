from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from urllib.parse import urljoin

import requests
from bs4 import BeautifulSoup

import fetch_sources as shared

BIM_BASE_URL = "https://www.bim.com.tr"


def build_parser() -> argparse.ArgumentParser:
    worker_root = Path(__file__).resolve().parent
    output_root = worker_root / "output"
    parser = argparse.ArgumentParser(
        description="Extract structured products from official BİM catalog pages."
    )
    parser.add_argument(
        "--source-manifest",
        default=str(output_root / "source_manifest.json"),
    )
    parser.add_argument(
        "--output",
        default=str(output_root / "extracted_products.json"),
    )
    parser.add_argument("--timeout", type=int, default=30)
    parser.add_argument("--max-brochures", type=int, default=24)
    return parser


def normalize_url(url: str) -> str:
    if url.startswith("//"):
        return f"https:{url}"
    return urljoin(BIM_BASE_URL, url)


def normalize_whitespace(value: str) -> str:
    return re.sub(r"\s+", " ", value or "").strip()


def parse_price(major: str, minor: str) -> float | None:
    raw = f"{major}{minor}"
    cleaned = raw.replace(".", "").replace(",", ".")
    try:
        return float(cleaned)
    except ValueError:
        return None


def extract_image_url(product_node: BeautifulSoup) -> str | None:
    image = product_node.select_one(".imageArea img")
    if image is None:
        return None
    for attribute in ("src", "xsrc", "data-src"):
        value = image.get(attribute)
        if value:
            return normalize_url(value)
    return None


def extract_tags(product_node: BeautifulSoup) -> list[str]:
    tags: list[str] = []
    for item in product_node.select(".textArea li .text"):
        text = normalize_whitespace(item.get_text(" ", strip=True))
        if text:
            tags.append(text)
    return tags


def extract_products_from_html(
    html: str,
    *,
    brochure_id: str,
    brochure_url: str,
    market_name: str,
    valid_from: str | None,
    valid_until: str | None,
) -> list[dict]:
    soup = BeautifulSoup(html, "html.parser")
    items: list[dict] = []

    for index, node in enumerate(soup.select(".productArea .product"), start=1):
        classes = set(node.get("class", []))
        if "justImage" in classes:
            continue

        title_tag = node.select_one(".descArea .title")
        if title_tag is None:
            continue

        title = normalize_whitespace(title_tag.get_text(" ", strip=True))
        if not title:
            continue

        major_tag = node.select_one(".priceArea .text.quantify")
        minor_tag = node.select_one(".priceArea .kusurArea .number")
        if major_tag is None:
            continue

        price = parse_price(
            normalize_whitespace(major_tag.get_text(" ", strip=True)),
            normalize_whitespace(minor_tag.get_text(" ", strip=True)) if minor_tag else "00",
        )
        if price is None:
            continue

        detail_anchor = node.select_one(".imageArea a[href]")
        detail_url = normalize_url(detail_anchor.get("href")) if detail_anchor else brochure_url
        image_url = extract_image_url(node)
        brand_tag = node.select_one(".descArea .subTitle")
        brand = normalize_whitespace(brand_tag.get_text(" ", strip=True)) if brand_tag else ""

        items.append(
            {
                "id": f"{brochure_id}-p{index:03d}",
                "brochureId": brochure_id,
                "brochureUrl": brochure_url,
                "marketName": market_name,
                "pageIndex": 1,
                "productName": title,
                "brand": brand or None,
                "discountPrice": price,
                "currency": "TRY",
                "confidence": 1.0,
                "imageUrl": image_url,
                "detailUrl": detail_url,
                "sourceLabel": "BİM Structured Catalog",
                "validFrom": valid_from,
                "validUntil": valid_until,
                "ocrText": title,
                "tags": extract_tags(node),
            }
        )

    return items


def main() -> None:
    args = build_parser().parse_args()
    source_manifest_path = Path(args.source_manifest).resolve()
    output_path = Path(args.output).resolve()
    output_path.parent.mkdir(parents=True, exist_ok=True)

    session = requests.Session()
    session.headers.update(shared.DEFAULT_HEADERS)

    manifest = json.loads(source_manifest_path.read_text(encoding="utf-8"))
    brochures = manifest.get("brochures", [])[: args.max_brochures]

    extracted_items: list[dict] = []
    for brochure in brochures:
        catalog_url = brochure.get("catalog_url") or brochure.get("detail_url")
        if not catalog_url:
            continue
        html = shared.fetch_html(session, catalog_url, args.timeout)
        extracted_items.extend(
            extract_products_from_html(
                html,
                brochure_id=str(brochure.get("brochure_id", "")),
                brochure_url=str(catalog_url),
                market_name=str(brochure.get("market_name") or "BİM"),
                valid_from=brochure.get("valid_from"),
                valid_until=brochure.get("valid_until"),
            )
        )

    payload = {
        "itemCount": len(extracted_items),
        "items": extracted_items,
    }
    output_path.write_text(
        json.dumps(payload, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )
    print(f"Wrote {len(extracted_items)} extracted product candidates to {output_path}")


if __name__ == "__main__":
    main()
