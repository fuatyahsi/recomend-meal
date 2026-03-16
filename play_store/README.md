# Play Store Assets

Bu klasor Android yayin hazirligi icin temel varliklari ve metinleri tutar.

Hazirlanan dosyalar:
- `metadata/tr-TR/` : Turkce Play Store metinleri
- `metadata/en-US/` : Ingilizce Play Store metinleri
- `checklist.md` : Yayina cikmadan once kontrol listesi

Gorsel varliklar:
- Uygulama ikon kaynagi: `assets/images/app_icon_source.png`
- Feature graphic: `assets/images/play_feature_graphic.png`

Ikonlari uretmek icin:
```powershell
flutter pub get
dart run flutter_launcher_icons
```

Android icin release bundle:
```powershell
flutter build appbundle --release
```
