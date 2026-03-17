import '../models/ingredient.dart';
import '../models/kitchen_intelligence.dart';
import '../models/recipe.dart';
import '../models/smart_kitchen.dart';
import '../utils/mood_recipes.dart';

class KitchenIntelligenceService {
  static const markets = [
    'A101',
    'BIM',
    'SOK',
    'Migros',
    'CarrefourSA',
    'Getir',
    'Yemeksepeti',
  ];

  static const _marketMultipliers = {
    'A101': 0.90,
    'BIM': 0.89,
    'SOK': 0.93,
    'Migros': 1.05,
    'CarrefourSA': 1.03,
    'Getir': 1.13,
    'Yemeksepeti': 1.16,
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
            ? preferredMarkets
            : markets;

    final results = availableMarkets.map((market) {
      final deals = items.map((shoppingItem) {
        RemoteMarketQuote? liveQuote;
        for (final quote in remoteQuotes) {
          if (quote.market == market &&
              quote.ingredientId == shoppingItem.ingredient.id) {
            liveQuote = quote;
            break;
          }
        }
        final unitPrice = liveQuote?.unitPrice ??
            _unitPriceForMarket(shoppingItem.ingredient, market);
        final totalPrice = unitPrice * shoppingItem.missingCount;
        final isCampaign = liveQuote?.isCampaign ??
            (_stableHash('${shoppingItem.ingredient.id}-$market') % 5 == 0);
        return MarketItemDeal(
          shoppingItem: shoppingItem,
          market: market,
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
        market: market,
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
        .split(RegExp(r'[\n,;]'))
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();
    final matchedIngredients = <Ingredient>[];
    final unmatched = <String>[];

    for (final line in lines) {
      final normalizedLine = _normalize(line);
      Ingredient? bestMatch;
      for (final ingredient in ingredients) {
        final names = [
          _normalize(ingredient.id),
          _normalize(ingredient.nameTr),
          _normalize(ingredient.nameEn),
        ];
        if (names.any(
          (name) =>
              normalizedLine.contains(name) || name.contains(normalizedLine),
        )) {
          bestMatch = ingredient;
          break;
        }
      }
      if (bestMatch != null) {
        if (!matchedIngredients.any((item) => item.id == bestMatch!.id)) {
          matchedIngredients.add(bestMatch);
        }
      } else {
        unmatched.add(line);
      }
    }

    final confidence =
        lines.isEmpty ? 0 : matchedIngredients.length / lines.length;
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
