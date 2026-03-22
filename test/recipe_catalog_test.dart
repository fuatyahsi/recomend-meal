import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_chef/utils/catalog_expansion.dart';

void main() {
  List<Map<String, dynamic>> loadRecipes(String path) {
    final raw = File(path).readAsStringSync();
    return (json.decode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> loadIngredients(String path) {
    final raw = File(path).readAsStringSync();
    return (json.decode(raw) as List<dynamic>).cast<Map<String, dynamic>>();
  }

  test('recipe catalog reaches 200 unique recipes', () {
    final baseRecipes = loadRecipes('assets/data/recipes.json');
    final extraRecipes = loadRecipes('assets/data/recipes_extra.json');
    final allRecipes = expandRecipeCatalog([...baseRecipes, ...extraRecipes]);

    expect(baseRecipes.length, 65);
    expect(extraRecipes.length, 35);
    expect(allRecipes.length, 200);
  });

  test('ingredient catalog reaches 424 ingredients', () {
    final baseIngredients = loadIngredients('assets/data/ingredients.json');
    final extraIngredients =
        loadIngredients('assets/data/ingredients_extra.json');
    final allIngredients = expandIngredientCatalog([
      ...baseIngredients,
      ...extraIngredients,
    ]);

    expect(baseIngredients.length, 77);
    expect(extraIngredients.length, 135);
    expect(allIngredients.length, 424);
  });

  test('romantic tagged recipes stay dinner-friendly', () {
    final baseRecipes = loadRecipes('assets/data/recipes.json');
    final extraRecipes = loadRecipes('assets/data/recipes_extra.json');
    final allRecipes = expandRecipeCatalog([...baseRecipes, ...extraRecipes]);

    final romanticRecipes = allRecipes.where((recipe) {
      final tags =
          (recipe['tags'] as List<dynamic>? ?? const []).cast<String>();
      return tags.any(
        (tag) => tag.contains('romantik') || tag.contains('özel-aksam'),
      );
    }).toList();

    expect(romanticRecipes.length, greaterThanOrEqualTo(5));
    for (final recipe in romanticRecipes) {
      expect(
        ['main', 'dessert', 'appetizer', 'salad'].contains(recipe['category']),
        isTrue,
      );
    }
  });

  test('recipe catalog does not keep duplicate content with different names',
      () {
    final baseRecipes = loadRecipes('assets/data/recipes.json');
    final extraRecipes = loadRecipes('assets/data/recipes_extra.json');
    final allRecipes = expandRecipeCatalog([...baseRecipes, ...extraRecipes]);

    final signatures = allRecipes.map(buildRecipeContentSignature).toList();

    expect(signatures.toSet().length, signatures.length);
  });

  test('recipe catalog does not repeat visible Turkish recipe names', () {
    final baseRecipes = loadRecipes('assets/data/recipes.json');
    final extraRecipes = loadRecipes('assets/data/recipes_extra.json');
    final allRecipes = expandRecipeCatalog([...baseRecipes, ...extraRecipes]);

    final normalizedNames = allRecipes
        .map(
          (recipe) => (recipe['name_tr'] ?? '').toString().trim().toLowerCase(),
        )
        .toList();

    expect(normalizedNames.toSet().length, normalizedNames.length);
  });
}
