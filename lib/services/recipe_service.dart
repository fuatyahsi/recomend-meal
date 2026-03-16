import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/ingredient.dart';
import '../models/recipe.dart';

class RecipeService {
  List<Ingredient> _ingredients = [];
  List<Recipe> _recipes = [];
  bool _isLoaded = false;

  List<Ingredient> get ingredients => _ingredients;
  List<Recipe> get recipes => _recipes;

  Future<void> loadData() async {
    if (_isLoaded) return;

    // Load ingredients
    final ingredientsJson =
        await rootBundle.loadString('assets/data/ingredients.json');
    final List<dynamic> ingredientsList = json.decode(ingredientsJson);
    _ingredients =
        ingredientsList.map((e) => Ingredient.fromJson(e)).toList();

    // Load recipes
    final recipeFiles = [
      'assets/data/recipes.json',
      'assets/data/recipes_extra.json',
    ];
    final recipeMaps = <Map<String, dynamic>>[];

    for (final recipeFile in recipeFiles) {
      final recipesJson = await rootBundle.loadString(recipeFile);
      final List<dynamic> recipesList = json.decode(recipesJson);
      recipeMaps.addAll(
        recipesList.map((entry) => entry as Map<String, dynamic>),
      );
    }

    _recipes = recipeMaps.map(Recipe.fromJson).toList();

    _isLoaded = true;
  }

  /// Get ingredients grouped by category
  Map<String, List<Ingredient>> getIngredientsByCategory() {
    final Map<String, List<Ingredient>> grouped = {};
    for (final ingredient in _ingredients) {
      grouped.putIfAbsent(ingredient.category, () => []);
      grouped[ingredient.category]!.add(ingredient);
    }
    return grouped;
  }

  /// Search ingredients by name
  List<Ingredient> searchIngredients(String query, String locale) {
    if (query.isEmpty) return _ingredients;
    final lowerQuery = query.toLowerCase();
    return _ingredients.where((ing) {
      return ing.getName(locale).toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get recipes sorted by match percentage (best match first)
  List<RecipeMatch> getMatchingRecipes(List<String> userIngredientIds) {
    if (userIngredientIds.isEmpty) return [];

    final matches = _recipes.map((recipe) {
      final percentage = recipe.getMatchPercentage(userIngredientIds);
      final missing = recipe.getMissingIngredients(userIngredientIds);
      return RecipeMatch(
        recipe: recipe,
        matchPercentage: percentage,
        missingIngredients: missing,
        canMake: recipe.canMakeWith(userIngredientIds),
      );
    }).toList();

    // Filter out recipes with 0% match
    matches.removeWhere((m) => m.matchPercentage == 0);

    // Sort: full matches first, then by percentage descending
    matches.sort((a, b) {
      if (a.canMake && !b.canMake) return -1;
      if (!a.canMake && b.canMake) return 1;
      return b.matchPercentage.compareTo(a.matchPercentage);
    });

    return matches;
  }

  /// Get ingredient name by ID
  Ingredient? getIngredientById(String id) {
    try {
      return _ingredients.firstWhere((ing) => ing.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get recipe by ID
  Recipe? getRecipeById(String id) {
    try {
      return _recipes.firstWhere((recipe) => recipe.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get recipes by category
  List<Recipe> getRecipesByCategory(String category) {
    return _recipes.where((r) => r.category == category).toList();
  }
}

class RecipeMatch {
  final Recipe recipe;
  final double matchPercentage;
  final List<RecipeIngredient> missingIngredients;
  final bool canMake;

  const RecipeMatch({
    required this.recipe,
    required this.matchPercentage,
    required this.missingIngredients,
    required this.canMake,
  });

  int get matchPercent => (matchPercentage * 100).round();
}
