// ignore_for_file: unnecessary_brace_in_string_interps

import 'dart:math' as math;

import '../models/ingredient.dart';
import '../models/kitchen_intelligence.dart';
import '../models/smart_actueller.dart';
import '../models/smart_kitchen.dart';
import '../utils/market_registry.dart';
import '../utils/product_category.dart';

class SmartActuellerService {
  static const _letterClass = r'A-Za-zĞğÜüŞşİıÖöÇç';
  static const _ignoredFlyerPhrases = {
    'aktuel',
    'aktuel urunler',
    'kampanya',
    'indirim',
    'firsat',
    'firsatlari',
    'stoklarla sinirlidir',
    'stoklarla sınırlıdır',
    'gecerli',
    'geçerli',
    'katalog',
    'brostur',
    'brosur',
    'sayfa',
    'hafta',
    'adet siniri',
  };

  static const _noiseTokens = {
    'adet',
    'adetle',
    'paket',
    'pkt',
    'kg',
    'g',
    'gr',
    'gram',
    'ml',
    'cl',
    'lt',
    'l',
    'x',
    'xl',
    'buyuk',
    'kucuk',
    'orta',
    'mini',
    'bonus',
    'hediye',
    'bedava',
    'net',
    'yuzde',
    'yuzdelik',
    'no',
    'kod',
  };

  static const _marketNames = [
    'A101',
    'BİM',
    'ŞOK',
    'Migros',
    'CarrefourSA',
    'Getir',
    'Yemeksepeti',
  ];

  static const _extraAliasesByIngredientId = {
    'olive': ['zeytin'],
    'black_olive': [
      'siyah zeytin',
      'sele zeytin',
      'gemlik zeytin',
      'zeytin siyah',
    ],
    'green_olive': ['yesil zeytin', 'kirma zeytin'],
    'egg': [
      'yumurta',
      'gezen tavuk yumurtasi',
      '10 lu yumurta',
      'yumurta 10 lu',
    ],
    'cheese_kashar': ['kasar', 'kasar peyniri', 'tost peyniri'],
    'cheese_white': ['beyaz peynir', 'inek peyniri'],
    'cream': ['krema', 'sef krema'],
    'olive_oil': ['zeytinyagi', 'sizma zeytinyagi'],
    'sunflower_oil': ['aycicek yagi', 'sivi yag'],
    'ground_beef': ['kiyma', 'dana kiyma'],
    'chicken_breast': ['tavuk gogsu', 'fileto tavuk'],
    'pasta': ['makarna', 'spagetti', 'burgu'],
    'white_bean': ['kuru fasulye'],
    'black_tea': ['cay', 'siyah cay'],
  };

  static const _referencePriceByCategory = {
    IngredientCategory.vegetables: 24.0,
    IngredientCategory.fruits: 22.0,
    IngredientCategory.meat: 89.0,
    IngredientCategory.dairy: 42.0,
    IngredientCategory.grains: 28.0,
    IngredientCategory.spices: 16.0,
    IngredientCategory.oils: 54.0,
    IngredientCategory.other: 24.0,
  };

  ActuellerScanResult analyzeFlyerText({
    required String rawText,
    required Iterable<Ingredient> ingredients,
    String? detectedStore,
    String sourceLabel = 'Kampanya Radarı',
    String? capturedImagePath,
    List<String> ocrBlocks = const [],
  }) {
    final aliases = _buildAliases(ingredients);
    final blocks = _buildCandidateBlocks(rawText, providedBlocks: ocrBlocks);
    final store = detectedStore ?? _detectStore(rawText);
    final catalogItems = <ActuellerCatalogItem>[];
    final catalogItemIds = <String>{};
    final deals = <ActuellerDeal>[];
    final dealIds = <String>{};
    final unmatchedBlocks = <String>[];
    var totalScore = 0.0;

    for (final block in blocks) {
      final prices = _extractPrices(block);
      if (prices.isEmpty) {
        continue;
      }

      final marketName = store ?? _detectStore(block) ?? 'Aktüel';
      final productTitle = _extractProductTitle(block);
      final discountPrice = prices.reduce(math.min);

      if (!_isPlausibleCatalogTitle(productTitle)) {
        unmatchedBlocks.add(block);
        continue;
      }

      final catalogItem = ActuellerCatalogItem(
        id: _buildCatalogItemId(
          marketName: marketName,
          productTitle: productTitle,
          price: discountPrice,
        ),
        marketName: marketName,
        productTitle: productTitle,
        price: discountPrice,
        confidence: 0.55,
        rawBlock: block,
        sourceLabel: sourceLabel,
        category: categorizeProduct(productTitle),
        brand: parseProductBrand(productTitle),
        weight: parseProductWeight(productTitle),
      );
      if (catalogItemIds.add(catalogItem.id)) {
        catalogItems.add(catalogItem);
      }

      final ingredientMatch = _findIngredientMatch(block, aliases);
      if (ingredientMatch == null) {
        unmatchedBlocks.add(block);
        continue;
      }

      final regularPrice = _selectRegularPrice(
        prices: prices,
        discountPrice: discountPrice,
      );
      if (!_isReasonablePrice(
        ingredientMatch.alias.ingredient,
        discountPrice,
      )) {
        unmatchedBlocks.add(block);
        continue;
      }
      final validUntil = _resolveValidUntil(block);
      final brand = _extractBrand(productTitle, ingredientMatch.alias.tokens);
      totalScore += ingredientMatch.score;

      final deal = ActuellerDeal(
        id: _buildDealId(
          ingredientId: ingredientMatch.alias.ingredient.id,
          marketName: marketName,
          discountPrice: discountPrice,
          validUntil: validUntil,
        ),
        ingredient: ingredientMatch.alias.ingredient,
        marketName: marketName,
        productTitle: productTitle,
        brand: brand,
        discountPrice: discountPrice,
        regularPrice: regularPrice,
        validUntil: validUntil,
        confidence: (ingredientMatch.score / 100).clamp(0.2, 0.98),
        rawBlock: block,
        sourceLabel: sourceLabel,
        fromImageOcr: capturedImagePath != null,
      );
      if (dealIds.add(deal.id)) {
        deals.add(deal);
      }
    }

    catalogItems.sort((a, b) {
      final marketCompare = a.marketName.compareTo(b.marketName);
      if (marketCompare != 0) return marketCompare;
      return a.productTitle.compareTo(b.productTitle);
    });

    deals.sort((a, b) {
      final priceCompare = a.discountPrice.compareTo(b.discountPrice);
      if (priceCompare != 0) return priceCompare;
      return a.ingredient.nameTr.compareTo(b.ingredient.nameTr);
    });

    final confidence = deals.isEmpty
        ? 0.0
        : ((deals.length / math.max(blocks.length, 1)) * 0.55 +
                (totalScore / (deals.length * 100)) * 0.45)
            .clamp(0.0, 1.0)
            .toDouble();

    return ActuellerScanResult(
      rawText: rawText,
      blocks: blocks,
      catalogItems: catalogItems,
      deals: deals,
      unmatchedBlocks: unmatchedBlocks,
      detectedStore: store,
      sourceLabel: sourceLabel,
      capturedImagePath: capturedImagePath,
      scannedAt: DateTime.now(),
      confidence: confidence,
    );
  }

  List<ActuellerSuggestion> buildPersonalizedSuggestions({
    required ActuellerScanResult scanResult,
    required Map<String, int> pantryCounts,
    required List<PantryRiskItem> pantryRiskItems,
    required List<SmartShoppingItem> shoppingItems,
    List<String> preferredMarkets = const [],
  }) {
    final riskByIngredient = {
      for (final item in pantryRiskItems) item.ingredient.id: item,
    };
    final normalizedPreferredMarkets =
        normalizeMarketIds(preferredMarkets).toSet();
    final shoppingByIngredient = {
      for (final item in shoppingItems) item.ingredient.id: item,
    };

    final suggestions = scanResult.deals.map((deal) {
      final pantryCount = pantryCounts[deal.ingredient.id] ?? 0;
      final riskItem = riskByIngredient[deal.ingredient.id];
      final shoppingItem = shoppingByIngredient[deal.ingredient.id];
      final neededCount = shoppingItem?.missingCount ?? 0;
      final dealMarketId = normalizeMarketId(deal.marketName);
      final displayMarketName = displayNameForMarket(deal.marketName);
      final isPreferredMarket = dealMarketId != null &&
          normalizedPreferredMarkets.contains(dealMarketId);

      var score = 0;
      if (neededCount > 0) score += 55 + math.min(neededCount * 6, 24);
      if (pantryCount == 0) {
        score += 12;
      } else if (pantryCount == 1) {
        score += 24;
      } else if (pantryCount == 2) {
        score += 12;
      }
      if (riskItem != null) {
        score += (riskItem.riskScore * 18).round();
      }
      if (deal.unitSavings >= 5) {
        score += math.min(deal.unitSavings.round(), 20);
      }
      if (isPreferredMarket) score += 8;
      if (deal.validUntil != null &&
          deal.validUntil!.difference(DateTime.now()).inDays <= 2) {
        score += 6;
      }

      final purchaseCount = _estimatePurchaseCount(
        neededCount: neededCount,
        pantryCount: pantryCount,
      );
      final hasRealSavings = deal.regularPrice != null && deal.regularPrice! > deal.discountPrice;
      final estimatedSavings = hasRealSavings
          ? (deal.regularPrice! - deal.discountPrice) * purchaseCount
          : 0.0;
      final recipeLabel = shoppingItem == null
          ? ''
          : shoppingItem.recipeNames.take(2).join(', ');
      final ingredientNameTr = deal.ingredient.nameTr;
      final ingredientNameEn = deal.ingredient.nameEn;
      final urgencyTr = neededCount > 0
          ? '$ingredientNameTr se\u00e7ili men\u00fclerin i\u00e7in eksik.'
          : pantryCount <= 1
              ? '$ingredientNameTr evde azalm\u0131\u015f g\u00f6r\u00fcn\u00fcyor.'
              : '$ingredientNameTr i\u00e7in g\u00fc\u00e7l\u00fc bir indirim yakaland\u0131.';
      final urgencyEn = neededCount > 0
          ? '$ingredientNameEn is missing for your planned menus.'
          : pantryCount <= 1
              ? '$ingredientNameEn looks low in your pantry.'
              : 'A strong discount was found for $ingredientNameEn.';
      final recipeNoteTr = recipeLabel.isEmpty
          ? ''
          : ' \u00d6zellikle $recipeLabel i\u00e7in i\u015fine yarar.';
      final recipeNoteEn =
          recipeLabel.isEmpty ? '' : ' It fits $recipeLabel especially well.';
      final savingsLabelTr = hasRealSavings && estimatedSavings >= 2
          ? ' Tahmini ${estimatedSavings.round()} TL tasarruf.'
          : '';
      final savingsLabelEn = hasRealSavings && estimatedSavings >= 2
          ? ' Estimated ${estimatedSavings.round()} TRY savings.'
          : '';
      final untilLabelTr = deal.validUntil == null
          ? ''
          : ' Son tarih: ${_formatDateTr(deal.validUntil!)}.';
      final untilLabelEn = deal.validUntil == null
          ? ''
          : ' Valid until ${_formatDateEn(deal.validUntil!)}.';

      return ActuellerSuggestion(
        deal: deal,
        score: score,
        pantryCount: pantryCount,
        neededCount: neededCount,
        relatedRecipes: shoppingItem?.recipeNames ?? const [],
        estimatedSavings: estimatedSavings.clamp(0, 9999).toDouble(),
        titleTr:
            '$displayMarketName - ${ingredientNameTr} ${deal.discountPrice.toStringAsFixed(2)} TL',
        titleEn:
            '$displayMarketName - $ingredientNameEn ${deal.discountPrice.toStringAsFixed(2)} TRY',
        bodyTr: '$urgencyTr$recipeNoteTr$savingsLabelTr$untilLabelTr',
        bodyEn: '$urgencyEn$recipeNoteEn$savingsLabelEn$untilLabelEn',
      );
    }).toList()
      ..sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        return b.estimatedSavings.compareTo(a.estimatedSavings);
      });

    return suggestions.take(6).toList();
  }

  double? _selectRegularPrice({
    required List<double> prices,
    required double discountPrice,
  }) {
    if (prices.length != 2) {
      return null;
    }

    final sorted = [...prices]..sort();
    final candidate = sorted.last;
    final ratio = candidate / math.max(discountPrice, 1);
    if (candidate <= discountPrice * 1.05) {
      return null;
    }
    if (ratio > 2.6) {
      return null;
    }
    return candidate;
  }

  DateTime? _resolveValidUntil(String source) {
    final detected = _detectValidUntil(source);
    if (detected == null) {
      return null;
    }

    final now = DateTime.now();
    final earliestAllowed = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 14));
    final latestAllowed =
        DateTime(now.year, now.month, now.day).add(const Duration(days: 45));

    if (detected.isBefore(earliestAllowed) || detected.isAfter(latestAllowed)) {
      return null;
    }
    return detected;
  }

  int _estimatePurchaseCount({
    required int neededCount,
    required int pantryCount,
  }) {
    if (neededCount > 0) {
      return neededCount.clamp(1, 4);
    }
    return pantryCount <= 1 ? 1 : 0;
  }

  List<RemoteMarketQuote> toRemoteQuotes(ActuellerScanResult scanResult) {
    return scanResult.deals
        .map(
          (deal) => RemoteMarketQuote(
            ingredientId: deal.ingredient.id,
            market: displayNameForMarket(deal.marketName),
            unitPrice: deal.discountPrice,
            isCampaign: true,
            campaignLabelTr: deal.validUntil == null
                ? 'Akt\u00fcel indirim'
                : 'Akt\u00fcel indirim - ${_formatDateTr(deal.validUntil!)}',
            campaignLabelEn: deal.validUntil == null
                ? 'Flyer deal'
                : 'Flyer deal • ${_formatDateEn(deal.validUntil!)}',
          ),
        )
        .toList();
  }

  double estimateReferencePrice(Ingredient ingredient) {
    return _referencePriceByCategory[ingredient.category] ?? 24.0;
  }

  bool _isReasonablePrice(Ingredient ingredient, double price) {
    final reference = estimateReferencePrice(ingredient);
    final maxMultiplier = switch (ingredient.category) {
      IngredientCategory.meat => 7.0,
      IngredientCategory.oils => 5.5,
      IngredientCategory.dairy => 5.0,
      IngredientCategory.grains => 6.0,
      IngredientCategory.spices => 4.0,
      IngredientCategory.vegetables => 5.0,
      IngredientCategory.fruits => 5.0,
      IngredientCategory.other => 5.0,
      _ => 5.0,
    };
    final minPrice = math.max(3.0, reference * 0.2);
    final maxPrice = reference * maxMultiplier;
    return price >= minPrice && price <= maxPrice;
  }

  List<String> _buildCandidateBlocks(
    String rawText, {
    List<String> providedBlocks = const [],
  }) {
    final compactProvidedBlocks = providedBlocks
        .map((block) => block.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((block) => block.isNotEmpty)
        .toList();
    if (compactProvidedBlocks.isNotEmpty) {
      return _buildCandidateBlocksFromLines(compactProvidedBlocks);
    }

    final lines = rawText
        .split(RegExp(r'[\n\r]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    return _buildCandidateBlocksFromLines(lines);
  }

  List<String> _buildCandidateBlocksFromLines(List<String> lines) {
    final candidateBlocks = <String>[];

    for (var i = 0; i < lines.length; i++) {
      if (!_containsPrice(lines[i])) continue;
      final currentLine = lines[i].replaceAll(RegExp(r'\s+'), ' ').trim();
      final normalizedCurrent = _normalize(currentLine);
      if (RegExp(r'[a-z]').hasMatch(normalizedCurrent)) {
        candidateBlocks.add(currentLine);
        continue;
      }

      final contextParts = <String>[];
      for (var j = math.max(0, i - 2); j <= i; j++) {
        if (j == i || !_containsPrice(lines[j])) {
          contextParts.add(lines[j]);
        }
      }
      final cleaned =
          contextParts.join(' ').replaceAll(RegExp(r'\s+'), ' ').trim();
      if (cleaned.isNotEmpty &&
          RegExp(r'[a-z]').hasMatch(_normalize(cleaned))) {
        candidateBlocks.add(cleaned);
      }
    }

    if (candidateBlocks.isNotEmpty) {
      return candidateBlocks.toSet().toList();
    }

    return lines
        .map((line) => line.replaceAll(RegExp(r'\s+'), ' ').trim())
        .where((line) => line.isNotEmpty)
        .toSet()
        .toList();
  }

  List<double> _extractPrices(String block) {
    final sanitized = block
        .replaceAll(RegExp(r'\b\d{1,2}[./-]\d{1,2}(?:[./-]\d{2,4})?\b'), ' ')
        .replaceAll(RegExp(r'\b20\d{2}\b'), ' ');
    final prices = <double>[];

    final explicitCurrencyMatches = RegExp(
      '(?<![0-9$_letterClass])(\\d{1,3}(?:\\.\\d{3})+(?:,\\d{2})?|\\d{1,5},\\d{2}|\\d{1,5})(?![0-9$_letterClass])\\s*(?:tl|₺)\\b',
      caseSensitive: false,
    ).allMatches(sanitized);
    for (final match in explicitCurrencyMatches) {
      final parsed = _parsePriceToken(match.group(1));
      if (parsed != null) {
        prices.add(parsed);
      }
    }

    final decimalMatches = RegExp(
      '(?<![0-9$_letterClass])(\\d{1,4},\\d{2})(?![0-9$_letterClass])',
      caseSensitive: false,
    ).allMatches(sanitized);
    for (final match in decimalMatches) {
      final parsed = _parsePriceToken(match.group(1));
      if (parsed != null) {
        prices.add(parsed);
      }
    }

    return prices.toSet().toList();
  }

  double? _parsePriceToken(String? raw) {
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final normalized = raw.replaceAll('.', '').replaceAll(',', '.');
    final value = double.tryParse(normalized);
    if (value == null) {
      return null;
    }
    if (value < 5 || value > 100000) {
      return null;
    }
    return value;
  }

  bool _isPlausibleCatalogTitle(String title) {
    final normalized = _normalize(title);
    if (normalized.isEmpty) {
      return false;
    }
    if (normalized.length < 3) {
      return false;
    }
    if (!_containsLetter(normalized)) {
      return false;
    }
    if (_ignoredFlyerPhrases.contains(normalized)) {
      return false;
    }
    return true;
  }

  bool _containsLetter(String value) {
    return RegExp(r'[a-z]').hasMatch(value);
  }

  String _buildCatalogItemId({
    required String marketName,
    required String productTitle,
    required double price,
  }) {
    return '${_normalize(marketName)}|${_normalize(productTitle)}|${price.toStringAsFixed(2)}';
  }

  _ActuellerMatch? _findIngredientMatch(
    String block,
    List<_ActuellerAlias> aliases,
  ) {
    final normalizedBlock = _normalize(block);
    final blockTokens = _tokenize(normalizedBlock);
    if (blockTokens.isEmpty) return null;

    _ActuellerMatch? best;
    for (final alias in aliases) {
      final score = _scoreAlias(
        normalizedBlock: normalizedBlock,
        blockTokens: blockTokens,
        alias: alias,
      );
      if (score < 36) continue;
      if (best == null || score > best.score) {
        best = _ActuellerMatch(alias: alias, score: score);
      }
    }
    return best;
  }

  double _scoreAlias({
    required String normalizedBlock,
    required Set<String> blockTokens,
    required _ActuellerAlias alias,
  }) {
    var score = 0.0;
    final compactBlock = normalizedBlock.replaceAll(' ', '');

    for (final phrase in alias.phrases) {
      final compactPhrase = phrase.replaceAll(' ', '');
      if (normalizedBlock.contains(phrase) && phrase.length >= 4) {
        score = math.max(score, 70 + (_tokenize(phrase).length * 5));
      } else if (compactPhrase.length >= 5 &&
          compactBlock.contains(compactPhrase)) {
        score = math.max(score, 62 + (_tokenize(phrase).length * 5));
      }
    }

    final overlap = blockTokens.intersection(alias.tokens);
    if (overlap.isNotEmpty) {
      score += overlap.length * 16;
      final longestToken = overlap.fold<int>(
        0,
        (current, token) => math.max(current, token.length),
      );
      score += (longestToken / 2).clamp(0, 9);
    }

    for (final aliasToken in alias.tokens.difference(overlap)) {
      var bestSimilarity = 0.0;
      for (final blockToken in blockTokens) {
        final similarity = _similarity(aliasToken, blockToken);
        if (similarity > bestSimilarity) {
          bestSimilarity = similarity;
        }
      }
      if (bestSimilarity >= 0.74) {
        score += 11 + (bestSimilarity * 8);
      }
    }

    if (blockTokens.length > 5 && overlap.length == 1) {
      score -= 4;
    }
    return score;
  }

  List<_ActuellerAlias> _buildAliases(Iterable<Ingredient> ingredients) {
    return ingredients.map((ingredient) {
      final phrases = <String>{
        _normalize(ingredient.id.replaceAll('_', ' ')),
        _normalize(ingredient.nameTr),
        _normalize(ingredient.nameEn),
        ...?_extraAliasesByIngredientId[ingredient.id]?.map(_normalize),
      }..removeWhere((phrase) {
          if (phrase.isEmpty) return true;
          return _ignoredFlyerPhrases.contains(phrase);
        });

      final tokens = <String>{};
      for (final phrase in phrases) {
        tokens.addAll(_tokenize(phrase));
      }

      return _ActuellerAlias(
        ingredient: ingredient,
        phrases: phrases.toList()..sort((a, b) => b.length.compareTo(a.length)),
        tokens: tokens,
      );
    }).toList();
  }

  String? _detectStore(String source) {
    final normalized = _normalize(source);
    if (normalized.contains('migros')) return 'Migros';
    if (normalized.contains('carrefoursa')) return 'CarrefourSA';
    if (normalized.contains('a101')) return 'A101';
    if (normalized.contains('bim')) return 'BIM';
    if (normalized.contains('sok') || normalized.contains('sok market')) {
      return 'SOK';
    }
    if (normalized.contains('getir')) return 'Getir';
    if (normalized.contains('yemeksepeti')) return 'Yemeksepeti';
    return null;
  }

  DateTime? _detectValidUntil(String source) {
    final match = RegExp(
      r'\b(\d{1,2})[./-](\d{1,2})(?:[./-](\d{2,4}))?\b',
    ).firstMatch(source);
    if (match == null) return null;
    final day = int.tryParse(match.group(1) ?? '');
    final month = int.tryParse(match.group(2) ?? '');
    final yearRaw = int.tryParse(match.group(3) ?? '');
    if (day == null || month == null) return null;
    final now = DateTime.now();
    final year =
        yearRaw == null ? now.year : (yearRaw < 100 ? 2000 + yearRaw : yearRaw);
    return DateTime(year, month, day);
  }

  String _extractProductTitle(String block) {
    final withoutDates = block.replaceAll(
      RegExp(r'\b\d{1,2}[./-]\d{1,2}(?:[./-]\d{2,4})?\b'),
      ' ',
    );
    final withoutPrices = withoutDates
        .replaceAll(
          RegExp(
            '(?<![0-9$_letterClass])\\d{1,3}(?:\\.\\d{3})+(?:,\\d{2})?(?![0-9$_letterClass])\\s*(?:tl|₺)\\b|(?<![0-9$_letterClass])\\d{1,5},\\d{2}(?![0-9$_letterClass])\\s*(?:tl|₺)\\b|(?<![0-9$_letterClass])\\d{1,5}(?![0-9$_letterClass])\\s*(?:tl|₺)\\b',
            caseSensitive: false,
          ),
          ' ',
        )
        .replaceAll(
          RegExp(
            '(?<![0-9$_letterClass])\\d{1,4},\\d{2}(?![0-9$_letterClass])',
          ),
          ' ',
        );
    final compact = withoutPrices.replaceAll(RegExp(r'\s+'), ' ').trim();
    final cleaned = compact.isEmpty ? block.trim() : compact;
    return _cleanProductTitleArtifacts(cleaned);
  }

  String _cleanProductTitleArtifacts(String title) {
    var cleaned = title.replaceAll(RegExp(r'\s+'), ' ').trim();

    while (true) {
      final previous = cleaned;
      cleaned = cleaned.replaceAll(RegExp(r'[\s,;/:-]+$'), '').trim();

      if (!_endsWithValidMeasure(cleaned)) {
        cleaned = cleaned
            .replaceAll(
              RegExp(
                r'\s+(?:(?:g|gr|gram|kg|ml|cl|cc|cm|mm|lt|l)\s*/\s*){1,6}(?:g|gr|gram|kg|ml|cl|cc|cm|mm|lt|l)\s*$',
                caseSensitive: false,
              ),
              '',
            )
            .trim()
            .replaceAll(
              RegExp(
                r'\s+(?:x|×)\s+(?:g|gr|gram|kg|ml|cl|cc|cm|mm|lt|l)\s*$',
                caseSensitive: false,
              ),
              '',
            )
            .trim()
            .replaceAll(
              RegExp(
                r'\s+(?:g|gr|gram|kg|ml|cl|cc|cm|mm|lt|l)\s*$',
                caseSensitive: false,
              ),
              '',
            )
            .trim();
      }

      if (!_endsWithValidCountSuffix(cleaned)) {
        cleaned = cleaned
            .replaceAll(
              RegExp(r"\s+['’]?(?:li|lı|lu|lü)\s*$", caseSensitive: false),
              '',
            )
            .trim();
      }

      cleaned = cleaned.replaceAll(RegExp(r'\s+(?:x|×)\s*$'), '').trim();
      cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

      if (cleaned == previous) {
        break;
      }
    }

    cleaned = _removeStandaloneCountSuffixTokens(cleaned);
    return cleaned.isEmpty
        ? title.replaceAll(RegExp(r'\s+'), ' ').trim()
        : cleaned;
  }

  String _removeStandaloneCountSuffixTokens(String value) {
    final parts = value.split(RegExp(r'\s+')).where((part) => part.isNotEmpty);
    final cleanedParts = <String>[];

    for (final part in parts) {
      final isStandaloneSuffix = RegExp(
        r"^['’]?(?:li|lı|lu|lü)$",
        caseSensitive: false,
      ).hasMatch(part);
      final previous = cleanedParts.isEmpty ? '' : cleanedParts.last;
      if (isStandaloneSuffix && !RegExp(r'\d$').hasMatch(previous)) {
        continue;
      }
      cleanedParts.add(part);
    }

    return cleanedParts.join(' ').trim();
  }

  bool _endsWithValidMeasure(String value) {
    return RegExp(
      r'(?:\d+(?:[.,]\d+)?(?:\s*[x×]\s*\d+(?:[.,]\d+)?){0,3})\s*(?:g|gr|gram|kg|ml|cl|cc|cm|mm|lt|l)\b$',
      caseSensitive: false,
    ).hasMatch(value);
  }

  bool _endsWithValidCountSuffix(String value) {
    return RegExp(
      r"\b\d+\s*['’]?(?:li|lı|lu|lü)\b$",
      caseSensitive: false,
    ).hasMatch(value);
  }

  String? _extractBrand(String productTitle, Set<String> ingredientTokens) {
    final rawTokens = productTitle
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toList();
    for (final token in rawTokens) {
      final normalized = _normalize(token);
      if (normalized.length < 3) continue;
      if (_noiseTokens.contains(normalized)) continue;
      if (ingredientTokens.contains(normalized)) continue;
      if (_marketNames.map(_normalize).contains(normalized)) continue;
      return token;
    }
    return null;
  }

  String _buildDealId({
    required String ingredientId,
    required String marketName,
    required double discountPrice,
    required DateTime? validUntil,
  }) {
    final dateKey = validUntil == null
        ? 'open'
        : '${validUntil.year}-${validUntil.month}-${validUntil.day}';
    return '${_normalize(marketName)}-$ingredientId-${discountPrice.toStringAsFixed(2)}-$dateKey';
  }

  bool _containsPrice(String line) {
    return RegExp(r'\d').hasMatch(line) &&
        (line.contains('TL') ||
            line.contains('tl') ||
            line.contains('₺') ||
            RegExp(r'\d+[.,]\d{2}').hasMatch(line));
  }

  Set<String> _tokenize(String input) {
    return input
        .split(' ')
        .map(_stemToken)
        .where((token) => token.length >= 2 && !_noiseTokens.contains(token))
        .toSet();
  }

  String _stemToken(String token) {
    var value = token.trim();
    if (value.length <= 4) return value;
    const suffixes = [
      'leri',
      'lari',
      'lerin',
      'larin',
      'lik',
      'luk',
      'dan',
      'den',
      'nin',
      'li',
      'lu',
      'si',
      'su',
      'yi',
      'yu',
      'i',
      'u',
    ];
    for (final suffix in suffixes) {
      if (value.endsWith(suffix) && value.length - suffix.length >= 4) {
        value = value.substring(0, value.length - suffix.length);
        break;
      }
    }
    return value;
  }

  double _similarity(String left, String right) {
    if (left == right) return 1;
    if (left.length < 2 || right.length < 2) return 0;
    if (left.contains(right) || right.contains(left)) {
      final shorter = math.min(left.length, right.length);
      final longer = math.max(left.length, right.length);
      if (shorter >= 3) return shorter / longer;
    }
    final distance = _levenshtein(left, right);
    final longest = math.max(left.length, right.length);
    return 1 - (distance / longest);
  }

  int _levenshtein(String left, String right) {
    if (left.isEmpty) return right.length;
    if (right.isEmpty) return left.length;
    var previous = List<int>.generate(right.length + 1, (index) => index);
    for (var i = 0; i < left.length; i++) {
      final current = List<int>.filled(right.length + 1, 0);
      current[0] = i + 1;
      for (var j = 0; j < right.length; j++) {
        final cost = left[i] == right[j] ? 0 : 1;
        current[j + 1] = math.min(
          math.min(previous[j + 1] + 1, current[j] + 1),
          previous[j] + cost,
        );
      }
      previous = current;
    }
    return previous.last;
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
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _formatDateTr(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day.$month.${date.year}';
  }

  String _formatDateEn(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$month/$day/${date.year}';
  }
}

class _ActuellerAlias {
  final Ingredient ingredient;
  final List<String> phrases;
  final Set<String> tokens;

  const _ActuellerAlias({
    required this.ingredient,
    required this.phrases,
    required this.tokens,
  });
}

class _ActuellerMatch {
  final _ActuellerAlias alias;
  final double score;

  const _ActuellerMatch({
    required this.alias,
    required this.score,
  });
}
