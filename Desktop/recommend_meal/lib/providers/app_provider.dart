import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/ingredient.dart';
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

  Future<void> initialize() async {
    await _recipeService.loadData();
    await _loadPreferences();
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
    notifyListeners();
  }

  bool isIngredientSelected(String ingredientId) {
    return _selectedIngredientIds.contains(ingredientId);
  }

  void clearSelectedIngredients() {
    _selectedIngredientIds.clear();
    _matchingRecipes = [];
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

  // --- Persistence ---
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final langCode = prefs.getString('language') ?? 'tr';
      _locale = Locale(langCode);
      _isDarkMode = prefs.getBool('darkMode') ?? false;
      final favs = prefs.getStringList('favorites') ?? [];
      _favoriteRecipeIds.addAll(favs);
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
    } catch (_) {
      // Ignore save errors
    }
  }
}
