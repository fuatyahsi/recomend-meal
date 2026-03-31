import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ingredient.dart';
import '../models/kitchen_intelligence.dart';
import '../models/market_fiyati.dart';
import '../models/smart_actueller.dart';
import '../utils/market_registry.dart';
import '../utils/product_category.dart';

class MarketFiyatiSourceService {
  static const apiBaseUrl = 'https://api.marketfiyati.org.tr/api/v2';
  static const _mapApiBaseUrl =
      'https://harita.marketfiyati.org.tr/Service/api/v1';

  static const _defaultHeaders = {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    'Origin': 'https://marketfiyati.org.tr',
    'Referer': 'https://marketfiyati.org.tr/',
  };

  final http.Client _client;

  MarketFiyatiSourceService({http.Client? client})
      : _client = client ?? http.Client();

  Future<MarketFiyatiSearchResponse> searchByIdentity({
    required MarketFiyatiSession session,
    required String identity,
    required String keywords,
    int page = 0,
    int size = 1,
    String identityType = 'id',
  }) async {
    final payload = session.toIdentityPayload(
      identity: identity,
      keywords: keywords,
      page: page,
      size: size,
      identityType: identityType,
    );
    return _postSearch('searchByIdentity', payload);
  }

  Future<List<MarketFiyatiLocationSuggestion>> searchLocationSuggestions({
    required String words,
  }) async {
    final trimmedWords = words.trim();
    if (trimmedWords.isEmpty) {
      return const [];
    }

    final results = <String, MarketFiyatiLocationSuggestion>{};

    for (final variant in _buildLocationQueryVariants(trimmedWords)) {
      final suggestions = await _fetchLocationSuggestions(words: variant);
      for (final suggestion in suggestions) {
        final key =
            '${suggestion.displayLabel}|${suggestion.latitude}|${suggestion.longitude}';
        results.putIfAbsent(key, () => suggestion);
      }
      if (results.isNotEmpty) {
        break;
      }
    }

    return results.values.toList();
  }

  Future<List<MarketFiyatiNearestDepot>> fetchNearestDepots({
    required double latitude,
    required double longitude,
    int distance = 1,
  }) async {
    final uri = Uri.parse('$apiBaseUrl/nearest');
    final response = await _client
        .post(
          uri,
          headers: _defaultHeaders,
          body: json.encode({
            'latitude': latitude,
            'longitude': longitude,
            'distance': distance,
          }),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Market Fiyatı yakın market isteği başarısız oldu (${response.statusCode}).',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('Market Fiyatı yakın market yanıtı geçersiz.');
    }

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(MarketFiyatiNearestDepot.fromJson)
        .toList();
  }

  MarketFiyatiSession buildSessionFromNearest({
    String? locationLabel,
    required double latitude,
    required double longitude,
    required List<MarketFiyatiNearestDepot> depots,
    int distance = 5,
    int maxDepots = 24,
  }) {
    final depotIds = depots
        .map((depot) => depot.id)
        .where((id) => id.trim().isNotEmpty)
        .take(maxDepots)
        .toList();

    return MarketFiyatiSession(
      locationLabel: locationLabel,
      depots: depotIds,
      distance: distance,
      latitude: latitude,
      longitude: longitude,
    );
  }

  MarketFiyatiSession buildSessionFromSuggestion({
    required MarketFiyatiLocationSuggestion suggestion,
    required List<MarketFiyatiNearestDepot> depots,
    int distance = 5,
    int maxDepots = 24,
  }) {
    return buildSessionFromNearest(
      locationLabel: suggestion.displayLabel,
      latitude: suggestion.latitude,
      longitude: suggestion.longitude,
      depots: depots,
      distance: distance,
      maxDepots: maxDepots,
    );
  }

  Future<MarketFiyatiSearchResponse> searchByCategories({
    required MarketFiyatiSession session,
    required String keywords,
    int page = 0,
    int size = 24,
  }) async {
    final payload = session.toCategoryPayload(
      keywords: keywords,
      page: page,
      size: size,
    );
    return _postSearch('searchByCategories', payload);
  }

  Future<MarketFiyatiSearchResponse> searchSimilarProduct({
    required MarketFiyatiSession session,
    required String id,
    required String keywords,
    int page = 0,
    int size = 24,
  }) async {
    final payload = session.toSimilarProductPayload(
      id: id,
      keywords: keywords,
      page: page,
      size: size,
    );
    return _postSearch('searchSimilarProduct', payload);
  }

  List<ActuellerCatalogItem> toCatalogItems(
    MarketFiyatiSearchResponse response, {
    String sourceLabel = 'Market Fiyatı',
  }) {
    final items = <ActuellerCatalogItem>[];

    for (final product in response.content) {
      final category = categorizeProduct(
        [
          product.title,
          ...product.categories,
          product.mainCategory ?? '',
          product.menuCategory ?? '',
        ].join(' '),
      );

      for (final offer in product.offers) {
        final weight = product.refinedMeasure;
        final marketName = displayNameForMarket(offer.marketId);
        final title = [
          product.title.trim(),
          if (weight != null && weight.isNotEmpty) weight,
        ].join(' ');
        final rawBlock = '$title ${offer.price.toStringAsFixed(2)} TL';

        items.add(
          ActuellerCatalogItem(
            id: '${product.id}-${offer.depotId}',
            marketName: marketName.isEmpty ? offer.marketId : marketName,
            productTitle: title,
            price: offer.price,
            confidence: 0.99,
            rawBlock: rawBlock,
            sourceLabel: sourceLabel,
            category: category,
            brand: product.brand,
            weight: weight,
            sourceProductId: product.id,
            sourceDepotId: offer.depotId,
            sourceMenuCategory: product.menuCategory,
            sourceMainCategory: product.mainCategory,
          ),
        );
      }
    }

    return items;
  }

  List<RemoteMarketQuote> toRemoteQuotes(
    MarketFiyatiSearchResponse response, {
    required List<Ingredient> ingredients,
  }) {
    final quotes = <RemoteMarketQuote>[];

    for (final product in response.content) {
      final ingredientId = _matchIngredientId(
        product: product,
        ingredients: ingredients,
      );
      if (ingredientId == null) continue;

      for (final offer in product.offers) {
        quotes.add(
          RemoteMarketQuote(
            ingredientId: ingredientId,
            market: displayNameForMarket(offer.marketId),
            unitPrice: offer.price,
            isCampaign: offer.discount,
            campaignLabelTr: offer.discount
                ? 'Market Fiyatı fırsatı'
                : 'Market Fiyatı raf fiyatı',
            campaignLabelEn: offer.discount
                ? 'Market Fiyati deal'
                : 'Market Fiyati shelf price',
          ),
        );
      }
    }

    return quotes;
  }

  Future<MarketFiyatiSearchResponse> _postSearch(
    String endpoint,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse('$apiBaseUrl/$endpoint');
    final response = await _client
        .post(
          uri,
          headers: _defaultHeaders,
          body: json.encode(payload),
        )
        .timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Market Fiyatı isteği başarısız oldu (${response.statusCode}).',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Market Fiyatı yanıtı geçersiz.');
    }
    return MarketFiyatiSearchResponse.fromJson(decoded);
  }

  Future<List<MarketFiyatiLocationSuggestion>> _fetchLocationSuggestions({
    required String words,
  }) async {
    final uri = Uri.parse(
      '$_mapApiBaseUrl/AutoSuggestion/Search?words=${Uri.encodeQueryComponent(words)}',
    );
    final response = await _client.get(
      uri,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Origin': 'https://marketfiyati.org.tr',
        'Referer': 'https://marketfiyati.org.tr/',
      },
    ).timeout(const Duration(seconds: 20));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Market Fiyatı lokasyon araması başarısız oldu (${response.statusCode}).',
      );
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) {
      throw Exception('Market Fiyatı lokasyon arama yanıtı geçersiz.');
    }

    return decoded
        .whereType<List<dynamic>>()
        .map(MarketFiyatiLocationSuggestion.fromList)
        .toList();
  }

  List<String> _buildLocationQueryVariants(String rawQuery) {
    final trimmed = rawQuery.trim();
    final variants = <String>{trimmed};
    const replacements = {
      'c': 'ç',
      'g': 'ğ',
      'i': 'ı',
      'o': 'ö',
      's': 'ş',
      'u': 'ü',
    };

    for (final entry in replacements.entries) {
      final snapshot = variants.toList();
      for (final variant in snapshot) {
        if (variant.contains(entry.key)) {
          variants.add(variant.replaceAll(entry.key, entry.value));
        }
        final upperSource = entry.key.toUpperCase();
        final upperTarget = entry.value.toUpperCase();
        if (variant.contains(upperSource)) {
          variants.add(variant.replaceAll(upperSource, upperTarget));
        }
      }
    }

    return variants.take(16).toList();
  }

  String? _matchIngredientId({
    required MarketFiyatiProduct product,
    required List<Ingredient> ingredients,
  }) {
    final candidates = [
      product.title,
      product.brand ?? '',
      ...product.categories,
      product.mainCategory ?? '',
      product.menuCategory ?? '',
    ].where((value) => value.trim().isNotEmpty);

    final normalizedCandidate = _normalize(candidates.join(' '));
    for (final ingredient in ingredients) {
      final names = [
        ingredient.id,
        ingredient.nameTr,
        ingredient.nameEn,
      ].map(_normalize);
      if (names.any(
        (name) =>
            normalizedCandidate.contains(name) ||
            name.contains(normalizedCandidate),
      )) {
        return ingredient.id;
      }
    }
    return null;
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }
}
