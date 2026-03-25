import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ingredient.dart';
import '../models/kitchen_intelligence.dart';
import '../models/kitchen_rpg.dart';
import '../models/recipe.dart';
import '../models/smart_actueller.dart';
import '../models/smart_kitchen.dart';
import '../services/kitchen_intelligence_service.dart';
import '../services/kitchen_rpg_service.dart';
import '../services/kitchen_vision_service.dart';
import '../services/market_watch_service.dart';
import '../services/notification_service.dart';
import '../services/recipe_service.dart';
import '../services/smart_actueller_feed_service.dart';
import '../services/smart_actueller_service.dart';
import '../services/smart_actueller_source_service.dart';
import '../utils/mood_recipes.dart';

class AppProvider extends ChangeNotifier {
  static const _actuellerDailySyncHour = 8;

  final RecipeService _recipeService = RecipeService();
  final KitchenIntelligenceService _kitchenIntelligenceService =
      KitchenIntelligenceService();
  final KitchenRpgService _kitchenRpgService = KitchenRpgService();
  final KitchenVisionService _kitchenVisionService = KitchenVisionService();
  final MarketWatchService _marketWatchService = MarketWatchService();
  final SmartActuellerFeedService _smartActuellerFeedService =
      SmartActuellerFeedService();
  final SmartActuellerService _smartActuellerService = SmartActuellerService();
  final SmartActuellerSourceService _smartActuellerSourceService =
      SmartActuellerSourceService();

  bool _isLoading = true;
  Locale _locale = const Locale('tr');
  bool _isDarkMode = false;
  final Map<String, int> _pantryItemCounts = {};
  final Map<String, DateTime> _pantryUpdatedAt = {};
  final Set<String> _favoriteRecipeIds = {};
  List<RecipeMatch> _matchingRecipes = [];
  SmartKitchenPreferences _smartKitchenPreferences =
      SmartKitchenPreferences.defaults();
  KitchenRpgProfile _kitchenRpgProfile = KitchenRpgProfile.initial();
  String? _activeMoodId;
  ReceiptScanResult? _lastReceiptScanResult;
  PlateAnalysisResult? _lastPlateAnalysisResult;
  ActuellerScanResult? _lastActuellerScanResult;
  List<RemoteMarketQuote> _remoteMarketQuotes = const [];
  List<RemoteMarketQuote> _actuellerMarketQuotes = const [];
  MarketSyncStatus _marketSyncStatus = const MarketSyncStatus.idle();
  double _smartActuellerMonthlySavings = 0;
  String? _smartActuellerSavingsMonthKey;
  final Set<String> _trackedActuellerDealIds = {};
  DateTime? _lastActuellerCatalogSyncAt;
  int _lastActuellerCatalogBrochureCount = 0;
  List<String> _lastActuellerCatalogUrls = const [];
  List<ActuellerCatalogBrochureReport> _lastActuellerCatalogReports = const [];
  bool _isActuellerCatalogSyncing = false;
  String? _actuellerCatalogSyncMessage;

  bool get isLoading => _isLoading;
  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isDarkMode => _isDarkMode;
  RecipeService get recipeService => _recipeService;
  Set<String> get selectedIngredientIds => _pantryItemCounts.entries
      .where((entry) => entry.value > 0)
      .map((entry) => entry.key)
      .toSet();
  Set<String> get favoriteRecipeIds => _favoriteRecipeIds;
  List<RecipeMatch> get matchingRecipes => _matchingRecipes;
  int get selectedCount => selectedIngredientIds.length;
  SmartKitchenPreferences get smartKitchenPreferences =>
      _smartKitchenPreferences;
  KitchenRpgProfile get kitchenRpgProfile => _kitchenRpgProfile;
  String? get activeMoodId => _activeMoodId;
  ReceiptScanResult? get lastReceiptScanResult => _lastReceiptScanResult;
  PlateAnalysisResult? get lastPlateAnalysisResult => _lastPlateAnalysisResult;
  ActuellerScanResult? get lastActuellerScanResult => _lastActuellerScanResult;
  MarketSyncStatus get marketSyncStatus => _marketSyncStatus;
  String get kitchenLevelTitle =>
      _kitchenRpgService.titleForLevel(_kitchenRpgProfile.level, languageCode);
  double get smartActuellerMonthlySavings =>
      _smartActuellerSavingsMonthKey == _monthKey(DateTime.now())
          ? _smartActuellerMonthlySavings
          : 0;
  DateTime? get lastActuellerCatalogSyncAt => _lastActuellerCatalogSyncAt;
  int get lastActuellerCatalogBrochureCount =>
      _lastActuellerCatalogBrochureCount;
  List<ActuellerCatalogBrochureReport> get lastActuellerCatalogReports =>
      _lastActuellerCatalogReports;
  int get actuellerDailySyncHour => _actuellerDailySyncHour;
  bool get isActuellerCatalogSyncing => _isActuellerCatalogSyncing;
  String? get actuellerCatalogSyncMessage => _actuellerCatalogSyncMessage;
  bool isActuellerDealTracked(String dealId) =>
      _trackedActuellerDealIds.contains(dealId);
  List<PantryStockItem> get pantryItems {
    final items = _pantryItemCounts.entries
        .where((entry) => entry.value > 0)
        .map((entry) {
          final ingredient = _recipeService.getIngredientById(entry.key);
          if (ingredient == null) return null;
          return PantryStockItem(ingredient: ingredient, count: entry.value);
        })
        .whereType<PantryStockItem>()
        .toList()
      ..sort((a, b) => a.ingredient.getName(languageCode).compareTo(
            b.ingredient.getName(languageCode),
          ));
    return items;
  }

  List<PantryRiskItem> get pantryRiskItems =>
      _kitchenIntelligenceService.buildPantryRiskItems(
        pantryItems: pantryItems,
        updatedAtById: _pantryUpdatedAt,
      );
  List<WasteRescueSuggestion> get wasteRescueSuggestions =>
      _kitchenIntelligenceService.buildWasteRescueSuggestions(
        riskItems: pantryRiskItems,
        recipes: _recipeService.recipes,
        availableIngredientIds: selectedIngredientIds,
      );
  List<DigitalTwinZone> get digitalTwinZones =>
      _kitchenIntelligenceService.buildDigitalTwin(pantryRiskItems);
  List<FlavorPairSuggestion> get flavorPairings =>
      _kitchenIntelligenceService.buildFlavorPairings(selectedIngredientIds);
  List<KitchenWeeklyChallengeProgress> get weeklyChallengeProgress =>
      _kitchenRpgService.buildWeeklyChallengeProgress(_kitchenRpgProfile);
  double get monthlySavingsEstimate => _kitchenRpgProfile.monthlySavingsValue;
  List<ActuellerSuggestion> get smartActuellerSuggestions =>
      _lastActuellerScanResult == null
          ? const []
          : _smartActuellerService.buildPersonalizedSuggestions(
              scanResult: _lastActuellerScanResult!,
              pantryCounts: Map<String, int>.from(_pantryItemCounts),
              pantryRiskItems: pantryRiskItems,
              shoppingItems: getCombinedShoppingItems(),
              preferredMarkets: _smartKitchenPreferences.preferredMarkets,
            );

  Future<void> initialize() async {
    try {
      await _recipeService.loadData();
    } catch (e) {
      debugPrint('RecipeService loadData error: $e');
    }
    try {
      await _loadPreferences();
    } catch (e) {
      debugPrint('LoadPreferences error: $e');
    }
    try {
      await _refreshSmartKitchenNotifications();
    } catch (e) {
      debugPrint('Smart kitchen notification sync error: $e');
    }
    try {
      if (_smartKitchenPreferences.priceComparisonEnabled &&
          _smartKitchenPreferences.marketFeedUrl.trim().isNotEmpty) {
        await refreshMarketWatch(silent: true);
      }
    } catch (e) {
      debugPrint('Market watch sync error: $e');
    }
    _isLoading = false;
    notifyListeners();
    syncAkakceActuellerCatalogIfDue();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    _savePreferences();
    _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  void toggleLanguage() {
    _locale =
        _locale.languageCode == 'tr' ? const Locale('en') : const Locale('tr');
    _savePreferences();
    _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _savePreferences();
    notifyListeners();
  }

  void toggleIngredient(String ingredientId) {
    if (isIngredientSelected(ingredientId)) {
      _pantryItemCounts.remove(ingredientId);
      _pantryUpdatedAt.remove(ingredientId);
    } else {
      _pantryItemCounts[ingredientId] = 1;
      _pantryUpdatedAt[ingredientId] = DateTime.now();
    }
    _persistPantryState();
  }

  void incrementIngredient(String ingredientId) {
    _pantryItemCounts[ingredientId] = getIngredientCount(ingredientId) + 1;
    _pantryUpdatedAt[ingredientId] = DateTime.now();
    _persistPantryState();
  }

  void decrementIngredient(String ingredientId) {
    final currentCount = getIngredientCount(ingredientId);
    if (currentCount <= 1) {
      _pantryItemCounts.remove(ingredientId);
      _pantryUpdatedAt.remove(ingredientId);
    } else {
      _pantryItemCounts[ingredientId] = currentCount - 1;
    }
    _persistPantryState();
  }

  void addMissingIngredients(Iterable<String> ingredientIds) {
    var changed = false;
    final now = DateTime.now();
    for (final ingredientId in ingredientIds) {
      if (getIngredientCount(ingredientId) <= 0) {
        _pantryItemCounts[ingredientId] = 1;
        _pantryUpdatedAt[ingredientId] = now;
        changed = true;
      }
    }
    if (changed) {
      _persistPantryState();
    }
  }

  int getIngredientCount(String ingredientId) {
    return _pantryItemCounts[ingredientId] ?? 0;
  }

  void _persistPantryState() {
    _recordKitchenActivity(KitchenActivityType.pantrySync);
    _updateMatchingRecipes();
    _savePreferences();
    _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  bool isIngredientSelected(String ingredientId) {
    return getIngredientCount(ingredientId) > 0;
  }

  void clearSelectedIngredients() {
    _pantryItemCounts.clear();
    _pantryUpdatedAt.clear();
    _matchingRecipes = [];
    _savePreferences();
    _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  void _updateMatchingRecipes() {
    _matchingRecipes = _recipeService.getMatchingRecipes(
      selectedIngredientIds.toList(),
    );
  }

  void findRecipes() {
    _updateMatchingRecipes();
    notifyListeners();
  }

  void toggleFavorite(String recipeId) {
    if (_favoriteRecipeIds.contains(recipeId)) {
      _favoriteRecipeIds.remove(recipeId);
    } else {
      _favoriteRecipeIds.add(recipeId);
    }
    _savePreferences();
    notifyListeners();
  }

  bool isFavorite(String recipeId) {
    return _favoriteRecipeIds.contains(recipeId);
  }

  Future<void> setActiveMood(String? moodId) async {
    _activeMoodId = moodId;
    _recordKitchenActivity(KitchenActivityType.visionAnalysis);
    await _savePreferences();
    await _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  Future<void> analyzeReceiptText(
    String rawText, {
    String? capturedImagePath,
    String? detectedStore,
    List<String> detectedLabels = const [],
  }) async {
    _lastReceiptScanResult = _kitchenIntelligenceService.analyzeReceiptText(
      rawText,
      _recipeService.ingredients,
      languageCode,
    );
    if (_lastReceiptScanResult != null) {
      _lastReceiptScanResult = ReceiptScanResult(
        matchedIngredients: _lastReceiptScanResult!.matchedIngredients,
        unmatchedLines: _lastReceiptScanResult!.unmatchedLines,
        confidence: _lastReceiptScanResult!.confidence,
        rawText: rawText,
        detectedStore: detectedStore ?? _lastReceiptScanResult!.detectedStore,
        detectedLabels: detectedLabels,
        capturedImagePath: capturedImagePath,
      );
    }

    final now = DateTime.now();
    for (final ingredient in _lastReceiptScanResult!.matchedIngredients) {
      _pantryItemCounts[ingredient.id] = getIngredientCount(ingredient.id) + 1;
      _pantryUpdatedAt[ingredient.id] = now;
    }

    _recordKitchenActivity(KitchenActivityType.receiptScan);
    _recordKitchenActivity(KitchenActivityType.pantrySync, force: true);
    _updateMatchingRecipes();
    await _savePreferences();
    await _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  Future<void> analyzeReceiptImage(String imagePath) async {
    final capture = await _kitchenVisionService.analyzeReceiptImage(imagePath);
    await analyzeReceiptText(
      capture.rawText,
      capturedImagePath: capture.imagePath,
      detectedStore: capture.detectedStore,
      detectedLabels: capture.labels,
    );
  }

  Future<void> analyzePlateDescription(
    String prompt, {
    String? capturedImagePath,
    List<String> detectedLabels = const [],
    int estimatedCalories = 0,
    double confidence = 0,
  }) async {
    _lastPlateAnalysisResult = _kitchenIntelligenceService.analyzeDishPrompt(
      prompt,
      _recipeService.recipes,
      languageCode,
    );
    if (_lastPlateAnalysisResult != null) {
      _lastPlateAnalysisResult = PlateAnalysisResult(
        headlineTr: _lastPlateAnalysisResult!.headlineTr,
        headlineEn: _lastPlateAnalysisResult!.headlineEn,
        summaryTr: _lastPlateAnalysisResult!.summaryTr,
        summaryEn: _lastPlateAnalysisResult!.summaryEn,
        suggestedMoodId: _lastPlateAnalysisResult!.suggestedMoodId,
        shareCaptionTr: _lastPlateAnalysisResult!.shareCaptionTr,
        shareCaptionEn: _lastPlateAnalysisResult!.shareCaptionEn,
        matchedRecipes: _lastPlateAnalysisResult!.matchedRecipes,
        detectedLabels: detectedLabels,
        estimatedCalories: estimatedCalories > 0
            ? estimatedCalories
            : _lastPlateAnalysisResult!.estimatedCalories,
        analysisPrompt: prompt,
        capturedImagePath: capturedImagePath,
        confidence:
            confidence > 0 ? confidence : _lastPlateAnalysisResult!.confidence,
      );
    }
    _recordKitchenActivity(KitchenActivityType.visionAnalysis);
    await _savePreferences();
    notifyListeners();
  }

  Future<void> analyzePlateImage(String imagePath) async {
    final capture = await _kitchenVisionService.analyzePlateImage(imagePath);
    await analyzePlateDescription(
      capture.prompt,
      capturedImagePath: capture.imagePath,
      detectedLabels: capture.labels,
      estimatedCalories: capture.estimatedCalories,
      confidence: capture.confidence,
    );
  }

  Future<void> analyzeActuellerText(
    String rawText, {
    String? capturedImagePath,
    String? detectedStore,
    List<String> blocks = const [],
    String sourceLabel = 'Smart Actüel',
  }) async {
    _lastActuellerScanResult = _smartActuellerService.analyzeFlyerText(
      rawText: rawText,
      ingredients: _recipeService.ingredients,
      detectedStore: detectedStore,
      sourceLabel: sourceLabel,
      capturedImagePath: capturedImagePath,
      ocrBlocks: blocks,
    );
    _actuellerMarketQuotes =
        _smartActuellerService.toRemoteQuotes(_lastActuellerScanResult!);
    _recordKitchenActivity(KitchenActivityType.visionAnalysis);
    await _savePreferences();
    await _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  Future<void> analyzeActuellerImage(String imagePath) async {
    final capture =
        await _kitchenVisionService.analyzeActuellerImage(imagePath);
    await analyzeActuellerText(
      capture.rawText,
      capturedImagePath: capture.imagePath,
      detectedStore: capture.detectedStore,
      blocks: capture.blocks,
      sourceLabel: capture.detectedStore == null
          ? 'Smart Actüel OCR'
          : '${capture.detectedStore} Aktüel',
    );
  }

  Future<void> analyzeActuellerUrl(String url) async {
    final source = await _smartActuellerSourceService.prepareSource(url);
    final allBlocks = <String>{};
    final rawParts = <String>[];
    var detectedStore = source.detectedStore;

    if (source.extractedText.trim().isNotEmpty) {
      rawParts.add(source.extractedText.trim());
    }

    final shouldRunImageFallback =
        rawParts.isEmpty && source.shouldUseImageFallback;

    if (shouldRunImageFallback) {
      for (final imagePath in source.localImagePaths) {
        final capture = await _kitchenVisionService.analyzeActuellerImage(
          imagePath,
        );
        if (capture.rawText.trim().isNotEmpty) {
          rawParts.add(capture.rawText.trim());
        }
        allBlocks.addAll(capture.blocks);
        detectedStore ??= capture.detectedStore;
      }
    }

    if (rawParts.isEmpty) {
      throw Exception('Broşürde okunabilir metin bulunamadı.');
    }

    await analyzeActuellerText(
      rawParts.join('\n'),
      capturedImagePath:
          source.localImagePaths.isEmpty ? null : source.localImagePaths.first,
      detectedStore: detectedStore,
      blocks: allBlocks.toList(),
      sourceLabel: source.sourceLabel,
    );
  }

  Future<void> importSmartActuellerFeed(String feedUrl) async {
    final snapshot = await _smartActuellerFeedService.fetchFeed(
      feedUrl: feedUrl,
    );

    _lastActuellerScanResult = ActuellerScanResult(
      rawText: snapshot.catalogItems.map((item) => item.rawBlock).join('\n'),
      blocks: snapshot.catalogItems.map((item) => item.rawBlock).toList(),
      catalogItems: snapshot.catalogItems,
      deals: const [],
      unmatchedBlocks: const [],
      detectedStore: null,
      sourceLabel: snapshot.sourceLabel,
      capturedImagePath: null,
      scannedAt: snapshot.updatedAt,
      confidence: snapshot.catalogItems.isEmpty ? 0 : 0.92,
    );
    _actuellerMarketQuotes = const [];
    _lastActuellerCatalogSyncAt = snapshot.updatedAt;
    _lastActuellerCatalogBrochureCount = snapshot.brochureCount;
    _lastActuellerCatalogReports = snapshot.brochureReports;
    _lastActuellerCatalogUrls = snapshot.brochureReports
        .map((report) => report.brochureUrl)
        .where((url) => url.isNotEmpty)
        .toList();
    _actuellerCatalogSyncMessage =
        '${snapshot.brochureCount} broşür feedden alındı, '
        '${snapshot.catalogItems.length} ürün hazır.';
    await _savePreferences();
    await _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  Future<void> syncAkakceActuellerCatalogIfDue() async {
    await syncAkakceActuellerCatalog();
  }

  Future<void> syncAkakceActuellerCatalog({bool force = false}) async {
    final now = DateTime.now();
    if (!force && !_shouldSyncActuellerCatalog(now)) {
      return;
    }
    if (_isActuellerCatalogSyncing) {
      return;
    }

    _isActuellerCatalogSyncing = true;
    _actuellerCatalogSyncMessage = null;
    notifyListeners();

    try {
      final brochureUrls =
          await _smartActuellerSourceService.discoverBrochureUrls(
        selectedMarketIds: _smartKitchenPreferences.preferredMarkets,
        maxPerMarket: 15,
        maxTotal: 45,
      );
      final urlsToProcess = brochureUrls;

      if (urlsToProcess.isEmpty) {
        _lastActuellerCatalogSyncAt = now;
        _lastActuellerCatalogBrochureCount = 0;
        _lastActuellerCatalogUrls = brochureUrls;
        _actuellerCatalogSyncMessage = _lastActuellerScanResult == null
            ? 'Bugün yeni broşür bulunmadı.'
            : 'Bugün yeni broşür bulunmadı. Mevcut aktüel veriler korunuyor.';
        await _savePreferences();
        await _refreshSmartKitchenNotifications();
        return;
      }

      final previousScan = _lastActuellerScanResult;
      final uniqueCatalogItems = <String, ActuellerCatalogItem>{};
      final uniqueDeals = <String, ActuellerDeal>{};
      final allBlocks = <String>{};
      final unmatchedBlocks = <String>{};
      final reports = <ActuellerCatalogBrochureReport>[];
      var brochureCount = 0;

      for (final brochureUrl in urlsToProcess) {
        try {
          final source = await _smartActuellerSourceService.prepareSource(
            brochureUrl,
          );
          final rawParts = <String>[];
          final brochureBlocks = <String>{};
          var detectedStore = source.detectedStore;

          if (source.extractedText.trim().isNotEmpty) {
            rawParts.add(source.extractedText.trim());
          }

          final shouldRunImageFallback =
              rawParts.isEmpty && source.shouldUseImageFallback;

          if (shouldRunImageFallback) {
            for (final imagePath in source.localImagePaths.take(6)) {
              try {
                final capture =
                    await _kitchenVisionService.analyzeActuellerImage(
                  imagePath,
                );
                if (capture.rawText.trim().isNotEmpty) {
                  final filtered = _filterOcrLines(capture.rawText.trim());
                  if (filtered.isNotEmpty) {
                    rawParts.add(filtered);
                  }
                }
                brochureBlocks.addAll(
                  capture.blocks.where(_isUsableOcrBlock),
                );
                detectedStore ??= capture.detectedStore;
              } catch (error) {
                debugPrint(
                  '[Aktueller] OCR hatasi (devam ediliyor): $error',
                );
              }
            }
          }

          if (rawParts.isEmpty) {
            reports.add(
              ActuellerCatalogBrochureReport(
                brochureUrl: brochureUrl,
                sourceLabel: source.sourceLabel,
                marketName: detectedStore,
                imageCount: source.localImagePaths.length,
                blockCount: brochureBlocks.length,
                itemCount: 0,
                dealCount: 0,
                hadReadableText: false,
                productNames: const [],
                note:
                    'Yeni broşürler bulundu ama okunabilir içerik çıkarılamadı.',
              ),
            );
            continue;
          }

          brochureCount += 1;
          final brochureResult = _smartActuellerService.analyzeFlyerText(
            rawText: rawParts.join('\n'),
            ingredients: _recipeService.ingredients,
            detectedStore: detectedStore,
            sourceLabel: source.sourceLabel,
            ocrBlocks: brochureBlocks.toList(),
          );
          reports.add(
            ActuellerCatalogBrochureReport(
              brochureUrl: brochureUrl,
              sourceLabel: source.sourceLabel,
              marketName: detectedStore ?? brochureResult.detectedStore,
              imageCount: source.localImagePaths.length,
              blockCount: brochureResult.blocks.length,
              itemCount: brochureResult.catalogItems.length,
              dealCount: brochureResult.deals.length,
              hadReadableText: true,
              productNames: brochureResult.catalogItems
                  .map((item) => item.productTitle)
                  .take(5)
                  .toList(),
              note: brochureResult.catalogItems.isEmpty
                  ? 'Okunabilir metin alındı ama ürün listesi çıkarılamadı.'
                  : null,
            ),
          );

          for (final item in brochureResult.catalogItems) {
            uniqueCatalogItems[item.id] = item;
          }
          for (final deal in brochureResult.deals) {
            final key = '${deal.marketName}|${deal.ingredient.id}';
            final existing = uniqueDeals[key];
            if (existing == null ||
                deal.discountPrice < existing.discountPrice ||
                (deal.discountPrice == existing.discountPrice &&
                    deal.confidence > existing.confidence)) {
              uniqueDeals[key] = deal;
            }
          }
          allBlocks.addAll(brochureResult.blocks);
          unmatchedBlocks.addAll(brochureResult.unmatchedBlocks.take(8));
        } catch (error) {
          reports.add(
            ActuellerCatalogBrochureReport(
              brochureUrl: brochureUrl,
              sourceLabel: 'Aktüel Broşür',
              marketName: null,
              imageCount: 0,
              blockCount: 0,
              itemCount: 0,
              dealCount: 0,
              hadReadableText: false,
              productNames: const [],
              note: error.toString().replaceFirst('Exception: ', ''),
            ),
          );
          debugPrint('Actueller brochure sync error: $error');
        }
      }

      final deals = uniqueDeals.values.toList()
        ..sort((a, b) {
          final marketCompare = a.marketName.compareTo(b.marketName);
          if (marketCompare != 0) return marketCompare;
          return a.discountPrice.compareTo(b.discountPrice);
        });
      final catalogItems = uniqueCatalogItems.values.toList()
        ..sort((a, b) {
          final marketCompare = a.marketName.compareTo(b.marketName);
          if (marketCompare != 0) return marketCompare;
          return a.productTitle.compareTo(b.productTitle);
        });

      if (catalogItems.isNotEmpty ||
          deals.isNotEmpty ||
          force ||
          previousScan == null) {
        _lastActuellerScanResult = ActuellerScanResult(
          rawText: allBlocks.join('\n'),
          blocks: allBlocks.toList(),
          catalogItems: catalogItems,
          deals: deals,
          unmatchedBlocks: unmatchedBlocks.take(40).toList(),
          detectedStore: null,
          sourceLabel: 'Günlük Aktüel Broşürler',
          capturedImagePath: null,
          scannedAt: now,
          confidence: deals.isEmpty ? 0 : 0.78,
        );
        _actuellerMarketQuotes = _smartActuellerService.toRemoteQuotes(
          _lastActuellerScanResult!,
        );
      }

      _lastActuellerCatalogSyncAt = now;
      _lastActuellerCatalogBrochureCount = brochureCount;
      _lastActuellerCatalogUrls = brochureUrls;
      _lastActuellerCatalogReports = reports;
      _actuellerCatalogSyncMessage = brochureCount == 0
          ? 'Yeni broşürler bulundu ama okunabilir içerik çıkarılamadı.'
          : catalogItems.isEmpty
              ? 'Yeni broşürler bulundu ama ürün listesi çıkarılamadı.'
              : '$brochureCount yeni broşür işlendi, '
                  '${catalogItems.length} ürün okundu, '
                  '${deals.length} mutfak eşleşmesi hazır.';
      _recordKitchenActivity(KitchenActivityType.visionAnalysis);
      await _savePreferences();
      await _refreshSmartKitchenNotifications();
    } catch (error) {
      _actuellerCatalogSyncMessage =
          'Aktüel broşürler alınamadı. Daha sonra tekrar dene.';
      debugPrint('Actueller catalog sync error: $error');
    } finally {
      _isActuellerCatalogSyncing = false;
      notifyListeners();
    }
  }

  Future<void> trackActuellerSavings(ActuellerSuggestion suggestion) async {
    final currentMonthKey = _monthKey(DateTime.now());
    if (_smartActuellerSavingsMonthKey != currentMonthKey) {
      _smartActuellerSavingsMonthKey = currentMonthKey;
      _smartActuellerMonthlySavings = 0;
      _trackedActuellerDealIds.clear();
    }
    if (_trackedActuellerDealIds.contains(suggestion.deal.id)) {
      return;
    }
    _trackedActuellerDealIds.add(suggestion.deal.id);
    _smartActuellerMonthlySavings += suggestion.estimatedSavings;
    await _savePreferences();
    notifyListeners();
  }

  void clearVisionResults() {
    _lastReceiptScanResult = null;
    _lastPlateAnalysisResult = null;
    _lastActuellerScanResult = null;
    _actuellerMarketQuotes = const [];
    _lastActuellerCatalogReports = const [];
    _savePreferences();
    notifyListeners();
  }

  void recordRoulettePlay() {
    _recordKitchenActivity(KitchenActivityType.roulettePlay);
    _savePreferences();
    notifyListeners();
  }

  List<SmartShoppingItem> getCombinedShoppingItems() {
    final merged = <String, SmartShoppingItem>{};
    for (final slot in _smartKitchenPreferences.mealSlots) {
      for (final item in getShoppingItemsForMeal(slot.id)) {
        final existing = merged[item.ingredient.id];
        if (existing == null) {
          merged[item.ingredient.id] = item;
          continue;
        }
        final recipeNames =
            {...existing.recipeNames, ...item.recipeNames}.toList()..sort();
        merged[item.ingredient.id] = SmartShoppingItem(
          ingredient: item.ingredient,
          requiredCount: existing.requiredCount + item.requiredCount,
          availableCount: existing.availableCount,
          missingCount: existing.missingCount + item.missingCount,
          recipeNames: recipeNames,
        );
      }
    }

    final items = merged.values.toList()
      ..sort((a, b) => b.missingCount.compareTo(a.missingCount));
    return items;
  }

  List<MarketBasketComparison> getMarketComparisons() {
    return _kitchenIntelligenceService.buildMarketComparisons(
      getCombinedShoppingItems(),
      remoteQuotes: [
        ..._remoteMarketQuotes,
        ..._actuellerMarketQuotes,
      ],
      preferredMarkets: _smartKitchenPreferences.preferredMarkets,
    );
  }

  WeeklyMenuDigest getWeeklyMenuDigest() {
    final breakfast = getMenuSuggestionsForMeal('breakfast', limit: 1)
        .map((item) => item.recipe)
        .toList();
    final lunch = getMenuSuggestionsForMeal('lunch', limit: 1)
        .map((item) => item.recipe)
        .toList();
    final dinner = getMenuSuggestionsForMeal('dinner', limit: 1)
        .map((item) => item.recipe)
        .toList();
    return _kitchenIntelligenceService.buildWeeklyMenuDigest(
      breakfast: breakfast,
      lunch: lunch,
      dinner: dinner,
      locale: languageCode,
      moodId: _activeMoodId,
    );
  }

  void _recordKitchenActivity(
    KitchenActivityType type, {
    int amount = 1,
    double savedValue = 0,
    bool force = false,
  }) {
    final now = DateTime.now();
    if (type == KitchenActivityType.pantrySync &&
        !force &&
        !_kitchenRpgService.shouldGrantPantrySync(_kitchenRpgProfile, now)) {
      return;
    }

    _kitchenRpgProfile = _kitchenRpgService.registerActivity(
      _kitchenRpgProfile,
      type,
      now: now,
      amount: amount,
      savedValue: savedValue,
    );
  }

  List<PersonalizedRecipeSuggestion> getPersonalizedSuggestions({
    String? mealId,
    int limit = 3,
  }) {
    final targetMealId = mealId ?? getNextPlannedMealId();
    final activeMood = _activeMoodId == null
        ? null
        : MoodRecipeEngine.getMoodById(_activeMoodId!);

    final suggestions = _recipeService.recipes
        .where((recipe) => _isRecipeSuitableForMeal(targetMealId, recipe))
        .where((recipe) => _matchesActiveMood(recipe, activeMood))
        .map((recipe) {
      final missingItems = _getMissingItemsForRecipe(recipe);
      final matchPercent = _getRecipeCoveragePercent(recipe);
      final canCookNow = missingItems.isEmpty;
      final categoryBonus =
          _preferredCategoriesForMeal(targetMealId).contains(recipe.category)
              ? 40
              : 0;
      final moodBonus =
          activeMood == null ? 0 : _scoreMoodFit(recipe, activeMood.filter);
      final pantryBonus = canCookNow
          ? 36
          : selectedIngredientIds.isEmpty
              ? 12
              : (matchPercent / 3).round();
      final speedBonus =
          (((90 - recipe.totalTimeMinutes).clamp(0, 90)) / 3).round();
      final difficultyBonus = switch (recipe.difficulty) {
        'easy' => 10,
        'medium' => 6,
        _ => 2,
      };
      final score = categoryBonus +
          moodBonus +
          pantryBonus +
          speedBonus +
          difficultyBonus;

      return PersonalizedRecipeSuggestion(
        recipe: recipe,
        score: score,
        matchPercent: matchPercent,
        canCookNow: canCookNow,
        missingItems: missingItems,
      );
    }).toList()
      ..sort((a, b) {
        final scoreCompare = b.score.compareTo(a.score);
        if (scoreCompare != 0) return scoreCompare;
        final matchCompare = b.matchPercent.compareTo(a.matchPercent);
        if (matchCompare != 0) return matchCompare;
        return a.recipe.totalTimeMinutes.compareTo(b.recipe.totalTimeMinutes);
      });

    return suggestions.take(limit).toList();
  }

  List<ReminderPreview> getUpcomingReminderPreviews({int limit = 4}) {
    final now = DateTime.now();
    final previews = _smartKitchenPreferences.mealSlots
        .where((slot) => slot.enabled)
        .map((slot) => _nextReminderForSlot(slot, now))
        .whereType<ReminderPreview>()
        .toList()
      ..sort((a, b) => a.remindAt.compareTo(b.remindAt));

    return previews.take(limit).toList();
  }

  ReminderPreview? get nextReminderPreview {
    final previews = getUpcomingReminderPreviews(limit: 1);
    return previews.isEmpty ? null : previews.first;
  }

  String getNextPlannedMealId() {
    final now = DateTime.now();
    final nextMeals = _smartKitchenPreferences.mealSlots
        .where((slot) => slot.enabled)
        .map((slot) => _nextMealForSlot(slot, now))
        .whereType<ReminderPreview>()
        .toList()
      ..sort((a, b) => a.mealAt.compareTo(b.mealAt));

    if (nextMeals.isNotEmpty) return nextMeals.first.mealId;
    return 'dinner';
  }

  List<Recipe> getPlannedRecipes(String mealId) {
    final recipeIds =
        _smartKitchenPreferences.plannedRecipeIdsByMeal[mealId] ?? const [];
    return recipeIds
        .map(_recipeService.getRecipeById)
        .whereType<Recipe>()
        .toList();
  }

  Recipe? getPlannedRecipe(String mealId) {
    final recipes = getPlannedRecipes(mealId);
    return recipes.isEmpty ? null : recipes.first;
  }

  List<Recipe> getMealPlanCandidates(String mealId, {int limit = 24}) {
    return getPersonalizedSuggestions(mealId: mealId, limit: limit)
        .map((suggestion) => suggestion.recipe)
        .toList();
  }

  List<PersonalizedRecipeSuggestion> getMenuSuggestionsForMeal(
    String mealId, {
    int limit = 4,
  }) {
    final selectedRecipeIds =
        (_smartKitchenPreferences.plannedRecipeIdsByMeal[mealId] ?? const [])
            .toSet();
    return getPersonalizedSuggestions(mealId: mealId, limit: limit + 6)
        .where(
            (suggestion) => !selectedRecipeIds.contains(suggestion.recipe.id))
        .take(limit)
        .toList();
  }

  Future<void> consumePlannedRecipesForMeal(String mealId) async {
    final recipes = getPlannedRecipes(mealId);
    if (recipes.isEmpty) return;

    final riskItemsBefore = pantryRiskItems;
    final requiredCounts = _getCombinedRequiredCounts(recipes);
    var protectedValue = 0.0;
    var rescuedRiskyItems = 0;
    for (final entry in requiredCounts.entries) {
      final currentCount = getIngredientCount(entry.key);
      if (currentCount <= 0) continue;
      final ingredient = _recipeService.getIngredientById(entry.key);
      if (ingredient != null) {
        protectedValue += _kitchenIntelligenceService.estimateIngredientValue(
          ingredient,
          entry.value.clamp(0, currentCount),
        );
      }
      final nextCount = currentCount - entry.value;
      if (nextCount > 0) {
        _pantryItemCounts[entry.key] = nextCount;
      } else {
        _pantryItemCounts.remove(entry.key);
        _pantryUpdatedAt.remove(entry.key);
      }
    }

    for (final riskItem
        in riskItemsBefore.where((item) => item.riskScore >= 0.45)) {
      if (requiredCounts.containsKey(riskItem.ingredient.id)) {
        rescuedRiskyItems += 1;
      }
    }

    _updateMatchingRecipes();
    _recordKitchenActivity(
      KitchenActivityType.menuCooked,
      savedValue: protectedValue,
    );
    if (rescuedRiskyItems > 0) {
      _recordKitchenActivity(
        KitchenActivityType.wasteRescue,
        amount: rescuedRiskyItems,
        savedValue: protectedValue,
      );
    }
    await _savePreferences();
    await _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  Future<void> setMealSlotEnabled(String mealId, bool enabled) async {
    final slot = _smartKitchenPreferences.slotById(mealId);
    _smartKitchenPreferences =
        _smartKitchenPreferences.replaceSlot(slot.copyWith(enabled: enabled));
    await _savePreferences();
    await _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  Future<void> setMealSlotTime(
    String mealId, {
    required bool isWeekend,
    required int minutesAfterMidnight,
  }) async {
    final slot = _smartKitchenPreferences.slotById(mealId);
    _smartKitchenPreferences = _smartKitchenPreferences.replaceSlot(
      slot.copyWith(
        weekdayMinutes: isWeekend ? slot.weekdayMinutes : minutesAfterMidnight,
        weekendMinutes: isWeekend ? minutesAfterMidnight : slot.weekendMinutes,
      ),
    );
    await _savePreferences();
    await _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  Future<void> setMealLeadMinutes(String mealId, int minutes) async {
    final slot = _smartKitchenPreferences.slotById(mealId);
    _smartKitchenPreferences = _smartKitchenPreferences.replaceSlot(
      slot.copyWith(leadMinutes: minutes),
    );
    await _savePreferences();
    await _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  Future<void> setPlannedRecipeForMeal(String mealId, String recipeId) async {
    final plannedRecipeIdsByMeal = {
      ..._smartKitchenPreferences.plannedRecipeIdsByMeal,
      mealId: [...?_smartKitchenPreferences.plannedRecipeIdsByMeal[mealId]],
    };
    final currentIds = plannedRecipeIdsByMeal[mealId] ?? <String>[];
    if (!currentIds.contains(recipeId)) {
      currentIds.add(recipeId);
    }
    _smartKitchenPreferences = _smartKitchenPreferences.copyWith(
      plannedRecipeIdsByMeal: plannedRecipeIdsByMeal,
    );
    _recordKitchenActivity(KitchenActivityType.mealPlan);
    await _savePreferences();
    await _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  Future<void> replacePlannedRecipesForMeal(
    String mealId,
    List<String> recipeIds,
  ) async {
    final plannedRecipeIdsByMeal = {
      ..._smartKitchenPreferences.plannedRecipeIdsByMeal,
    };
    final uniqueIds = <String>[];
    for (final recipeId in recipeIds) {
      if (!uniqueIds.contains(recipeId)) {
        uniqueIds.add(recipeId);
      }
    }

    if (uniqueIds.isEmpty) {
      plannedRecipeIdsByMeal.remove(mealId);
    } else {
      plannedRecipeIdsByMeal[mealId] = uniqueIds;
    }

    _smartKitchenPreferences = _smartKitchenPreferences.copyWith(
      plannedRecipeIdsByMeal: plannedRecipeIdsByMeal,
    );
    if (uniqueIds.isNotEmpty) {
      _recordKitchenActivity(KitchenActivityType.mealPlan,
          amount: uniqueIds.length);
    }
    await _savePreferences();
    await _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  Future<void> removePlannedRecipeForMeal(
      String mealId, String recipeId) async {
    final currentIds = [
      ...?_smartKitchenPreferences.plannedRecipeIdsByMeal[mealId],
    ]..remove(recipeId);
    final plannedRecipeIdsByMeal = {
      ..._smartKitchenPreferences.plannedRecipeIdsByMeal,
    };
    if (currentIds.isEmpty) {
      plannedRecipeIdsByMeal.remove(mealId);
    } else {
      plannedRecipeIdsByMeal[mealId] = currentIds;
    }
    _smartKitchenPreferences = _smartKitchenPreferences.copyWith(
      plannedRecipeIdsByMeal: plannedRecipeIdsByMeal,
    );
    await _savePreferences();
    await _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  int getPlannedMenuCount() {
    return _smartKitchenPreferences.plannedRecipeIdsByMeal.values.fold<int>(
      0,
      (count, ids) => count + ids.length,
    );
  }

  int getPlannedMealCount() {
    return _smartKitchenPreferences.mealSlots
        .where((slot) => getPlannedRecipes(slot.id).isNotEmpty)
        .length;
  }

  Future<void> clearPlannedRecipeForMeal(String mealId) async {
    final plannedRecipeIdsByMeal = {
      ..._smartKitchenPreferences.plannedRecipeIdsByMeal,
    };
    plannedRecipeIdsByMeal.remove(mealId);
    _smartKitchenPreferences = _smartKitchenPreferences.copyWith(
      plannedRecipeIdsByMeal: plannedRecipeIdsByMeal,
    );
    await _savePreferences();
    await _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  Future<void> setEveningDriveHomeSuggestions(bool value) async {
    _smartKitchenPreferences = _smartKitchenPreferences.copyWith(
      eveningDriveHomeSuggestions: value,
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setSchoolBreakfastNudges(bool value) async {
    _smartKitchenPreferences = _smartKitchenPreferences.copyWith(
      schoolBreakfastNudges: value,
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setPriceComparisonEnabled(bool value) async {
    _smartKitchenPreferences = _smartKitchenPreferences.copyWith(
      priceComparisonEnabled: value,
    );
    await _savePreferences();
    if (!value) {
      _remoteMarketQuotes = const [];
      _marketSyncStatus = const MarketSyncStatus.idle();
    } else if (_smartKitchenPreferences.marketFeedUrl.trim().isNotEmpty) {
      await refreshMarketWatch(silent: true);
    }
    notifyListeners();
  }

  Future<void> setCampaignAlertsEnabled(bool value) async {
    _smartKitchenPreferences = _smartKitchenPreferences.copyWith(
      campaignAlertsEnabled: value,
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> togglePreferredMarket(String market) async {
    final markets = [..._smartKitchenPreferences.preferredMarkets];
    if (markets.contains(market)) {
      markets.remove(market);
    } else {
      markets.add(market);
    }

    _smartKitchenPreferences = _smartKitchenPreferences.copyWith(
      preferredMarkets: markets,
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setMarketFeedConfig({
    required String feedUrl,
    required String feedLabel,
  }) async {
    _smartKitchenPreferences = _smartKitchenPreferences.copyWith(
      marketFeedUrl: feedUrl.trim(),
      marketFeedLabel: feedLabel.trim(),
    );
    await _savePreferences();
    notifyListeners();
  }

  Future<void> refreshMarketWatch({bool silent = false}) async {
    final feedUrl = _smartKitchenPreferences.marketFeedUrl.trim();
    if (feedUrl.isEmpty) {
      _remoteMarketQuotes = const [];
      _marketSyncStatus = MarketSyncStatus(
        isLoading: false,
        usedLiveData: false,
        sourceLabel: _smartKitchenPreferences.marketFeedLabel,
        lastSyncedAt: null,
        message: languageCode == 'tr'
            ? 'Canli market feed URL ayarlanmadi.'
            : 'No live market feed URL configured.',
      );
      if (!silent) {
        notifyListeners();
      }
      return;
    }

    _marketSyncStatus = MarketSyncStatus(
      isLoading: true,
      usedLiveData: _remoteMarketQuotes.isNotEmpty,
      sourceLabel: _smartKitchenPreferences.marketFeedLabel,
      lastSyncedAt: _marketSyncStatus.lastSyncedAt,
      message: null,
    );
    if (!silent) {
      notifyListeners();
    }

    try {
      final snapshot = await _marketWatchService.fetchFeed(
        feedUrl: feedUrl,
        ingredients: _recipeService.ingredients,
      );
      _remoteMarketQuotes = snapshot.quotes;
      _marketSyncStatus = MarketSyncStatus(
        isLoading: false,
        usedLiveData: snapshot.quotes.isNotEmpty,
        sourceLabel: snapshot.sourceLabel,
        lastSyncedAt: snapshot.fetchedAt,
        message: snapshot.quotes.isEmpty
            ? (languageCode == 'tr'
                ? 'Feed geldi ama eslesen urun bulunamadi.'
                : 'Feed loaded but no matching products were found.')
            : null,
      );
    } catch (error) {
      _remoteMarketQuotes = const [];
      _marketSyncStatus = MarketSyncStatus(
        isLoading: false,
        usedLiveData: false,
        sourceLabel: _smartKitchenPreferences.marketFeedLabel,
        lastSyncedAt: _marketSyncStatus.lastSyncedAt,
        message: languageCode == 'tr'
            ? 'Canli market feed okunamadi. Tahmini fiyatlara donuldu.'
            : 'Live market feed could not be loaded. Falling back to estimated prices.',
      );
      debugPrint('Market watch error: $error');
    }

    await _savePreferences();
    notifyListeners();
  }

  List<SmartShoppingItem> getShoppingItemsForMeal(String mealId) {
    final plannedRecipes = getPlannedRecipes(mealId);
    if (plannedRecipes.isEmpty) return const [];

    final combinedCounts = _getCombinedRequiredCounts(plannedRecipes);
    final recipeNamesByIngredient = <String, Set<String>>{};

    for (final recipe in plannedRecipes) {
      final recipeName = recipe.getName(languageCode);
      for (final requirement in recipe.ingredients.where(
        (ingredient) => !ingredient.isOptional,
      )) {
        recipeNamesByIngredient
            .putIfAbsent(requirement.ingredientId, () => <String>{})
            .add(recipeName);
      }
    }

    return combinedCounts.entries
        .map((entry) {
          final ingredient = _recipeService.getIngredientById(entry.key);
          if (ingredient == null) return null;
          final availableCount = getIngredientCount(entry.key);
          final missingCount = (entry.value - availableCount).clamp(0, 999);
          if (missingCount == 0) return null;
          return SmartShoppingItem(
            ingredient: ingredient,
            requiredCount: entry.value,
            availableCount: availableCount,
            missingCount: missingCount,
            recipeNames:
                (recipeNamesByIngredient[entry.key] ?? const <String>{})
                    .toList()
                  ..sort(),
          );
        })
        .whereType<SmartShoppingItem>()
        .toList()
      ..sort(
        (a, b) => b.missingCount.compareTo(a.missingCount),
      );
  }

  List<String> getPlannedShoppingSummary() {
    final summary = <String>[];
    final seenItems = <String>{};

    for (final slot in _smartKitchenPreferences.mealSlots.where(
      (slot) => slot.enabled && getPlannedRecipes(slot.id).isNotEmpty,
    )) {
      for (final item in getShoppingItemsForMeal(slot.id)) {
        final recipeLabel = item.recipeNames.join(', ');
        final line =
            '${getPlannerMealLabel(slot.id)} • ${item.ingredient.getName(languageCode)} • '
            '${item.missingCount} '
            '${languageCode == 'tr' ? 'stok birimi eksik' : 'stock units missing'}'
            '${recipeLabel.isEmpty ? '' : ' • $recipeLabel'}';
        if (seenItems.add(line)) {
          summary.add(line);
        }
      }
    }

    return summary;
  }

  String getPlannerMealLabel(String mealId) {
    switch (mealId) {
      case 'breakfast':
        return languageCode == 'tr' ? 'Kahvaltı' : 'Breakfast';
      case 'lunch':
        return languageCode == 'tr' ? 'Öğle yemeği' : 'Lunch';
      case 'dinner':
      default:
        return languageCode == 'tr' ? 'Akşam yemeği' : 'Dinner';
    }
  }

  List<String> _preferredCategoriesForMeal(String mealId) {
    switch (mealId) {
      case 'breakfast':
        return ['breakfast', 'beverage'];
      case 'lunch':
        return ['soup', 'salad', 'main', 'side'];
      case 'dinner':
      default:
        return ['main', 'soup', 'appetizer', 'side'];
    }
  }

  bool _matchesActiveMood(Recipe recipe, MoodOption? mood) {
    if (mood == null) return true;
    final filter = mood.filter;
    if (filter.maxTime > 0 && recipe.totalTimeMinutes > filter.maxTime) {
      return false;
    }
    if (filter.difficulties.isNotEmpty &&
        !filter.difficulties.contains(recipe.difficulty)) {
      return false;
    }
    if (filter.categories.isNotEmpty &&
        !filter.categories.contains(recipe.category)) {
      return false;
    }
    if (filter.requiredTags.isNotEmpty &&
        !filter.requiredTags.any((tag) => _matchesAnyTag(recipe, [tag]))) {
      return false;
    }
    if (filter.blockedTags.isNotEmpty &&
        filter.blockedTags.any((tag) => _matchesAnyTag(recipe, [tag]))) {
      return false;
    }
    return true;
  }

  int _scoreMoodFit(Recipe recipe, MoodFilter filter) {
    var score = 0;
    if (filter.maxTime > 0 && recipe.totalTimeMinutes <= filter.maxTime) {
      score += 14;
    }
    if (filter.difficulties.isNotEmpty &&
        filter.difficulties.contains(recipe.difficulty)) {
      score += 12;
    }
    if (filter.categories.isNotEmpty &&
        filter.categories.contains(recipe.category)) {
      score += 16;
    }
    if (filter.requiredTags.isNotEmpty &&
        filter.requiredTags.any((tag) => _matchesAnyTag(recipe, [tag]))) {
      score += 18;
    }
    return score;
  }

  int _getRecipeCoveragePercent(Recipe recipe) {
    final requiredCounts = _getRequiredCountsForRecipe(recipe);
    if (requiredCounts.isEmpty) return 0;

    var requiredTotal = 0;
    var availableTotal = 0;

    for (final entry in requiredCounts.entries) {
      final required = entry.value;
      final available = getIngredientCount(entry.key);
      requiredTotal += required;
      availableTotal += available.clamp(0, required);
    }

    if (requiredTotal == 0) return 0;
    return ((availableTotal / requiredTotal) * 100).round();
  }

  List<SmartShoppingItem> _getMissingItemsForRecipe(Recipe recipe) {
    final recipeName = recipe.getName(languageCode);
    final requiredCounts = _getRequiredCountsForRecipe(recipe);
    final requirementsByIngredient = <String, RecipeIngredient>{};

    for (final requirement in recipe.ingredients.where(
      (ingredient) => !ingredient.isOptional,
    )) {
      requirementsByIngredient.putIfAbsent(
        requirement.ingredientId,
        () => requirement,
      );
    }

    return requiredCounts.entries
        .map((entry) {
          final ingredient = _recipeService.getIngredientById(entry.key);
          if (ingredient == null) return null;
          final availableCount = getIngredientCount(entry.key);
          final missingCount = (entry.value - availableCount).clamp(0, 999);
          if (missingCount == 0) return null;
          return SmartShoppingItem(
            ingredient: ingredient,
            requirement: requirementsByIngredient[entry.key],
            requiredCount: entry.value,
            availableCount: availableCount,
            missingCount: missingCount,
            recipeNames: [recipeName],
          );
        })
        .whereType<SmartShoppingItem>()
        .toList();
  }

  Map<String, int> _getCombinedRequiredCounts(List<Recipe> recipes) {
    final combined = <String, int>{};
    for (final recipe in recipes) {
      final recipeCounts = _getRequiredCountsForRecipe(recipe);
      for (final entry in recipeCounts.entries) {
        combined.update(
          entry.key,
          (value) => value + entry.value,
          ifAbsent: () => entry.value,
        );
      }
    }
    return combined;
  }

  Map<String, int> _getRequiredCountsForRecipe(Recipe recipe) {
    final counts = <String, int>{};
    for (final requirement in recipe.ingredients.where(
      (ingredient) => !ingredient.isOptional,
    )) {
      counts.update(
        requirement.ingredientId,
        (value) => value + requirement.estimatedStockUnits,
        ifAbsent: () => requirement.estimatedStockUnits,
      );
    }
    return counts;
  }

  bool _isRecipeSuitableForMeal(String mealId, Recipe recipe) {
    switch (mealId) {
      case 'breakfast':
        return recipe.category == 'breakfast' ||
            recipe.category == 'beverage' ||
            _matchesAnyTag(
              recipe,
              ['kahvalti', 'kahvaltı', 'breakfast', 'brunch'],
            );
      case 'lunch':
        if (_matchesAnyTag(recipe, ['kahvalti', 'kahvaltı', 'breakfast'])) {
          return false;
        }
        return ['main', 'soup', 'salad', 'side', 'appetizer']
            .contains(recipe.category);
      case 'dinner':
      default:
        if (_matchesAnyTag(recipe, ['kahvalti', 'kahvaltı', 'breakfast'])) {
          return false;
        }
        return ['main', 'appetizer', 'salad', 'soup', 'side', 'dessert']
            .contains(recipe.category);
    }
  }

  bool _matchesAnyTag(Recipe recipe, List<String> expectedTags) {
    final recipeTags = recipe.tags.map(_normalizeText).toSet();
    for (final expectedTag in expectedTags) {
      if (recipeTags.contains(_normalizeText(expectedTag))) {
        return true;
      }
    }
    return false;
  }

  String _normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('û', 'u')
        .trim();
  }

  ReminderPreview? _nextReminderForSlot(MealRoutineSlot slot, DateTime now) {
    for (var dayOffset = 0; dayOffset < 8; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      final isWeekend = _isWeekend(date);
      final minutes = isWeekend ? slot.weekendMinutes : slot.weekdayMinutes;
      final mealAt = DateTime(
        date.year,
        date.month,
        date.day,
        minutes ~/ 60,
        minutes % 60,
      );
      final remindAt = mealAt.subtract(Duration(minutes: slot.leadMinutes));

      if (remindAt.isAfter(now)) {
        return ReminderPreview(
          mealId: slot.id,
          remindAt: remindAt,
          mealAt: mealAt,
          leadMinutes: slot.leadMinutes,
        );
      }
    }
    return null;
  }

  ReminderPreview? _nextMealForSlot(MealRoutineSlot slot, DateTime now) {
    for (var dayOffset = 0; dayOffset < 8; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      final isWeekend = _isWeekend(date);
      final minutes = isWeekend ? slot.weekendMinutes : slot.weekdayMinutes;
      final mealAt = DateTime(
        date.year,
        date.month,
        date.day,
        minutes ~/ 60,
        minutes % 60,
      );
      if (mealAt.isAfter(now)) {
        return ReminderPreview(
          mealId: slot.id,
          remindAt: mealAt.subtract(Duration(minutes: slot.leadMinutes)),
          mealAt: mealAt,
          leadMinutes: slot.leadMinutes,
        );
      }
    }
    return null;
  }

  bool _isWeekend(DateTime date) {
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  DateTime _nextSundayAt(int hour, int minute) {
    final now = DateTime.now();
    var daysUntilSunday = DateTime.sunday - now.weekday;
    if (daysUntilSunday < 0) {
      daysUntilSunday += 7;
    }
    var target = DateTime(
      now.year,
      now.month,
      now.day + daysUntilSunday,
      hour,
      minute,
    );
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 7));
    }
    return target;
  }

  DateTime _nextMorningAt(int hour, int minute) {
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, hour, minute);
    if (!target.isAfter(now)) {
      target = target.add(const Duration(days: 1));
    }
    return target;
  }

  Future<void> syncSmartKitchenNotifications() async {
    await _refreshSmartKitchenNotifications();
  }

  Future<void> _refreshSmartKitchenNotifications() async {
    final reminders =
        getUpcomingReminderPreviews(limit: 3).asMap().entries.map((entry) {
      final index = entry.key;
      final preview = entry.value;
      final plannedRecipes = getPlannedRecipes(preview.mealId);
      final recipeName = plannedRecipes.isEmpty
          ? null
          : plannedRecipes.length == 1
              ? plannedRecipes.first.getName(languageCode)
              : languageCode == 'tr'
                  ? '${plannedRecipes.length} tarif'
                  : '${plannedRecipes.length} recipes';
      final missingCount = plannedRecipes.isEmpty
          ? 0
          : getShoppingItemsForMeal(preview.mealId).fold<int>(
              0,
              (sum, item) => sum + item.missingCount,
            );
      final mealLabel = getPlannerMealLabel(preview.mealId);

      final title = languageCode == 'tr'
          ? '$mealLabel yaklaşıyor'
          : '$mealLabel is coming up';
      final body = languageCode == 'tr'
          ? recipeName == null
              ? '$mealLabel için önce menünü oluştur, sonra eksikleri birlikte hazırlayalım.'
              : '$recipeName planlandı. $missingCount eksik malzemeyi kontrol et.'
          : recipeName == null
              ? 'Create your $mealLabel menu first, then let us prepare the missing items.'
              : '$recipeName is planned. Check your $missingCount missing items.';

      return SmartReminderNotification(
        id: 7000 + index,
        title: title,
        body: body,
        scheduledAt: preview.remindAt,
      );
    }).toList();

    await NotificationService.instance.scheduleSmartKitchenReminders(reminders);

    final insightNotifications = <SmartReminderNotification>[];
    final digest = getWeeklyMenuDigest();
    if (digest.recipes.isNotEmpty) {
      insightNotifications.add(
        SmartReminderNotification(
          id: 9101,
          title: digest.title(languageCode),
          body: digest.body(languageCode),
          scheduledAt: _nextSundayAt(18, 0),
        ),
      );
    }

    final rescueSuggestion =
        wasteRescueSuggestions.isEmpty ? null : wasteRescueSuggestions.first;
    if (rescueSuggestion != null) {
      insightNotifications.add(
        SmartReminderNotification(
          id: 9102,
          title: rescueSuggestion.title(languageCode),
          body: rescueSuggestion.body(languageCode),
          scheduledAt: _nextMorningAt(9, 0),
        ),
      );
    }

    final actuellerSuggestion =
        _smartKitchenPreferences.campaignAlertsEnabled &&
                smartActuellerSuggestions.isNotEmpty
            ? smartActuellerSuggestions.first
            : null;
    if (actuellerSuggestion != null) {
      insightNotifications.add(
        SmartReminderNotification(
          id: 9103,
          title: actuellerSuggestion.title(languageCode),
          body: actuellerSuggestion.body(languageCode),
          scheduledAt: _nextMorningAt(10, 30),
        ),
      );
    }

    await NotificationService.instance.scheduleKitchenInsights(
      insightNotifications,
    );
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('language') ?? 'tr';
      _locale = Locale(langCode);
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      final favs = prefs.getStringList('favorites') ?? [];
      _favoriteRecipeIds.addAll(favs);
      final pantryRaw = prefs.getString('pantryItemCounts');
      if (pantryRaw != null && pantryRaw.isNotEmpty) {
        final decoded = json.decode(pantryRaw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final parsedValue = entry.value;
          if (parsedValue is num && parsedValue > 0) {
            _pantryItemCounts[entry.key] = parsedValue.round();
          }
        }
      } else {
        final selected = prefs.getStringList('selectedIngredients') ?? [];
        for (final ingredientId in selected) {
          _pantryItemCounts[ingredientId] = 1;
        }
      }

      final pantryDatesRaw = prefs.getString('pantryUpdatedAt');
      if (pantryDatesRaw != null && pantryDatesRaw.isNotEmpty) {
        final decoded = json.decode(pantryDatesRaw) as Map<String, dynamic>;
        for (final entry in decoded.entries) {
          final parsedDate = DateTime.tryParse(entry.value.toString());
          if (parsedDate != null) {
            _pantryUpdatedAt[entry.key] = parsedDate;
          }
        }
      }

      final smartKitchenRaw = prefs.getString('smartKitchenPreferences');
      if (smartKitchenRaw != null && smartKitchenRaw.isNotEmpty) {
        final decoded = json.decode(smartKitchenRaw) as Map<String, dynamic>;
        final loadedPrefs = SmartKitchenPreferences.fromJson(decoded);
        _smartKitchenPreferences = loadedPrefs.copyWith(
          mealSlots: _mergeSlotsWithDefaults(loadedPrefs.mealSlots),
        );
      }

      final kitchenRpgRaw = prefs.getString('kitchenRpgProfile');
      if (kitchenRpgRaw != null && kitchenRpgRaw.isNotEmpty) {
        _kitchenRpgProfile = KitchenRpgProfile.fromJson(
          json.decode(kitchenRpgRaw) as Map<String, dynamic>,
        );
      }

      _activeMoodId = prefs.getString('activeMoodId');
      final marketSyncRaw = prefs.getString('marketSyncStatus');
      if (marketSyncRaw != null && marketSyncRaw.isNotEmpty) {
        final decoded = json.decode(marketSyncRaw) as Map<String, dynamic>;
        _marketSyncStatus = MarketSyncStatus(
          isLoading: false,
          usedLiveData: decoded['usedLiveData'] as bool? ?? false,
          sourceLabel: decoded['sourceLabel']?.toString() ?? '',
          lastSyncedAt:
              DateTime.tryParse(decoded['lastSyncedAt']?.toString() ?? ''),
          message: decoded['message']?.toString(),
        );
      }
      final receiptRaw = prefs.getString('lastReceiptScanResult');
      if (receiptRaw != null && receiptRaw.isNotEmpty) {
        final decoded = json.decode(receiptRaw) as Map<String, dynamic>;
        final matchedIds =
            (decoded['matchedIds'] as List<dynamic>? ?? const <dynamic>[])
                .map((value) => value.toString())
                .toList();
        _lastReceiptScanResult = ReceiptScanResult(
          matchedIngredients: matchedIds
              .map(_recipeService.getIngredientById)
              .whereType<Ingredient>()
              .toList(),
          unmatchedLines:
              (decoded['unmatchedLines'] as List<dynamic>? ?? const [])
                  .map((value) => value.toString())
                  .toList(),
          confidence: (decoded['confidence'] as num?)?.toDouble() ?? 0,
          rawText: decoded['rawText']?.toString() ?? '',
          detectedStore: decoded['detectedStore']?.toString(),
          detectedLabels:
              (decoded['detectedLabels'] as List<dynamic>? ?? const [])
                  .map((value) => value.toString())
                  .toList(),
          capturedImagePath: decoded['capturedImagePath']?.toString(),
        );
      }

      final plateRaw = prefs.getString('lastPlateAnalysisResult');
      if (plateRaw != null && plateRaw.isNotEmpty) {
        final decoded = json.decode(plateRaw) as Map<String, dynamic>;
        final matchedRecipeIds =
            (decoded['recipeIds'] as List<dynamic>? ?? const <dynamic>[])
                .map((value) => value.toString())
                .toList();
        _lastPlateAnalysisResult = PlateAnalysisResult(
          headlineTr: decoded['headlineTr']?.toString() ?? '',
          headlineEn: decoded['headlineEn']?.toString() ?? '',
          summaryTr: decoded['summaryTr']?.toString() ?? '',
          summaryEn: decoded['summaryEn']?.toString() ?? '',
          suggestedMoodId: decoded['suggestedMoodId']?.toString() ?? 'comfort',
          shareCaptionTr: decoded['shareCaptionTr']?.toString() ?? '',
          shareCaptionEn: decoded['shareCaptionEn']?.toString() ?? '',
          matchedRecipes: matchedRecipeIds
              .map(_recipeService.getRecipeById)
              .whereType<Recipe>()
              .toList(),
          detectedLabels:
              (decoded['detectedLabels'] as List<dynamic>? ?? const [])
                  .map((value) => value.toString())
                  .toList(),
          estimatedCalories:
              (decoded['estimatedCalories'] as num?)?.round() ?? 0,
          analysisPrompt: decoded['analysisPrompt']?.toString() ?? '',
          capturedImagePath: decoded['capturedImagePath']?.toString(),
          confidence: (decoded['confidence'] as num?)?.toDouble() ?? 0,
        );
      }

      final actuellerRaw = prefs.getString('lastActuellerScanResult');
      if (actuellerRaw != null && actuellerRaw.isNotEmpty) {
        final decoded = json.decode(actuellerRaw) as Map<String, dynamic>;
        _lastActuellerScanResult = ActuellerScanResult.fromJson(
          decoded,
          _recipeService.getIngredientById,
        );
        _actuellerMarketQuotes = _smartActuellerService.toRemoteQuotes(
          _lastActuellerScanResult!,
        );
      }

      final actuellerSavingsRaw =
          prefs.getString('smartActuellerMonthlySavings');
      if (actuellerSavingsRaw != null && actuellerSavingsRaw.isNotEmpty) {
        final decoded =
            json.decode(actuellerSavingsRaw) as Map<String, dynamic>;
        _smartActuellerMonthlySavings =
            (decoded['value'] as num?)?.toDouble() ?? 0;
        _smartActuellerSavingsMonthKey = decoded['monthKey']?.toString();
        _trackedActuellerDealIds
          ..clear()
          ..addAll(
            (decoded['trackedDealIds'] as List<dynamic>? ?? const [])
                .map((value) => value.toString()),
          );
      }

      _lastActuellerCatalogSyncAt = DateTime.tryParse(
        prefs.getString('lastActuellerCatalogSyncAt') ?? '',
      );
      _lastActuellerCatalogBrochureCount =
          prefs.getInt('lastActuellerCatalogBrochureCount') ?? 0;
      _lastActuellerCatalogUrls =
          prefs.getStringList('lastActuellerCatalogUrls') ?? const [];
      final actuellerCatalogReportsRaw =
          prefs.getString('lastActuellerCatalogReports');
      if (actuellerCatalogReportsRaw != null &&
          actuellerCatalogReportsRaw.isNotEmpty) {
        _lastActuellerCatalogReports =
            (json.decode(actuellerCatalogReportsRaw) as List<dynamic>)
                .whereType<Map<String, dynamic>>()
                .map(ActuellerCatalogBrochureReport.fromJson)
                .toList();
      }
      _actuellerCatalogSyncMessage =
          prefs.getString('actuellerCatalogSyncMessage');

      _updateMatchingRecipes();
    } catch (_) {
      // Use defaults
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('language', _locale.languageCode);
      await prefs.setBool('darkMode', _isDarkMode);
      await prefs.setStringList('favorites', _favoriteRecipeIds.toList());
      await prefs.setStringList(
        'selectedIngredients',
        selectedIngredientIds.toList(),
      );
      await prefs.setString(
        'pantryItemCounts',
        json.encode(_pantryItemCounts),
      );
      await prefs.setString(
        'pantryUpdatedAt',
        json.encode(
          _pantryUpdatedAt.map(
            (key, value) => MapEntry(key, value.toIso8601String()),
          ),
        ),
      );
      await prefs.setString(
        'smartKitchenPreferences',
        json.encode(_smartKitchenPreferences.toJson()),
      );
      await prefs.setString(
        'kitchenRpgProfile',
        json.encode(_kitchenRpgProfile.toJson()),
      );
      await prefs.setString(
        'marketSyncStatus',
        json.encode({
          'usedLiveData': _marketSyncStatus.usedLiveData,
          'sourceLabel': _marketSyncStatus.sourceLabel,
          'lastSyncedAt': _marketSyncStatus.lastSyncedAt?.toIso8601String(),
          'message': _marketSyncStatus.message,
        }),
      );
      if (_activeMoodId == null) {
        await prefs.remove('activeMoodId');
      } else {
        await prefs.setString('activeMoodId', _activeMoodId!);
      }
      if (_lastReceiptScanResult == null) {
        await prefs.remove('lastReceiptScanResult');
      } else {
        await prefs.setString(
          'lastReceiptScanResult',
          json.encode({
            'matchedIds': _lastReceiptScanResult!.matchedIngredients
                .map((i) => i.id)
                .toList(),
            'unmatchedLines': _lastReceiptScanResult!.unmatchedLines,
            'confidence': _lastReceiptScanResult!.confidence,
            'rawText': _lastReceiptScanResult!.rawText,
            'detectedStore': _lastReceiptScanResult!.detectedStore,
            'detectedLabels': _lastReceiptScanResult!.detectedLabels,
            'capturedImagePath': _lastReceiptScanResult!.capturedImagePath,
          }),
        );
      }
      if (_lastPlateAnalysisResult == null) {
        await prefs.remove('lastPlateAnalysisResult');
      } else {
        await prefs.setString(
          'lastPlateAnalysisResult',
          json.encode({
            'headlineTr': _lastPlateAnalysisResult!.headlineTr,
            'headlineEn': _lastPlateAnalysisResult!.headlineEn,
            'summaryTr': _lastPlateAnalysisResult!.summaryTr,
            'summaryEn': _lastPlateAnalysisResult!.summaryEn,
            'suggestedMoodId': _lastPlateAnalysisResult!.suggestedMoodId,
            'shareCaptionTr': _lastPlateAnalysisResult!.shareCaptionTr,
            'shareCaptionEn': _lastPlateAnalysisResult!.shareCaptionEn,
            'recipeIds': _lastPlateAnalysisResult!.matchedRecipes
                .map((r) => r.id)
                .toList(),
            'detectedLabels': _lastPlateAnalysisResult!.detectedLabels,
            'estimatedCalories': _lastPlateAnalysisResult!.estimatedCalories,
            'analysisPrompt': _lastPlateAnalysisResult!.analysisPrompt,
            'capturedImagePath': _lastPlateAnalysisResult!.capturedImagePath,
            'confidence': _lastPlateAnalysisResult!.confidence,
          }),
        );
      }
      if (_lastActuellerScanResult == null) {
        await prefs.remove('lastActuellerScanResult');
      } else {
        await prefs.setString(
          'lastActuellerScanResult',
          json.encode(_lastActuellerScanResult!.toJson()),
        );
      }
      await prefs.setString(
        'smartActuellerMonthlySavings',
        json.encode({
          'value': _smartActuellerMonthlySavings,
          'monthKey': _smartActuellerSavingsMonthKey,
          'trackedDealIds': _trackedActuellerDealIds.toList(),
        }),
      );
      if (_lastActuellerCatalogSyncAt == null) {
        await prefs.remove('lastActuellerCatalogSyncAt');
      } else {
        await prefs.setString(
          'lastActuellerCatalogSyncAt',
          _lastActuellerCatalogSyncAt!.toIso8601String(),
        );
      }
      await prefs.setInt(
        'lastActuellerCatalogBrochureCount',
        _lastActuellerCatalogBrochureCount,
      );
      await prefs.setStringList(
        'lastActuellerCatalogUrls',
        _lastActuellerCatalogUrls,
      );
      await prefs.setString(
        'lastActuellerCatalogReports',
        json.encode(
          _lastActuellerCatalogReports
              .map((report) => report.toJson())
              .toList(),
        ),
      );
      if (_actuellerCatalogSyncMessage == null ||
          _actuellerCatalogSyncMessage!.isEmpty) {
        await prefs.remove('actuellerCatalogSyncMessage');
      } else {
        await prefs.setString(
          'actuellerCatalogSyncMessage',
          _actuellerCatalogSyncMessage!,
        );
      }
    } catch (_) {
      // Ignore save errors
    }
  }

  String _monthKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}';

  bool _shouldSyncActuellerCatalog(
    DateTime now, {
    int dailyHour = _actuellerDailySyncHour,
  }) {
    if (_lastActuellerCatalogSyncAt == null) {
      return _lastActuellerScanResult == null || now.hour >= dailyHour;
    }
    final last = _lastActuellerCatalogSyncAt!.toLocal();
    final isSameDay =
        last.year == now.year && last.month == now.month && last.day == now.day;
    if (isSameDay) {
      return false;
    }
    return now.hour >= dailyHour;
  }

  List<MealRoutineSlot> _mergeSlotsWithDefaults(List<MealRoutineSlot> slots) {
    final defaults = SmartKitchenPreferences.defaults().mealSlots;
    return defaults.map((defaultSlot) {
      try {
        return slots.firstWhere((slot) => slot.id == defaultSlot.id);
      } catch (_) {
        return defaultSlot;
      }
    }).toList();
  }

  // ── OCR kalite filtresi ──────────────────────────────────────────

  /// Fiyat kalıbı: "123,50 TL" veya "123.50 TL" veya "1.299,00 TL" gibi
  static final _ocrPricePattern = RegExp(
    r'[\d.,]+\s*TL\s*$',
    caseSensitive: false,
  );

  /// Çöp kalıplar: sadece fiyat ("t42.50"), slogan, bitişik/bozuk metin
  static final _ocrGarbagePatterns = [
    RegExp(r'^t\d'), // "t17.999", "t42.50"
    RegExp(r'EN BÜYÜK', caseSensitive: false), // slogan
    RegExp(r'ART.ya Özel', caseSensitive: false), // reklam
    RegExp(r'ZINCiRİ|ZİNCİRİ', caseSensitive: false),
    RegExp(r'ANOT[Ốô]', caseSensitive: false), // bozuk karakter
    RegExp(r'garanti', caseSensitive: false), // "2yıl garanti"
    RegExp(r'alışverişinizde', caseSensitive: false),
    RegExp(r'^\*'), // "*Ocak doğal gaza…"
    RegExp(r'^\d+\s*TL\s*$'), // sadece fiyat: "50 TL"
    RegExp(r'^[%\d.,\s]+$'), // sadece sayı/yüzde
    RegExp(r'HDmr|HDR\s+\d', caseSensitive: false), // bozuk TV spec metni
    RegExp(r'KAPSÜL', caseSensitive: false), // reklam: "50 KAPSÜL"
    RegExp(r'Dahili\s+\d', caseSensitive: false), // "Dahili 3x..."
    RegExp(r'GOYaKredi|Yapıkredi', caseSensitive: false), // banka reklam
    RegExp(r'^\d+[.,]\d{3}\s*$'), // "32.999" tek fiyat
  ];

  /// OCR'dan gelen ham metni satır bazlı filtreler, çöp satırları atar.
  String _filterOcrLines(String ocrText) {
    final lines = ocrText.split('\n');
    final kept = <String>[];
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      if (_isUsableOcrLine(trimmed)) {
        kept.add(trimmed);
      }
    }
    return kept.join('\n');
  }

  /// Tek bir OCR satırının kullanılabilir olup olmadığını kontrol eder.
  bool _isUsableOcrLine(String line) {
    // Çok kısa satırlar genelde çöp (< 10 karakter)
    if (line.length < 10) return false;

    // Bilinen çöp kalıpları
    for (final pattern in _ocrGarbagePatterns) {
      if (pattern.hasMatch(line)) return false;
    }

    // En az 2 kelime + fiyat kalıbı olan satırları tut
    final words =
        line.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length < 2) return false;

    // Fiyat kalıbı varsa kesinlikle tut
    if (_ocrPricePattern.hasMatch(line)) return true;

    // Fiyat kalıbı yoksa ama en az 3 kelime ve bitişik karakter yok → tut
    if (words.length >= 3) {
      // Bitişik kelime kontrolü (ör: "sütlüÇlkolatalı")
      final hasGlued = words.any(
        (w) => RegExp(r'[a-zçğıöşü][A-ZÇĞİÖŞÜ]').hasMatch(w),
      );
      if (!hasGlued) return true;
    }

    return false;
  }

  /// OCR bloğunun kullanılabilir olup olmadığını kontrol eder.
  bool _isUsableOcrBlock(String block) {
    return _isUsableOcrLine(block.trim());
  }
}
