import 'dart:math' as math;

import '../models/ingredient.dart';
import '../models/kitchen_intelligence.dart';
import '../models/recipe.dart';
import '../models/smart_kitchen.dart';
import '../utils/market_registry.dart';
import '../utils/mood_recipes.dart';

class KitchenIntelligenceService {
  static const _receiptIgnoredPhrases = [
    'toplam',
    'ara toplam',
    'genel toplam',
    'kdv',
    'tarih',
    'saat',
    'fis no',
    'fatura no',
    'kasa',
    'kasiyer',
    'nakit',
    'kart',
    'visa',
    'mastercard',
    'temassiz',
    'odeme',
    'para ustu',
    'tesekkur',
    'tesekkurler',
    'tic a s',
    'ticaret',
    'san ve tic',
    'www',
    'tel',
    'magaza',
    'sube',
    'adres',
    'provizyon',
    'slip',
    'onay',
    'iade',
    'satis',
    'pos',
    'z no',
    'fiş',
    'fis',
    'no:',
  ];

  static const _receiptNoiseWords = {
    'adet',
    'ad',
    'kg',
    'gr',
    'g',
    'gram',
    'ml',
    'cl',
    'lt',
    'l',
    'paket',
    'pkt',
    'pk',
    'x',
    'xl',
    'm',
    's',
    'buyuk',
    'kucuk',
    'orta',
    'organik',
    'kampanya',
    'indirim',
    'net',
    'brut',
    'yuzde',
    'yagli',
    'tam',
    'yarim',
    'az',
    'lu',
    'li',
  };

  static const _receiptAliasesByIngredientId = {
    'egg': ['yumurta', 'yumrta', '10 lu yumurta', '15 li yumurta'],
    'tomato': ['domates', 'salkim domates', 'ceri domates'],
    'onion': ['sogan', 'kuru sogan'],
    'garlic': ['sarimsak'],
    'potato': ['patates'],
    'cucumber': ['salatalik'],
    'pepper_green': ['yesil biber', 'sivri biber'],
    'red_pepper': ['kirmizi biber'],
    'capia_pepper': ['kapya biber'],
    'milk': ['sut'],
    'yogurt': ['yogurt'],
    'cheese_white': ['beyaz peynir', 'peynir'],
    'cheese_kashar': ['kasar', 'kasar peyniri', 'tost peyniri'],
    'cream_cheese': ['krem peynir'],
    'butter': ['tereyagi'],
    'cream': ['krema'],
    'olive_oil': [
      'zeytinyagi',
      'zeytin yagi',
      'zeytnyagi',
      'zeytinyag',
      'sizma zeytinyagi',
    ],
    'sunflower_oil': ['aycicek yagi', 'aycicek yag'],
    'tomato_paste': ['salca', 'domates salcasi', 'biber salcasi'],
    'rice': ['pirinc', 'baldo pirinc'],
    'bulgur': ['bulgur'],
    'pasta': ['makarna', 'spagetti', 'burgu makarna'],
    'bread': ['ekmek', 'somun', 'baget'],
    'flour': ['un'],
    'lentil_red': ['kirmizi mercimek'],
    'lentil_green': ['yesil mercimek'],
    'chickpea': ['nohut'],
    'white_bean': ['kuru fasulye'],
    'black_pepper': ['karabiber'],
    'red_pepper_flakes': ['pul biber'],
    'parsley': ['maydanoz'],
    'dill': ['dereotu'],
    'mint_dried': ['kuru nane'],
    'oregano': ['kekik'],
    'chicken': ['tavuk'],
    'chicken_breast': [
      'tavuk gogsu',
      'tavk gogsu',
      'tavuk fileto',
    ],
    'ground_beef': ['kiyma', 'dana kiyma'],
    'beef_cubes': ['kusbasi', 'dana kusbasi'],
    'fish': ['balik'],
    'salmon': ['somon'],
    'tuna': ['ton baligi'],
    'olive': ['zeytin'],
    'lemon': ['limon'],
    'apple': ['elma'],
    'banana': ['muz'],
    'strawberry': ['cilek'],
    'walnut': ['ceviz'],
    'honey': ['bal'],
    'sugar': ['seker'],
    'tea': ['cay', 'siyah cay'],
  };

  static const markets = [
    'a101',
    'bim',
    'sok',
    'migros',
    'carrefoursa',
    'getir',
    'yemeksepeti',
  ];

  static const _marketMultipliers = {
    'a101': 0.90,
    'bim': 0.89,
    'sok': 0.93,
    'migros': 1.05,
    'carrefoursa': 1.03,
    'getir': 1.13,
    'yemeksepeti': 1.16,
  };

  static const _baseShelfLifeByCategory = {
    IngredientCategory.vegetables: 5,
    IngredientCategory.fruits: 6,
    IngredientCategory.meat: 3,
    IngredientCategory.dairy: 5,
    IngredientCategory.grains: 35,
    IngredientCategory.spices: 120,
    IngredientCategory.oils: 60,
    IngredientCategory.other: 12,
  };

  static const _baseValueByCategory = {
    IngredientCategory.vegetables: 18.0,
    IngredientCategory.fruits: 16.0,
    IngredientCategory.meat: 55.0,
    IngredientCategory.dairy: 24.0,
    IngredientCategory.grains: 20.0,
    IngredientCategory.spices: 10.0,
    IngredientCategory.oils: 22.0,
    IngredientCategory.other: 14.0,
  };

  static const _pairingRules = [
    (
      ['salmon', 'capers', 'dill'],
      'Somon, kapari ve dereotu birlikte imza tabak verir.',
      'Salmon, capers, and dill make a strong signature plate.',
      94,
    ),
    (
      ['tomato', 'olive_oil', 'basil'],
      'Domates, zeytinyagi ve feslegen her zaman temiz bir eslesme verir.',
      'Tomato, olive oil, and basil always land as a clean match.',
      91,
    ),
    (
      ['yogurt', 'mint_dried', 'cucumber'],
      'Yogurt, mint, and cucumber together create a cool rescue plate.',
      'Yogurt, mint, and cucumber together create a cool rescue plate.',
      88,
    ),
    (
      ['egg', 'cheese_white', 'parsley'],
      'Yumurta, beyaz peynir ve maydanoz kahvaltida cok guclu bir cekirdek.',
      'Egg, white cheese, and parsley create a powerful breakfast core.',
      86,
    ),
  ];

  List<PantryRiskItem> buildPantryRiskItems({
    required List<PantryStockItem> pantryItems,
    required Map<String, DateTime> updatedAtById,
    DateTime? now,
  }) {
    final safeNow = now ?? DateTime.now();
    final items = pantryItems.map((item) {
      final updatedAt = updatedAtById[item.ingredient.id] ?? safeNow;
      final ageDays = safeNow.difference(updatedAt).inDays;
      final shelfLifeDays = _shelfLifeDays(item.ingredient);
      final riskScore =
          ((ageDays + 1) / shelfLifeDays).clamp(0.08, 1.35).toDouble();
      final lossValue = estimateIngredientValue(item.ingredient, item.count) *
          riskScore.clamp(0.4, 1.0);
      return PantryRiskItem(
        ingredient: item.ingredient,
        count: item.count,
        lastUpdatedAt: updatedAt,
        ageDays: ageDays,
        shelfLifeDays: shelfLifeDays,
        riskScore: riskScore,
        estimatedLossValue: lossValue,
      );
    }).toList()
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));
    return items;
  }

  List<WasteRescueSuggestion> buildWasteRescueSuggestions({
    required List<PantryRiskItem> riskItems,
    required List<Recipe> recipes,
    required Set<String> availableIngredientIds,
  }) {
    final suggestions = <WasteRescueSuggestion>[];

    for (final item in riskItems.where((risk) => risk.riskScore >= 0.45)) {
      final candidateRecipes = recipes
          .where(
            (recipe) => recipe.ingredients.any(
              (ingredient) => ingredient.ingredientId == item.ingredient.id,
            ),
          )
          .toList()
        ..sort((a, b) {
          final aMissing = a
              .getMissingIngredients(availableIngredientIds.toList())
              .where((ingredient) => !ingredient.isOptional)
              .length;
          final bMissing = b
              .getMissingIngredients(availableIngredientIds.toList())
              .where((ingredient) => !ingredient.isOptional)
              .length;
          final missingCompare = aMissing.compareTo(bMissing);
          if (missingCompare != 0) return missingCompare;
          return a.totalTimeMinutes.compareTo(b.totalTimeMinutes);
        });

      final recipe = candidateRecipes.isEmpty ? null : candidateRecipes.first;
      final missingUnits = recipe == null
          ? 0
          : recipe
              .getMissingIngredients(availableIngredientIds.toList())
              .where((ingredient) => !ingredient.isOptional)
              .fold<int>(
                0,
                (sum, ingredient) => sum + ingredient.estimatedStockUnits,
              );

      final ingredientNameTr = item.ingredient.nameTr;
      final ingredientNameEn = item.ingredient.nameEn;
      final recipeNameTr = recipe?.nameTr ?? 'hizli bir kurtarma tarifi';
      final recipeNameEn = recipe?.nameEn ?? 'a quick rescue dish';

      suggestions.add(
        WasteRescueSuggestion(
          riskItem: item,
          rescueRecipe: recipe,
          missingUnits: missingUnits,
          titleTr: '$ingredientNameTr riskte',
          titleEn: '$ingredientNameEn is at risk',
          bodyTr: recipe == null
              ? '$ingredientNameTr yakinda bitebilir. Bugun bir menuye ekleyerek yaklasik ${item.estimatedLossValue.round()} TL koruyabilirsin.'
              : '$ingredientNameTr icin $recipeNameTr iyi bir kurtarma hamlesi. Yaklasik ${item.estimatedLossValue.round()} TL degeri koruyabilir.',
          bodyEn: recipe == null
              ? '$ingredientNameEn may expire soon. Use it today to protect about ${item.estimatedLossValue.round()} TRY.'
              : '$recipeNameEn is a good rescue move for $ingredientNameEn. It can protect about ${item.estimatedLossValue.round()} TRY.',
        ),
      );
    }

    return suggestions.take(4).toList();
  }

  List<MarketBasketComparison> buildMarketComparisons(
    List<SmartShoppingItem> items, {
    List<RemoteMarketQuote> remoteQuotes = const [],
    List<String>? preferredMarkets,
  }) {
    if (items.isEmpty) return const [];

    final availableMarkets =
        preferredMarkets != null && preferredMarkets.isNotEmpty
            ? normalizeMarketIds(preferredMarkets)
            : markets;

    final results = availableMarkets.map((marketId) {
      final displayMarket = displayNameForMarket(marketId);
      final deals = items.map((shoppingItem) {
        RemoteMarketQuote? liveQuote;
        for (final quote in remoteQuotes) {
          if (normalizeMarketId(quote.market) == marketId &&
              quote.ingredientId == shoppingItem.ingredient.id) {
            liveQuote = quote;
            break;
          }
        }
        final unitPrice = liveQuote?.unitPrice ??
            _unitPriceForMarket(shoppingItem.ingredient, marketId);
        final totalPrice = unitPrice * shoppingItem.missingCount;
        final isCampaign = liveQuote?.isCampaign ??
            (_stableHash('${shoppingItem.ingredient.id}-$marketId') % 5 == 0);
        return MarketItemDeal(
          shoppingItem: shoppingItem,
          market: displayMarket,
          unitPrice: unitPrice,
          totalPrice: isCampaign ? totalPrice * 0.88 : totalPrice,
          isCampaign: isCampaign,
          isLiveData: liveQuote != null,
          campaignLabelTr: liveQuote?.campaignLabelTr ??
              (isCampaign ? 'Haftanin kampanyasi' : 'Standart raf fiyati'),
          campaignLabelEn: liveQuote?.campaignLabelEn ??
              (isCampaign ? 'Weekly campaign' : 'Regular shelf price'),
        );
      }).toList();

      final totalPrice =
          deals.fold<double>(0, (sum, deal) => sum + deal.totalPrice);
      final hasLiveData = deals.any((deal) => deal.isLiveData);
      return MarketBasketComparison(
        market: displayMarket,
        deals: deals,
        totalPrice: totalPrice,
        campaignCount: deals.where((deal) => deal.isCampaign).length,
        estimatedSavingsVsHighest: 0,
        isLiveData: hasLiveData,
        sourceLabel: hasLiveData ? 'Live feed' : 'Estimated',
      );
    }).toList()
      ..sort((a, b) => a.totalPrice.compareTo(b.totalPrice));

    final highest = results.isEmpty ? 0 : results.last.totalPrice;
    return results
        .map(
          (comparison) => MarketBasketComparison(
            market: comparison.market,
            deals: comparison.deals,
            totalPrice: comparison.totalPrice,
            campaignCount: comparison.campaignCount,
            estimatedSavingsVsHighest: highest - comparison.totalPrice,
            isLiveData: comparison.isLiveData,
            sourceLabel: comparison.sourceLabel,
          ),
        )
        .toList();
  }

  ReceiptScanResult analyzeReceiptText(
    String rawText,
    Iterable<Ingredient> ingredients,
    String locale,
  ) {
    final lines = rawText
        .split(RegExp(r'[\n\r]+'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final matchedIngredients = <Ingredient>[];
    final unmatched = <String>[];
    final aliases = _buildReceiptAliases(ingredients);
    var processedLineCount = 0;
    var scoreTotal = 0.0;

    for (final line in lines) {
      final normalizedRawLine = _normalizeReceiptInput(line);
      if (_shouldIgnoreReceiptLine(normalizedRawLine)) {
        continue;
      }

      final cleanedLine = _cleanReceiptLine(line);
      final normalizedLine = _normalizeReceiptInput(cleanedLine);
      if (normalizedLine.isEmpty || _shouldIgnoreReceiptLine(normalizedLine)) {
        continue;
      }

      processedLineCount += 1;
      final match = _findBestReceiptMatch(normalizedLine, aliases);
      if (match == null) {
        unmatched.add(line);
        continue;
      }

      scoreTotal += match.score;
      if (!matchedIngredients.any(
        (item) => item.id == match.alias.ingredient.id,
      )) {
        matchedIngredients.add(match.alias.ingredient);
      }
    }

    final coverage = processedLineCount == 0
        ? 0.0
        : matchedIngredients.length / processedLineCount;
    final quality =
        processedLineCount == 0 ? 0.0 : scoreTotal / (processedLineCount * 100);
    final confidence =
        ((coverage * 0.55) + (quality * 0.45)).clamp(0, 1).toDouble();

    return ReceiptScanResult(
      matchedIngredients: matchedIngredients,
      unmatchedLines: unmatched,
      confidence: confidence.clamp(0, 1).toDouble(),
      rawText: rawText,
      detectedStore: _detectStore(rawText),
    );
  }

  PlateAnalysisResult analyzeDishPrompt(
    String prompt,
    List<Recipe> recipes,
    String locale,
  ) {
    final normalizedPrompt = _normalize(prompt);
    final scored = recipes.map((recipe) {
      var score = 0;
      if (normalizedPrompt.contains(_normalize(recipe.nameTr)) ||
          normalizedPrompt.contains(_normalize(recipe.nameEn))) {
        score += 12;
      }
      for (final tag in recipe.tags) {
        if (normalizedPrompt.contains(_normalize(tag))) {
          score += 6;
        }
      }
      for (final ingredient in recipe.ingredients) {
        if (normalizedPrompt.contains(_normalize(ingredient.ingredientId))) {
          score += 2;
        }
      }
      if (normalizedPrompt.contains(_normalize(recipe.category))) {
        score += 3;
      }
      return MapEntry(recipe, score);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final matchedRecipes = scored
        .where((entry) => entry.value > 0)
        .take(3)
        .map((entry) => entry.key)
        .toList();

    final detectedMoodId = _detectMoodId(normalizedPrompt, matchedRecipes);
    final leadRecipe = matchedRecipes.isEmpty ? null : matchedRecipes.first;
    final leadNameTr = leadRecipe?.nameTr ?? 'serbest tabak';
    final leadNameEn = leadRecipe?.nameEn ?? 'free-style plate';

    return PlateAnalysisResult(
      headlineTr: 'Muhtemel tabak: $leadNameTr',
      headlineEn: 'Likely dish: $leadNameEn',
      summaryTr: matchedRecipes.isEmpty
          ? 'Tabakta serbest yaraticilik var. Ruh haline gore hizli menu onerileri hazir.'
          : 'Bu tabak $leadNameTr cizgisine yakin. Benzer tarifleri hemen acabilirsin.',
      summaryEn: matchedRecipes.isEmpty
          ? 'This looks like a freestyle plate. Mood-driven menu ideas are ready.'
          : 'This plate is close to $leadNameEn. Similar recipes are ready to open.',
      suggestedMoodId: detectedMoodId,
      shareCaptionTr:
          'FridgeChef ile tabagimi analiz ettim. Siradaki deneme daha da iddiali geliyor.',
      shareCaptionEn:
          'I analyzed my plate with FridgeChef. The next round is going bigger.',
      matchedRecipes: matchedRecipes,
      estimatedCalories: _estimateCaloriesFromPrompt(prompt),
      analysisPrompt: prompt,
      confidence: matchedRecipes.isEmpty ? 0.32 : 0.72,
    );
  }

  List<DigitalTwinZone> buildDigitalTwin(List<PantryRiskItem> items) {
    final upperShelf = items
        .where(
          (item) =>
              item.ingredient.category == IngredientCategory.dairy ||
              item.ingredient.category == IngredientCategory.oils ||
              item.ingredient.category == IngredientCategory.spices,
        )
        .toList();
    final middleShelf = items
        .where(
          (item) =>
              item.ingredient.category == IngredientCategory.meat ||
              item.ingredient.category == IngredientCategory.grains ||
              item.ingredient.category == IngredientCategory.other,
        )
        .toList();
    final crisper = items
        .where(
          (item) =>
              item.ingredient.category == IngredientCategory.vegetables ||
              item.ingredient.category == IngredientCategory.fruits,
        )
        .toList();

    return [
      DigitalTwinZone(
        id: 'upper',
        labelTr: 'Ust raf',
        labelEn: 'Upper shelf',
        items: upperShelf,
      ),
      DigitalTwinZone(
        id: 'middle',
        labelTr: 'Orta raf',
        labelEn: 'Middle shelf',
        items: middleShelf,
      ),
      DigitalTwinZone(
        id: 'crisper',
        labelTr: 'Sebzelik',
        labelEn: 'Crisper',
        items: crisper,
      ),
    ];
  }

  List<FlavorPairSuggestion> buildFlavorPairings(
    Set<String> selectedIngredientIds,
  ) {
    final suggestions = <FlavorPairSuggestion>[];

    for (final rule in _pairingRules) {
      final ids = rule.$1;
      final matches = ids.where(selectedIngredientIds.contains).length;
      if (matches == 0) continue;

      final missing =
          ids.where((id) => !selectedIngredientIds.contains(id)).toList();
      final titleTr = missing.isEmpty
          ? 'Lezzet uyumu %${rule.$4}'
          : 'Bir adimda %${rule.$4} uyum';
      final titleEn = missing.isEmpty
          ? 'Flavor fit ${rule.$4}%'
          : 'One step away from ${rule.$4}% fit';

      final bodyTr = missing.isEmpty
          ? rule.$2
          : '${rule.$2} Eksik halka: ${missing.join(', ')}.';
      final bodyEn = missing.isEmpty
          ? rule.$3
          : '${rule.$3} Missing link: ${missing.join(', ')}.';

      suggestions.add(
        FlavorPairSuggestion(
          titleTr: titleTr,
          titleEn: titleEn,
          bodyTr: bodyTr,
          bodyEn: bodyEn,
          score: rule.$4,
        ),
      );
    }

    suggestions.sort((a, b) => b.score.compareTo(a.score));
    return suggestions.take(3).toList();
  }

  WeeklyMenuDigest buildWeeklyMenuDigest({
    required List<Recipe> breakfast,
    required List<Recipe> lunch,
    required List<Recipe> dinner,
    required String locale,
    String? moodId,
  }) {
    final recipes = [
      if (breakfast.isNotEmpty) breakfast.first,
      if (lunch.isNotEmpty) lunch.first,
      if (dinner.isNotEmpty) dinner.first,
    ];
    final mood = moodId == null ? null : MoodRecipeEngine.getMoodById(moodId);
    final moodLabelTr = mood?.nameTr ?? 'senin temposuna';
    final moodLabelEn = mood?.nameEn ?? 'your current rhythm';
    final recipeNamesTr = recipes.map((recipe) => recipe.nameTr).join(', ');
    final recipeNamesEn = recipes.map((recipe) => recipe.nameEn).join(', ');

    return WeeklyMenuDigest(
      titleTr: 'Pazar menun hazir',
      titleEn: 'Your Sunday menu is ready',
      bodyTr: recipes.isEmpty
          ? 'Mood ve dolap verine gore yeni hafta icin fikirler hazirliyorum.'
          : '$moodLabelTr gore secilen menu: $recipeNamesTr',
      bodyEn: recipes.isEmpty
          ? 'I am preparing next week ideas based on your mood and pantry.'
          : 'Picked for $moodLabelEn: $recipeNamesEn',
      recipes: recipes,
    );
  }

  double estimateIngredientValue(Ingredient ingredient, int units) {
    final base = _baseValueByCategory[ingredient.category] ?? 16;
    final variance = (_stableHash(ingredient.id) % 9).toDouble();
    return (base + variance) * units;
  }

  double _unitPriceForMarket(Ingredient ingredient, String market) {
    final multiplier = _marketMultipliers[market] ?? 1.0;
    final baseUnitValue = estimateIngredientValue(ingredient, 1);
    return ((baseUnitValue / 2.8) * multiplier).clamp(4, 120);
  }

  int _shelfLifeDays(Ingredient ingredient) {
    return _baseShelfLifeByCategory[ingredient.category] ?? 7;
  }

  String _detectMoodId(String normalizedPrompt, List<Recipe> matchedRecipes) {
    if (normalizedPrompt.contains('romantik') ||
        normalizedPrompt.contains('romantic')) {
      return 'romantic';
    }
    if (normalizedPrompt.contains('yorgun') ||
        normalizedPrompt.contains('tired')) {
      return 'tired';
    }
    if (normalizedPrompt.contains('misafir') ||
        normalizedPrompt.contains('guest')) {
      return 'party';
    }
    if (matchedRecipes.any((recipe) => recipe.totalTimeMinutes <= 15)) {
      return 'quick';
    }
    return 'comfort';
  }

  List<_ReceiptAlias> _buildReceiptAliases(Iterable<Ingredient> ingredients) {
    return ingredients.map((ingredient) {
      final phrases = <String>{
        _normalizeReceiptInput(ingredient.id.replaceAll('_', ' ')),
        _normalizeReceiptInput(ingredient.nameTr),
        _normalizeReceiptInput(ingredient.nameEn),
        ...?_receiptAliasesByIngredientId[ingredient.id]?.map(
          _normalizeReceiptInput,
        ),
      }..removeWhere((phrase) => phrase.isEmpty);

      final tokens = <String>{};
      for (final phrase in phrases) {
        tokens.addAll(_tokenizeReceiptText(phrase));
      }

      return _ReceiptAlias(
        ingredient: ingredient,
        phrases: phrases.toList()..sort((a, b) => b.length.compareTo(a.length)),
        tokens: tokens,
      );
    }).toList();
  }

  _ReceiptMatch? _findBestReceiptMatch(
    String normalizedLine,
    List<_ReceiptAlias> aliases,
  ) {
    final lineTokens = _tokenizeReceiptText(normalizedLine);
    if (lineTokens.isEmpty) {
      return null;
    }

    _ReceiptMatch? bestMatch;
    for (final alias in aliases) {
      final score = _scoreReceiptAlias(
        normalizedLine: normalizedLine,
        lineTokens: lineTokens,
        alias: alias,
      );
      if (score < 38) {
        continue;
      }
      if (bestMatch == null || score > bestMatch.score) {
        bestMatch = _ReceiptMatch(alias: alias, score: score);
      }
    }

    return bestMatch;
  }

  double _scoreReceiptAlias({
    required String normalizedLine,
    required Set<String> lineTokens,
    required _ReceiptAlias alias,
  }) {
    var score = 0.0;
    final compactLine = normalizedLine.replaceAll(' ', '');

    for (final phrase in alias.phrases) {
      if (phrase.isEmpty) {
        continue;
      }
      final compactPhrase = phrase.replaceAll(' ', '');
      if (normalizedLine == phrase) {
        score = score < 100 ? 100 : score;
      } else if (normalizedLine.contains(phrase) && phrase.length >= 4) {
        final phraseTokenCount = _tokenizeReceiptText(phrase).length;
        final phraseScore = 68 + (phraseTokenCount * 6);
        if (phraseScore > score) {
          score = phraseScore.toDouble();
        }
      } else if (compactPhrase.length >= 5 &&
          compactLine.contains(compactPhrase)) {
        final phraseTokenCount = _tokenizeReceiptText(phrase).length;
        final phraseScore = 62 + (phraseTokenCount * 5);
        if (phraseScore > score) {
          score = phraseScore.toDouble();
        }
      }
    }

    final overlap = lineTokens.intersection(alias.tokens);
    if (overlap.isNotEmpty) {
      score += overlap.length * 17;
      final longestTokenLength = overlap.fold<int>(
        0,
        (max, token) => token.length > max ? token.length : max,
      );
      score += (longestTokenLength / 2).clamp(0, 10);
    }

    var fuzzyTokenMatches = 0;
    var fuzzySimilarityTotal = 0.0;
    for (final aliasToken in alias.tokens.difference(overlap)) {
      var bestSimilarity = 0.0;
      for (final lineToken in lineTokens) {
        final similarity = _calculateTokenSimilarity(aliasToken, lineToken);
        if (similarity > bestSimilarity) {
          bestSimilarity = similarity;
        }
      }
      if (bestSimilarity >= 0.72) {
        fuzzyTokenMatches += 1;
        fuzzySimilarityTotal += bestSimilarity;
      }
    }

    if (fuzzyTokenMatches > 0) {
      score += fuzzyTokenMatches * 11;
      score += fuzzySimilarityTotal * 9;
    }

    for (final phrase in alias.phrases) {
      final phraseTokens = _tokenizeReceiptText(phrase);
      final coveredPhraseTokens = phraseTokens.where((token) {
        if (lineTokens.contains(token)) {
          return true;
        }
        return lineTokens.any(
          (lineToken) => _calculateTokenSimilarity(token, lineToken) >= 0.8,
        );
      });
      if (phraseTokens.isNotEmpty &&
          coveredPhraseTokens.length == phraseTokens.length) {
        score += 22;
        break;
      }
    }

    if (lineTokens.length > 4 && overlap.length == 1) {
      score -= 6;
    }
    if (overlap.length == 1 && overlap.first.length <= 3) {
      score -= 12;
    }

    return score;
  }

  double _calculateTokenSimilarity(String left, String right) {
    if (left == right) {
      return 1;
    }
    if (left.length < 2 || right.length < 2) {
      return 0;
    }
    if (left.contains(right) || right.contains(left)) {
      final shorterLength = math.min(left.length, right.length);
      final longerLength = math.max(left.length, right.length);
      if (shorterLength >= 3) {
        return shorterLength / longerLength;
      }
    }

    final distance = _levenshteinDistance(left, right);
    final longestLength = math.max(left.length, right.length);
    return 1 - (distance / longestLength);
  }

  int _levenshteinDistance(String left, String right) {
    if (left.isEmpty) {
      return right.length;
    }
    if (right.isEmpty) {
      return left.length;
    }

    var previous = List<int>.generate(right.length + 1, (index) => index);

    for (var i = 0; i < left.length; i++) {
      final current = List<int>.filled(right.length + 1, 0);
      current[0] = i + 1;

      for (var j = 0; j < right.length; j++) {
        final cost = left[i] == right[j] ? 0 : 1;
        final deletion = previous[j + 1] + 1;
        final insertion = current[j] + 1;
        final substitution = previous[j] + cost;
        current[j + 1] = math.min(
          math.min(deletion, insertion),
          substitution,
        );
      }

      previous = current;
    }

    return previous.last;
  }

  String _cleanReceiptLine(String line) {
    var cleaned = _normalizeReceiptInput(line);
    cleaned = cleaned.replaceAll(RegExp(r'\b\d+[.,]\d{2}\b'), ' ');
    cleaned = cleaned.replaceAll(
      RegExp(r'\b\d+\s*(adet|ad|kg|gr|g|gram|ml|cl|lt|l|paket|pkt|pk|x)\b'),
      ' ',
    );
    cleaned = cleaned.replaceAll(RegExp(r'\b\d+\b'), ' ');
    cleaned = cleaned.replaceAll(RegExp(r'[%*#/_+=]+'), ' ');

    final filteredTokens = _tokenizeReceiptText(cleaned)
        .where((token) => !_receiptNoiseWords.contains(token))
        .toList();
    return filteredTokens.join(' ');
  }

  bool _shouldIgnoreReceiptLine(String normalizedLine) {
    if (normalizedLine.isEmpty) {
      return true;
    }
    final tokens = _tokenizeReceiptText(normalizedLine);
    if (tokens.isEmpty) {
      return true;
    }
    final meaningfulTokens = tokens
        .where(
          (token) =>
              !_receiptNoiseWords.contains(token) &&
              !RegExp(r'^\d+$').hasMatch(token),
        )
        .toList();
    if (meaningfulTokens.isEmpty) {
      return true;
    }
    final containsIgnoredPhrase =
        _receiptIgnoredPhrases.any(normalizedLine.contains);
    final containsKnownMarket =
        markets.map(_normalizeReceiptInput).any(normalizedLine.contains);
    if (containsIgnoredPhrase &&
        (meaningfulTokens.length <= 1 ||
            (containsKnownMarket && meaningfulTokens.length <= 2))) {
      return true;
    }
    final hasLetters = RegExp(r'[a-z]').hasMatch(normalizedLine);
    final hasDigits = RegExp(r'\d').hasMatch(normalizedLine);
    if (!hasLetters && hasDigits) {
      return true;
    }
    return false;
  }

  Set<String> _tokenizeReceiptText(String input) {
    return input
        .split(' ')
        .map((token) => _stemReceiptToken(token))
        .where((token) => token.length >= 2)
        .toSet();
  }

  String _stemReceiptToken(String token) {
    var value = token.trim();
    if (value.length <= 4) {
      return value;
    }

    const suffixes = [
      'leri',
      'lari',
      'lerin',
      'larin',
      'lik',
      'luk',
      'siz',
      'suz',
      'dan',
      'den',
      'nin',
      'dir',
      'tir',
      'si',
      'su',
      'li',
      'lu',
      'ci',
      'cu',
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

  String _normalizeReceiptInput(String input) {
    return input
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('Ã„Â±', 'i')
        .replaceAll('Ã„Å¸', 'g')
        .replaceAll('ÃƒÂ¼', 'u')
        .replaceAll('Ã…Å¸', 's')
        .replaceAll('ÃƒÂ¶', 'o')
        .replaceAll('ÃƒÂ§', 'c')
        .replaceAll(RegExp(r'[^a-z0-9 ]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
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

  int _stableHash(String input) {
    var hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = (hash + input.codeUnitAt(i) * (i + 1)) % 100000;
    }
    return hash;
  }

  String? _detectStore(String rawText) {
    final normalized = _normalize(rawText);
    if (normalized.contains('migros')) {
      return 'Migros';
    }
    if (normalized.contains('carrefoursa')) {
      return 'CarrefourSA';
    }
    if (normalized.contains('a101')) {
      return 'A101';
    }
    if (normalized.contains('bim')) {
      return 'BIM';
    }
    if (normalized.contains('sok')) {
      return 'SOK';
    }
    return null;
  }

  int _estimateCaloriesFromPrompt(String prompt) {
    final normalized = _normalize(prompt);
    if (normalized.contains('salata') || normalized.contains('salad')) {
      return 220;
    }
    if (normalized.contains('corba') || normalized.contains('soup')) {
      return 190;
    }
    if (normalized.contains('makarna') || normalized.contains('pasta')) {
      return 540;
    }
    if (normalized.contains('pilav') || normalized.contains('rice')) {
      return 410;
    }
    if (normalized.contains('somon') || normalized.contains('salmon')) {
      return 340;
    }
    if (normalized.contains('burger') || normalized.contains('pizza')) {
      return 720;
    }
    return 360;
  }
}

class _ReceiptAlias {
  final Ingredient ingredient;
  final List<String> phrases;
  final Set<String> tokens;

  const _ReceiptAlias({
    required this.ingredient,
    required this.phrases,
    required this.tokens,
  });
}

class _ReceiptMatch {
  final _ReceiptAlias alias;
  final double score;

  const _ReceiptMatch({
    required this.alias,
    required this.score,
  });
}
