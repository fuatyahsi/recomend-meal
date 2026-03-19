import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class PreparedActuellerSource {
  final String requestUrl;
  final String sourceLabel;
  final String? detectedStore;
  final List<String> imageUrls;
  final List<String> localImagePaths;

  const PreparedActuellerSource({
    required this.requestUrl,
    required this.sourceLabel,
    required this.detectedStore,
    required this.imageUrls,
    required this.localImagePaths,
  });
}

class SmartActuellerSourceService {
  static const akakceListingUrl = 'https://www.akakce.com/brosurler/?l=1';

  final http.Client _client;

  SmartActuellerSourceService({http.Client? client})
      : _client = client ?? http.Client();

  Future<PreparedActuellerSource> prepareSource(String inputUrl) async {
    final trimmed = inputUrl.trim();
    if (trimmed.isEmpty) {
      throw Exception('Broşür bağlantısı boş.');
    }

    final uri = Uri.parse(trimmed);
    if (_looksLikeImage(uri)) {
      final detectedStore = _detectStore(trimmed);
      final localPath = await _downloadImage(uri);
      return PreparedActuellerSource(
        requestUrl: trimmed,
        sourceLabel: detectedStore == null
            ? 'Akakçe Aktüel'
            : '$detectedStore Aktüel',
        detectedStore: detectedStore,
        imageUrls: [uri.toString()],
        localImagePaths: [localPath],
      );
    }

    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Broşür sayfası alınamadı (${response.statusCode}).',
      );
    }

    final html = _decodeResponseBody(response);
    final imageUrls = _extractImageUrls(html, uri);
    if (imageUrls.isEmpty) {
      throw Exception('Broşür görseli bulunamadı.');
    }

    final localImagePaths = <String>[];
    for (final imageUrl in imageUrls.take(6)) {
      localImagePaths.add(await _downloadImage(Uri.parse(imageUrl)));
    }

    final sourceLabel = _extractTitle(html) ??
        ((_detectStore(trimmed) ?? _detectStore(html)) == null
            ? 'Akakçe Aktüel'
            : '${_detectStore(trimmed) ?? _detectStore(html)} Aktüel');

    return PreparedActuellerSource(
      requestUrl: trimmed,
      sourceLabel: sourceLabel,
      detectedStore: _detectStore('$sourceLabel $html'),
      imageUrls: imageUrls,
      localImagePaths: localImagePaths,
    );
  }

  Future<List<String>> discoverBrochureUrls({int maxTotal = 18}) async {
    final listingUri = Uri.parse(akakceListingUrl);
    final response = await _client.get(listingUri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Akakçe broşür listesi alınamadı (${response.statusCode}).',
      );
    }

    final html = _decodeResponseBody(response);
    final matches = RegExp(
      r'''href=["'](\/brosurler\/[^"']+)["']''',
      caseSensitive: false,
    ).allMatches(html);

    final urls = <String>[];
    final seenUrls = <String>{};
    final seenStores = <String>{};

    for (final match in matches) {
      final href = match.group(1);
      if (href == null || href.isEmpty) {
        continue;
      }

      final resolved = listingUri.resolve(href).toString();
      if (!seenUrls.add(resolved)) {
        continue;
      }

      final store = _detectStore(resolved);
      if (store != null && !seenStores.add(store)) {
        continue;
      }

      urls.add(resolved);
      if (urls.length >= maxTotal) {
        break;
      }
    }

    return urls;
  }

  bool _looksLikeImage(Uri uri) {
    final path = uri.path.toLowerCase();
    return path.endsWith('.jpg') ||
        path.endsWith('.jpeg') ||
        path.endsWith('.png') ||
        path.endsWith('.webp') ||
        path.contains('/_bro/');
  }

  List<String> _extractImageUrls(String html, Uri pageUri) {
    final matches = <String>{};

    final directMatches = RegExp(
      r'''https?:\/\/cdn\.akakce\.com\/_bro\/[^"']+\.(?:jpg|jpeg|png|webp)''',
      caseSensitive: false,
    ).allMatches(html);
    for (final match in directMatches) {
      final url = match.group(0);
      if (url != null) {
        matches.add(url);
      }
    }

    final protocolRelativeMatches = RegExp(
      r'''\/\/cdn\.akakce\.com\/_bro\/[^"']+\.(?:jpg|jpeg|png|webp)''',
      caseSensitive: false,
    ).allMatches(html);
    for (final match in protocolRelativeMatches) {
      final url = match.group(0);
      if (url != null) {
        matches.add('https:$url');
      }
    }

    final ogImageMatch = RegExp(
      r'''<meta[^>]+property=["']og:image["'][^>]+content=["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(html);
    final ogImage = ogImageMatch?.group(1);
    if (ogImage != null && ogImage.isNotEmpty) {
      matches.add(pageUri.resolve(ogImage).toString());
    }

    return matches.toList();
  }

  String? _extractTitle(String html) {
    final ogTitleMatch = RegExp(
      r'''<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']+)["']''',
      caseSensitive: false,
    ).firstMatch(html);
    final ogTitle = ogTitleMatch?.group(1);
    if (ogTitle != null && ogTitle.trim().isNotEmpty) {
      return _decodeBasicHtml(ogTitle.trim());
    }

    final titleMatch = RegExp(
      r'<title>([^<]+)</title>',
      caseSensitive: false,
    ).firstMatch(html);
    final title = titleMatch?.group(1);
    if (title == null || title.trim().isEmpty) {
      return null;
    }
    return _decodeBasicHtml(title.trim());
  }

  Future<String> _downloadImage(Uri uri) async {
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Broşür görseli indirilemedi (${response.statusCode}).');
    }

    final tempDir = await Directory.systemTemp.createTemp(
      'fridgechef_actuel_',
    );
    final extension = _fileExtension(uri.path);
    final file = File('${tempDir.path}\\brochure$extension');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file.path;
  }

  String _decodeResponseBody(http.Response response) {
    try {
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    } catch (_) {
      return response.body;
    }
  }

  String _fileExtension(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return '.png';
    if (lower.endsWith('.webp')) return '.webp';
    if (lower.endsWith('.jpeg')) return '.jpeg';
    return '.jpg';
  }

  String _decodeBasicHtml(String input) {
    return input
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', '\'')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&uuml;', 'ü')
        .replaceAll('&ouml;', 'ö')
        .replaceAll('&ccedil;', 'ç')
        .replaceAll('&Ccedil;', 'Ç')
        .replaceAll('&Uuml;', 'Ü')
        .replaceAll('&Ouml;', 'Ö')
        .replaceAll('&nbsp;', ' ');
  }

  String? _detectStore(String source) {
    final normalized = _normalize(source);
    if (normalized.contains('migros')) return 'Migros';
    if (normalized.contains('carrefoursa')) return 'CarrefourSA';
    if (normalized.contains('a101')) return 'A101';
    if (normalized.contains('bim')) return 'BIM';
    if (normalized.contains('sok')) return 'SOK';
    if (normalized.contains('esenlik')) return 'Esenlik';
    if (normalized.contains('hakmar')) return 'Hakmar';
    if (normalized.contains('tarim kredi')) return 'Tarım Kredi';
    return null;
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('İ', 'i')
        .replaceAll('Ğ', 'g')
        .replaceAll('Ü', 'u')
        .replaceAll('Ş', 's')
        .replaceAll('Ö', 'o')
        .replaceAll('Ç', 'c')
        .replaceAll('Ä±', 'i')
        .replaceAll('ÄŸ', 'g')
        .replaceAll('Ã¼', 'u')
        .replaceAll('ÅŸ', 's')
        .replaceAll('Ã¶', 'o')
        .replaceAll('Ã§', 'c')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
