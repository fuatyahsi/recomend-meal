const marketDisplayNamesById = <String, String>{
  'a101': 'A101',
  'bim': 'BİM',
  'sok': 'ŞOK',
  'migros': 'Migros',
  'carrefoursa': 'CarrefourSA',
  'hakmar': 'Hakmar Express',
  'metro': 'Metro',
  'kooperatif': 'Tarım Kredi',
  'file': 'File Market',
  'bildirici': 'Bildirici',
  'getir': 'Getir',
  'yemeksepeti': 'Yemeksepeti',
};

const marketAliasesById = <String, List<String>>{
  'a101': ['a101'],
  'bim': ['bim', 'bım', 'b.i.m'],
  'sok': ['sok', 'şok', 'şok'],
  'migros': ['migros'],
  'carrefoursa': ['carrefoursa', 'carrefour sa', 'carrefour'],
  'hakmar': ['hakmar', 'hakmar express'],
  'metro': ['metro', 'metro tr', 'metro-tr'],
  'kooperatif': [
    'kooperatif',
    'kooperatif market',
    'tarim kredi',
    'tarım kredi',
    'tarim kredi kooperatifi',
    'tarım kredi kooperatifi',
    'kooperatifmarket',
  ],
  'file': ['file', 'file market', 'filemarket'],
  'bildirici': ['bildirici'],
  'getir': ['getir'],
  'yemeksepeti': ['yemeksepeti', 'yemek sepeti'],
};

String normalizeMarketToken(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '');
}

String? normalizeMarketId(String? value) {
  if (value == null) return null;
  final normalized = normalizeMarketToken(value);
  if (normalized.isEmpty) return null;

  if (marketDisplayNamesById.containsKey(normalized)) {
    return normalized;
  }

  for (final entry in marketAliasesById.entries) {
    final aliases = entry.value;
    if (aliases.any((alias) => normalizeMarketToken(alias) == normalized)) {
      return entry.key;
    }
  }

  for (final entry in marketDisplayNamesById.entries) {
    if (normalizeMarketToken(entry.value) == normalized) {
      return entry.key;
    }
  }

  return null;
}

String displayNameForMarket(String? value) {
  if (value == null || value.trim().isEmpty) {
    return '';
  }
  final id = normalizeMarketId(value);
  return id == null ? value.trim() : marketDisplayNamesById[id]!;
}

List<String> normalizeMarketIds(Iterable<String> values) {
  final ids = <String>[];
  for (final value in values) {
    final id = normalizeMarketId(value);
    if (id != null && !ids.contains(id)) {
      ids.add(id);
    }
  }
  return ids;
}
