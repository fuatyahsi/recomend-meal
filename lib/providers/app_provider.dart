import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/recipe.dart';
import '../models/smart_kitchen.dart';
import '../services/notification_service.dart';
import '../services/recipe_service.dart';

class AppProvider extends ChangeNotifier {
  final RecipeService _recipeService = RecipeService();

  bool _isLoading = true;
  Locale _locale = const Locale('tr');
  bool _isDarkMode = false;
  final Map<String, int> _pantryItemCounts = {};
  final Set<String> _favoriteRecipeIds = {};
  List<RecipeMatch> _matchingRecipes = [];
  SmartKitchenPreferences _smartKitchenPreferences =
      SmartKitchenPreferences.defaults();

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
    _isLoading = false;
    notifyListeners();
  }

  void setLocale(Locale locale) {
    _locale = locale;
    _savePreferences();
    _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  void toggleLanguage() {
    _locale = _locale.languageCode == 'tr'
        ? const Locale('en')
        : const Locale('tr');
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
    } else {
      _pantryItemCounts[ingredientId] = 1;
    }
    _persistPantryState();
  }

  void incrementIngredient(String ingredientId) {
    _pantryItemCounts[ingredientId] = getIngredientCount(ingredientId) + 1;
    _persistPantryState();
  }

  void decrementIngredient(String ingredientId) {
    final currentCount = getIngredientCount(ingredientId);
    if (currentCount <= 1) {
      _pantryItemCounts.remove(ingredientId);
    } else {
      _pantryItemCounts[ingredientId] = currentCount - 1;
    }
    _persistPantryState();
  }

  int getIngredientCount(String ingredientId) {
    return _pantryItemCounts[ingredientId] ?? 0;
  }

  void _persistPantryState() {
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

  List<PersonalizedRecipeSuggestion> getPersonalizedSuggestions({
    String? mealId,
    int limit = 3,
  }) {
    final targetMealId = mealId ?? getNextPlannedMealId();

    final suggestions = _recipeService.recipes
        .where((recipe) => _isRecipeSuitableForMeal(targetMealId, recipe))
        .map((recipe) {
      final missingItems = _getMissingItemsForRecipe(recipe);
      final matchPercent = _getRecipeCoveragePercent(recipe);
      final canCookNow = missingItems.isEmpty;
      final categoryBonus =
          _preferredCategoriesForMeal(targetMealId).contains(recipe.category)
              ? 40
              : 0;
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
      final score =
          categoryBonus + pantryBonus + speedBonus + difficultyBonus;

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
        .where((suggestion) => !selectedRecipeIds.contains(suggestion.recipe.id))
        .take(limit)
        .toList();
  }

  Future<void> consumePlannedRecipesForMeal(String mealId) async {
    final recipes = getPlannedRecipes(mealId);
    if (recipes.isEmpty) return;

    final requiredCounts = _getCombinedRequiredCounts(recipes);
    for (final entry in requiredCounts.entries) {
      final currentCount = getIngredientCount(entry.key);
      if (currentCount <= 0) continue;
      final nextCount = currentCount - entry.value;
      if (nextCount > 0) {
        _pantryItemCounts[entry.key] = nextCount;
      } else {
        _pantryItemCounts.remove(entry.key);
      }
    }

    _updateMatchingRecipes();
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
        weekdayMinutes:
            isWeekend ? slot.weekdayMinutes : minutesAfterMidnight,
        weekendMinutes:
            isWeekend ? minutesAfterMidnight : slot.weekendMinutes,
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
    await _savePreferences();
    await _refreshSmartKitchenNotifications();
    notifyListeners();
  }

  Future<void> removePlannedRecipeForMeal(String mealId, String recipeId) async {
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

    return combinedCounts.entries.map((entry) {
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
        recipeNames: (recipeNamesByIngredient[entry.key] ?? const <String>{})
            .toList()
          ..sort(),
      );
    }).whereType<SmartShoppingItem>().toList()
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

    return requiredCounts.entries.map((entry) {
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
    }).whereType<SmartShoppingItem>().toList();
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
    return date.weekday == DateTime.saturday ||
        date.weekday == DateTime.sunday;
  }

  Future<void> syncSmartKitchenNotifications() async {
    await _refreshSmartKitchenNotifications();
  }

  Future<void> _refreshSmartKitchenNotifications() async {
    final reminders = getUpcomingReminderPreviews(limit: 3)
        .asMap()
        .entries
        .map((entry) {
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
        })
        .toList();

    await NotificationService.instance.scheduleSmartKitchenReminders(reminders);
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

      final smartKitchenRaw = prefs.getString('smartKitchenPreferences');
      if (smartKitchenRaw != null && smartKitchenRaw.isNotEmpty) {
        final decoded = json.decode(smartKitchenRaw) as Map<String, dynamic>;
        final loadedPrefs = SmartKitchenPreferences.fromJson(decoded);
        _smartKitchenPreferences = loadedPrefs.copyWith(
          mealSlots: _mergeSlotsWithDefaults(loadedPrefs.mealSlots),
        );
      }

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
        'smartKitchenPreferences',
        json.encode(_smartKitchenPreferences.toJson()),
      );
    } catch (_) {
      // Ignore save errors
    }
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
}
