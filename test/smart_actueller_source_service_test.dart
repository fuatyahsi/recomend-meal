import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_chef/services/smart_actueller_source_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('SmartActuellerSourceService', () {
    test('discovers the first current brochure per market from Akakce', () async {
      final client = MockClient((request) async {
        if (request.url.toString() ==
            SmartActuellerSourceService.akakceListingUrl) {
          return http.Response.bytes(
            utf8.encode('''
            <html>
              <body>
                <a href="/brosurler/bim-21-mart-2026-aktuel-111">BIM</a>
                <a href="/brosurler/bim-18-mart-2026-aktuel-110">BIM eski</a>
                <a href="/brosurler/a101-21-mart-2026-aktuel-222">A101</a>
                <a href="/brosurler/esenlik-21-mart-2026-aktuel-333">Esenlik</a>
              </body>
            </html>
            '''),
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        }
        return http.Response('Not found', 404);
      });

      final service = SmartActuellerSourceService(client: client);
      final urls = await service.discoverBrochureUrls();

      expect(
        urls,
        equals([
          'https://www.akakce.com/brosurler/bim-21-mart-2026-aktuel-111',
          'https://www.akakce.com/brosurler/a101-21-mart-2026-aktuel-222',
          'https://www.akakce.com/brosurler/esenlik-21-mart-2026-aktuel-333',
        ]),
      );
    });

    test('extracts Akakce brochure images from page html', () async {
      final client = MockClient((request) async {
        if (request.url.host == 'www.akakce.com') {
          return http.Response.bytes(
            utf8.encode('''
            <html>
              <head>
                <title>BIM 21 Mart 2026 Aktüel Kataloğu</title>
                <meta property="og:image" content="https://cdn.akakce.com/_bro/u/111/222/222_000001.jpg" />
              </head>
              <body>
                <img src="https://cdn.akakce.com/_bro/u/111/222/222_000001.jpg" />
                <img src="//cdn.akakce.com/_bro/u/111/222/222_000002.jpg" />
              </body>
            </html>
            '''),
            200,
            headers: {'content-type': 'text/html; charset=utf-8'},
          );
        }
        return http.Response.bytes(<int>[1, 2, 3, 4], 200);
      });

      final service = SmartActuellerSourceService(client: client);
      final result = await service.prepareSource(
        'https://www.akakce.com/brosurler/bim-21-mart-2026',
      );

      expect(result.detectedStore, 'BIM');
      expect(result.imageUrls.length, 2);
      expect(result.localImagePaths.length, 2);
      expect(File(result.localImagePaths.first).existsSync(), isTrue);

      for (final path in result.localImagePaths) {
        final file = File(path);
        if (file.existsSync()) {
          file.deleteSync();
        }
      }
    });

    test('accepts direct brochure image urls', () async {
      final client = MockClient((request) async {
        return http.Response.bytes(<int>[9, 8, 7, 6], 200);
      });

      final service = SmartActuellerSourceService(client: client);
      final result = await service.prepareSource(
        'https://cdn.akakce.com/_bro/u/3267/55790/55790_461152.jpg',
      );

      expect(result.imageUrls, hasLength(1));
      expect(result.localImagePaths, hasLength(1));
      expect(
        result.localImagePaths.first.toLowerCase().endsWith('.jpg'),
        isTrue,
      );

      final file = File(result.localImagePaths.first);
      if (file.existsSync()) {
        file.deleteSync();
      }
    });
  });
}
