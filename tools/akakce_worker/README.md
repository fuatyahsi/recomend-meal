# Akakce Worker

Bu klasor, `Smart Aktuel Asistani` icin merkezi brosur isleme hattinin ilk surumunu tutar.

Amac:
- `https://www.akakce.com/brosurler/?l=1` listesini gunluk taramak
- yeni brosur detay sayfalarini bulmak
- gercek CDN gorsellerini ayiklamak
- sayfalari urun karti seviyesine yaklasacak sekilde tile'lara bolmek
- daha sonra takilacak OCR / CV motoru icin temiz bir manifest ve JSON feed uretmek

Bu worker, telefon ustundeki tam sayfa OCR denemesinin yerini almak icin tasarlandi.

Not:
- GitHub-hosted runner bazen Akakce listing sayfasinda Cloudflare engeline takilir.
- Bu durumda worker, `input/seed_urls.txt` icindeki seed URL'lerle calisabilir.
- En guvenli seed tipi dogrudan CDN brosur gorsel URL'leridir.

## Klasor yapisi

- `fetch_sources.py`
  - Akakce liste ve detay sayfalarini okur
  - brosur ve sayfa manifesti uretir
- `segment_pages.py`
  - sayfa gorsellerini tile manifestine donusturur
- `extract_items.py`
  - fiyat etiketi adaylarini bulur
  - urun crop'lari uretir
  - OCR ile urun adi / fiyat cikarmayi dener
- `export_feed.py`
  - islenmis urunleri app'in tuketecegi JSON feed formatina cevirir
- `run_pipeline.py`
  - tum adimlari sirayla calistiran hafif orkestrator
- `requirements.txt`
  - worker bagimliliklari
- `feed.example.json`
  - hedef feed biciminin ornek cikisi
- `input/seed_urls.example.txt`
  - manuel / workflow_dispatch seed girisi ornegi

## Kurulum

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r tools/akakce_worker/requirements.txt
```

OCR ve urun crop adimi icin ek stack:

```bash
pip install -r tools/akakce_worker/requirements-ocr.txt
```

Windows notu:
- `onnxruntime` import hatasi alirsan ayni dosya zaten `msvc-runtime` kurar.
- Gerekirse komutu `--upgrade` ile tekrar calistir:

```bash
python -m pip install --upgrade -r tools/akakce_worker/requirements-ocr.txt
```

## Calistirma

Sadece kaynak manifesti uretmek:

```bash
python tools/akakce_worker/fetch_sources.py --max-brochures 24 --download-images
```

Tile manifesti uretmek:

```bash
python tools/akakce_worker/segment_pages.py
```

Tum hattin iskeletini calistirmak:

```bash
python tools/akakce_worker/run_pipeline.py --max-brochures 24 --download-images
```

Urun adaylarini da cikarmak:

```bash
python tools/akakce_worker/run_pipeline.py --max-brochures 24 --download-images --extract-items
```

Seed URL ile:

```bash
python tools/akakce_worker/fetch_sources.py --seed-urls-file tools/akakce_worker/input/seed_urls.txt --download-images
```

## Uretilen dosyalar

Varsayilan olarak su dosyalar `tools/akakce_worker/output/` altina yazilir:

- `source_manifest.json`
- `tile_manifest.json`
- `extracted_products.json`
- `actueller_feed.json`
- `images/<brochure_id>/page_XX.jpg`
- `crops/<brochure_id>/page_XX/product_YYY.jpg`

## Sonraki teknik adim

Bu iskelet bilerek iki parcayi ayri tuttu:

1. Kaynak toplama ve sayfa manifesti
2. Urun cikarma ve fiyat eslestirme

Bir sonraki adimda `extract_items.py` benzeri bir katman eklenecek ve:
- fiyat etiketi tespiti
- urun metni OCR'i
- marka / urun / fiyat baglama
- guven skoru hesaplama

aynı manifestin ustune oturtulacak.
