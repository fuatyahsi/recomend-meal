import 'package:flutter/material.dart';

enum ProductCategory {
  food,
  cleaning,
  home,
  electronics,
  clothing,
  other,
}

extension ProductCategoryExtension on ProductCategory {
  String get labelTr {
    switch (this) {
      case ProductCategory.food:
        return 'G\u0131da & \u0130\u00e7ecek';
      case ProductCategory.cleaning:
        return 'Temizlik & Bak\u0131m';
      case ProductCategory.home:
        return 'Ev & Mutfak';
      case ProductCategory.electronics:
        return 'Teknoloji & Elektronik';
      case ProductCategory.clothing:
        return 'Giyim & Ayakkab\u0131';
      case ProductCategory.other:
        return 'Di\u011fer';
    }
  }

  String get labelEn {
    switch (this) {
      case ProductCategory.food:
        return 'Food & Beverages';
      case ProductCategory.cleaning:
        return 'Cleaning & Care';
      case ProductCategory.home:
        return 'Home & Kitchen';
      case ProductCategory.electronics:
        return 'Technology & Electronics';
      case ProductCategory.clothing:
        return 'Clothing & Footwear';
      case ProductCategory.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ProductCategory.food:
        return Icons.restaurant_rounded;
      case ProductCategory.cleaning:
        return Icons.cleaning_services_rounded;
      case ProductCategory.home:
        return Icons.chair_rounded;
      case ProductCategory.electronics:
        return Icons.devices_other_rounded;
      case ProductCategory.clothing:
        return Icons.checkroom_rounded;
      case ProductCategory.other:
        return Icons.category_rounded;
    }
  }

  String get emoji {
    switch (this) {
      case ProductCategory.food:
        return '\u{1F37D}\uFE0F';
      case ProductCategory.cleaning:
        return '\u{1F9FC}';
      case ProductCategory.home:
        return '\u{1F3E0}';
      case ProductCategory.electronics:
        return '\u{1F4F1}';
      case ProductCategory.clothing:
        return '\u{1F45F}';
      case ProductCategory.other:
        return '\u{1F4E6}';
    }
  }
}

const Map<ProductCategory, List<String>> _categoryKeywordMap = {
  ProductCategory.food: [
    'sut',
    'peynir',
    'yogurt',
    'ayran',
    'tereyagi',
    'kaymak',
    'kefir',
    'labne',
    'lor',
    'krema',
    'tavuk',
    'pilic',
    'dana',
    'kiyma',
    'kuzu',
    'kofte',
    'salam',
    'sucuk',
    'balik',
    'sosis',
    'pastirma',
    'doner',
    'hindi',
    'makarna',
    'bulgur',
    'pirinc',
    'mercimek',
    'nohut',
    'fasulye',
    'seker',
    'cikolata',
    'gofret',
    'biskuvi',
    'kraker',
    'cips',
    'corba',
    'salca',
    'tursu',
    'zeytin',
    'pekmez',
    'tahin',
    'recel',
    'bal',
    'yumurta',
    'ketcap',
    'mayonez',
    'zeytinyagi',
    'aycicek yagi',
    'maden suyu',
    'limonata',
    'kahve',
    'cay',
    'icecek',
    'meyve',
    'sebze',
    'ekmek',
    'simit',
    'pogaca',
    'baklava',
    'kadayif',
    'lokum',
    'protein bar',
    'granola',
  ],
  ProductCategory.cleaning: [
    'temizlik',
    'deterjan',
    'sabun',
    'camasir',
    'bulasik',
    'tuvalet kagidi',
    'kagit havlu',
    'yuzey temizleyici',
    'dezenfektan',
    'sampuan',
    'krem',
    'losyon',
    'deodorant',
    'dis macunu',
    'dis fircasi',
    'sac maskesi',
    'tiras',
    'ped',
    'parlatici',
    'lavabo acici',
    'kirec cozucu',
    'yumusatici',
    'cop torbasi',
  ],
  ProductCategory.home: [
    'tencere',
    'tava',
    'bardak',
    'bardag',
    'tabak',
    'fincan',
    'surahi',
    'saklama kabi',
    'termos',
    'caydanlik',
    'sahan',
    'kavanoz',
    'tepsi',
    'bicak',
    'soyacak',
    'organizer',
    'duzenleyici',
    'dolap',
    'sehpa',
    'raf',
    'ayakkabilik',
    'sifonyer',
    'gardirop',
    'tv unitesi',
    'konsol',
    'masa',
    'sandalye',
    'yastik',
    'yorgan',
    'nevresim',
    'carsaf',
    'alez',
    'paspas',
    'havlu',
    'seccade',
    'matara',
    'baharatlik',
    'sekerlik',
    'sabunluk',
    'buzdolabi organizeri',
    'sineklik',
  ],
  ProductCategory.electronics: [
    'telefon',
    'smartphone',
    'tablet',
    'televizyon',
    'tv',
    'kulaklik',
    'hoparlor',
    'soundbar',
    'kamera',
    'guvenlik kamerasi',
    'akilli saat',
    'mouse',
    'hub',
    'sarj',
    'adaptor',
    'powerbank',
    'yazici',
    'bulasik makinesi',
    'camasir makinesi',
    'kurutma makinesi',
    'buzdolabi',
    'mikrodalga',
    'supurge',
    'fon makinesi',
    'epilasyon',
    'airfryer',
    'kahve makinesi',
    'cay makinesi',
    'blender seti',
    'mikser',
    'ankastre',
    'baskul',
    'elektrikli bisiklet',
    'capa makinesi',
    'airshape',
    'lazer epilasyon',
  ],
  ProductCategory.clothing: [
    'ayakkabi',
    'spor ayakkabi',
    'terlik',
    'corap',
    'sutyen',
    'slip',
    'pijama',
    'pantolon',
    'sort',
    'esofman',
    'tisort',
    'gomlek',
    'elbise',
    'sal',
    'canta',
    'valiz',
    'saat',
    'kol saati',
  ],
};

const _knownBrands = [
  'Aknaz',
  'Activia',
  'Addison',
  'Ak\u015feker',
  'Alberto',
  'Alpro',
  'Arnica',
  'Asperox',
  'Balparmak',
  'Baroness',
  'Bee\'o',
  'Bifa',
  'B\u0130M',
  'Binvezir',
  'Bingo',
  'Bonera',
  'Casilda',
  'Casilli',
  'Chef\'s',
  'Childgen',
  'Dagi',
  'Dalan',
  'Dijitsu',
  'Dost',
  'Efsane',
  'Ekmecik',
  'Emin',
  'Eti',
  'Fakir',
  'Fushia',
  'Glass In Love',
  'Gokidy',
  'Haribo',
  'Heifer',
  'Hisar',
  'Homendra',
  'House Pratik',
  '\u0130\u00e7im',
  '\u0130nci',
  'Kumtel',
  'Lav',
  'LG',
  'Maybelline',
  'Mikado',
  'Molped',
  'Nescafe',
  'Nivea',
  'Olux',
  'Onvo',
  'Pa\u015fabah\u00e7e',
  'Papilla',
  'Philips',
  'Piccolo Mondi',
  'Pirge',
  'Polosmart',
  'Queen',
  'Rakle',
  'Sek',
  'Serel',
  'Sole',
  'Stanley',
  'SuperFresh',
  'Sunny',
  'Teks\u00fct',
  'Tombik',
  'Torku',
  'Vip',
  'Y\u00f6rsan',
];

ProductCategory categorizeProduct(String productTitle) {
  final normalizedTitle = _normalizeTr(productTitle);
  for (final entry in _categoryKeywordMap.entries) {
    final hasMatch = entry.value.any(normalizedTitle.contains);
    if (hasMatch) {
      return entry.key;
    }
  }
  return ProductCategory.other;
}

String? parseProductWeight(String productTitle) {
  final normalizedTitle = _normalizeTr(productTitle);
  final match = RegExp(
    r'(\d+(?:[.,]\d+)?)\s*(kg|g|gr|gram|ml|cl|cc|l|lt|litre|paket|adet|rulo|parca|li)',
    caseSensitive: false,
  ).firstMatch(normalizedTitle);
  if (match == null) {
    final dimensionMatch = RegExp(
      r'(\d+\s*x\s*\d+(?:\s*x\s*\d+)?)\s*(cm|mm|m)',
      caseSensitive: false,
    ).firstMatch(normalizedTitle);
    if (dimensionMatch != null) {
      return '${dimensionMatch.group(1)} ${dimensionMatch.group(2)}';
    }
    final sizeMatch = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*(cm|mm|m)',
      caseSensitive: false,
    ).firstMatch(normalizedTitle);
    if (sizeMatch == null) {
      return null;
    }
    return '${sizeMatch.group(1)} ${sizeMatch.group(2)}';
  }
  return '${match.group(1)} ${match.group(2)}';
}

String? parseProductBrand(String productTitle) {
  final normalizedTitle = _normalizeTr(productTitle);
  for (final brand in _knownBrands) {
    if (normalizedTitle.startsWith(_normalizeTr(brand))) {
      return brand;
    }
  }
  return null;
}

String _normalizeTr(String value) {
  return value
      .toLowerCase()
      .replaceAll('\u0131', 'i')
      .replaceAll('\u011f', 'g')
      .replaceAll('\u00fc', 'u')
      .replaceAll('\u015f', 's')
      .replaceAll('\u00f6', 'o')
      .replaceAll('\u00e7', 'c');
}
