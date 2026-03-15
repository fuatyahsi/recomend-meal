import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/smart_kitchen.dart';
import '../services/recipe_service.dart';

class AppProvider extends ChangeNotifier {
  final RecipeService _recipeService = RecipeService();

  // State
  bool _isLoading = true;
  Locale _locale = const Locale('tr');
  bool _isDarkMode = false;
  final Set<String> _selectedIngredientIds = {};
  final Set<String> _favoriteRecipeIds = {};
  List<RecipeMatch> _matchingRecipes = [];
  SmartKitchenPreferences _smartKitchenPreferences =
      SmartKitchenPreferences.defaults();

  // Getters
  bool get isLoading => _isLoading;
  Locale get locale => _locale;
  String get languageCode => _locale.languageCode;
  bool get isDarkMode => _isDarkMode;
  RecipeService get recipeService => _recipeService;
  Set<String> get selectedIngredientIds => _selectedIngredientIds;
  Set<String> get favoriteRecipeIds => _favoriteRecipeIds;
  List<RecipeMatch> get matchingRecipes => _matchingRecipes;
  int get selectedCount => _selectedIngredientIds.length;
  SmartKitchenPreferences get smartKitchenPreferences =>
      _smartKitchenPreferences;

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
    _isLoading = false;
    notifyListeners();
  }

  // --- Language ---
  void setLocale(Locale locale) {
    _locale = locale;
    _savePreferences();
    notifyListeners();
  }

  void toggleLanguage() {
    _locale = _locale.languageCode == 'tr'
        ? const Locale('en')
        : const Locale('tr');
    _savePreferences();
    notifyListeners();
  }

  // --- Dark Mode ---
  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    _savePreferences();
    notifyListeners();
  }

  // --- Ingredient Selection ---
  void toggleIngredient(String ingredientId) {
    if (_selectedIngredientIds.contains(ingredientId)) {
      _selectedIngredientIds.remove(ingredientId);
    } else {
      _selectedIngredientIds.add(ingredientId);
    }
    _updateMatchingRecipes();
    _savePreferences();
    notifyListeners();
  }

  bool isIngredientSelected(String ingredientId) {
    return _selectedIngredientIds.contains(ingredientId);
  }

  void clearSelectedIngredients() {
    _selectedIngredientIds.clear();
    _matchingRecipes = [];
    _savePreferences();
    notifyListeners();
  }

  // --- Recipes ---
  void _updateMatchingRecipes() {
    _matchingRecipes = _recipeService
        .getMatchingRecipes(_selectedIngredientIds.toList());
  }

  void findRecipes() {
    _updateMatchingRecipes();
    notifyListeners();
  }

  // --- Favorites ---
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

  // --- Smart Kitchen Planner ---
  List<PersonalizedRecipeSuggestion> getPersonalizedSuggestions({
    String? mealId,
    int limit = 3,
  }) {
    final targetMealId = mealId ?? getNextPlannedMealId();
    final selectedIds = _selectedIngredientIds.toList();

    final suggestions = _recipeService.recipes.map((recipe) {
      final missingItems = recipe
          .getMissingIngredients(selectedIds)
          .map((requirement) {
            final ingredient =
                _recipeService.getIngredientById(requirement.ingredientId);
            if (ingredient == null) return null;
            return SmartShoppingItem(
              ingredient: ingredient,
              requirement: requirement,
            );
          })
          .whereType<SmartShoppingItem>()
          .toList();

      final matchPercent = selectedIds.isEmpty
          ? 0
          : (recipe.getMatchPercentage(selectedIds) * 100).round();
      final canCookNow = recipe.canMakeWith(selectedIds);
      final categoryBonus =
          _preferredCategoriesForMeal(targetMealId).contains(recipe.category)
              ? 40
              : 0;
      final pantryBonus = canCookNow
          ? 36
          : selectedIds.isEmpty
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

  Future<void> setMealSlotEnabled(String mealId, bool enabled) async {
    final slot = _smartKitchenPreferences.slotById(mealId);
    _smartKitchenPreferences =
        _smartKitchenPreferences.replaceSlot(slot.copyWith(enabled: enabled));
    await _savePreferences();
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
    notifyListeners();
  }

  Future<void> setMealLeadMinutes(String mealId, int minutes) async {
    final slot = _smartKitchenPreferences.slotById(mealId);
    _smartKitchenPreferences = _smartKitchenPreferences.replaceSlot(
      slot.copyWith(leadMinutes: minutes),
    );
    await _savePreferences();
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

  List<String> getSmartShoppingSummary(String mealId) {
    final suggestions = getPersonalizedSuggestions(mealId: mealId, limit: 1);
    if (suggestions.isEmpty) return const [];
    return suggestions.first.missingItems.map((item) {
      return '${item.ingredient.getName(languageCode)} • '
          '${item.requirement.getAmount(languageCode)}';
    }).toList();
  }

  String getMealLabel(String mealId) {
    switch (mealId) {
      case 'breakfast':
        return languageCode == 'tr' ? 'Kahvalti' : 'Breakfast';
      case 'lunch':
        return languageCode == 'tr' ? 'Oglen' : 'Lunch';
      case 'dinner':
      default:
        return languageCode == 'tr' ? 'Aksam' : 'Dinner';
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

  ReminderPreview? _nextReminderForSlot(MealRoutineSlot slot, DateTime now) {
    for (var dayOffset = 0; dayOffset < 8; dayOffset++) {
      final date = now.add(Duration(days: dayOffset));
      final isWeekend = _isWeekend(date);
      final minutes =
          isWeekend ? slot.weekendMinutes : slot.weekdayMinutes;
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
      final minutes =
          isWeekend ? slot.weekendMinutes : slot.weekdayMinutes;
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

  // --- Persistence ---
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('language') ?? 'tr';
      _locale = Locale(langCode);
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      final favs = prefs.getStringList('favorites') ?? [];
      _favoriteRecipeIds.addAll(favs);
      final selected = prefs.getStringList('selectedIngredients') ?? [];
      _selectedIngredientIds.addAll(selected);

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
        _selectedIngredientIds.toList(),
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
    return defaults
        .map((defaultSlot) {
          try {
            return slots.firstWhere((slot) => slot.id == defaultSlot.id);
          } catch (_) {
            return defaultSlot;
          }
        })
        .toList();
  }
}
