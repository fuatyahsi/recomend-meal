from __future__ import annotations

import json
from pathlib import Path


def load_json(path: Path) -> dict:
    if not path.exists():
        return {}
    return json.loads(path.read_text(encoding="utf-8"))


def main() -> None:
    output_root = Path(__file__).resolve().parent / "output"
    source_manifest = load_json(output_root / "source_manifest.json")
    extracted = load_json(output_root / "extracted_products.json")
    feed = load_json(output_root / "actueller_feed.json")

    brochures = source_manifest.get("brochures", [])
    extracted_items = extracted.get("items", [])
    feed_items = feed.get("items", [])

    print("=== Market Worker Summary ===")
    print(f"Source label: {source_manifest.get('sourceLabel') or feed.get('sourceLabel') or '-'}")
    print(f"Brochure count: {len(brochures)}")
    for brochure in brochures[:3]:
        print(
            f"- {brochure.get('market_name')} | "
            f"{brochure.get('detail_url')} | "
            f"{brochure.get('image_count')} image(s)"
        )

    print(f"Extracted candidate count: {len(extracted_items)}")
    for item in extracted_items[:5]:
        print(
            f"- {item.get('marketName')} | "
            f"{item.get('productName')} | "
            f"{item.get('price', item.get('discountPrice'))}"
        )

    print(f"Feed item count: {len(feed_items)}")
    for item in feed_items[:5]:
        print(
            f"- {item.get('marketName')} | "
            f"{item.get('productName')} | "
            f"{item.get('discountPrice')}"
        )


if __name__ == "__main__":
    main()
