import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/ingredient.dart';
import '../models/kitchen_intelligence.dart';

class MarketWatchService {
  final http.Client _client;

  MarketWatchService({http.Client? client}) : _client = client ?? http.Client();

  Future<MarketFeedSnapshot> fetchFeed({
    required String feedUrl,
    required List<Ingredient> ingredients,
  }) async {
    final uri = Uri.parse(feedUrl);
    final response = await _client.get(uri);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Market feed request failed with ${response.statusCode}');
    }

    final decoded = json.decode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Market feed format is invalid');
    }

    final sourceLabel = decoded['sourceLabel']?.toString() ??
        decoded['source']?.toString() ??
        uri.host;
    final fetchedAt =
        DateTime.tryParse(decoded['updatedAt']?.toString() ?? '') ??
            DateTime.now();
    final quotes = <RemoteMarketQuote>[];

    final rootItems = decoded['items'];
    if (rootItems is List) {
      for (final item in rootItems) {
        final quote = _parseQuote(item, ingredients);
        if (quote != null) {
          quotes.add(quote);
        }
      }
    }

    final marketGroups = decoded['markets'];
    if (marketGroups is List) {
      for (final group in marketGroups) {
        if (group is! Map<String, dynamic>) continue;
        final market = group['market']?.toString() ?? group['name']?.toString();
        final items = group['items'];
        if (market == null || items is! List) continue;
        for (final item in items) {
          final quote = _parseQuote(
            item,
            ingredients,
            fallbackMarket: market,
          );
          if (quote != null) {
            quotes.add(quote);
          }
        }
      }
    }

    return MarketFeedSnapshot(
      sourceLabel: sourceLabel,
      fetchedAt: fetchedAt,
      quotes: quotes,
    );
  }

  RemoteMarketQuote? _parseQuote(
    dynamic raw,
    List<Ingredient> ingredients, {
    String? fallbackMarket,
  }) {
    if (raw is! Map<String, dynamic>) return null;

    final market =
        raw['market']?.toString() ?? fallbackMarket ?? raw['store']?.toString();
    final unitPrice = (raw['unitPrice'] as num?)?.toDouble() ??
        (raw['price'] as num?)?.toDouble();
    if (market == null || unitPrice == null) return null;

    final ingredientId = _matchIngredientId(
      raw: raw,
      ingredients: ingredients,
    );
    if (ingredientId == null) return null;

    final isCampaign = raw['isCampaign'] as bool? ??
        raw['campaign'] as bool? ??
        raw['discounted'] as bool? ??
        false;

    return RemoteMarketQuote(
      ingredientId: ingredientId,
      market: market,
      unitPrice: unitPrice,
      isCampaign: isCampaign,
      campaignLabelTr: raw['campaignLabelTr']?.toString() ??
          (isCampaign ? 'Canli kampanya' : 'Canli raf fiyati'),
      campaignLabelEn: raw['campaignLabelEn']?.toString() ??
          (isCampaign ? 'Live campaign' : 'Live shelf price'),
    );
  }

  String? _matchIngredientId({
    required Map<String, dynamic> raw,
    required List<Ingredient> ingredients,
  }) {
    final directId = raw['ingredientId']?.toString();
    if (directId != null &&
        ingredients.any((ingredient) => ingredient.id == directId)) {
      return directId;
    }

    final candidates = [
      raw['ingredient'],
      raw['name'],
      raw['nameTr'],
      raw['nameEn'],
      raw['productName'],
    ].whereType<String>().toList();

    for (final candidate in candidates) {
      final normalizedCandidate = _normalize(candidate);
      for (final ingredient in ingredients) {
        final normalizedNames = [
          ingredient.id,
          ingredient.nameTr,
          ingredient.nameEn,
        ].map(_normalize);
        if (normalizedNames.any(
          (name) =>
              normalizedCandidate.contains(name) ||
              name.contains(normalizedCandidate),
        )) {
          return ingredient.id;
        }
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
        .trim();
  }
}
