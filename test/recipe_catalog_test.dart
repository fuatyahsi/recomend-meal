import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  List<Map<String, dynamic>> loadRecipes(String path) {
    final raw = File(path).readAsStringSync();
    return (json.decode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  List<Map<String, dynamic>> loadIngredients(String path) {
    final raw = File(path).readAsStringSync();
    return (json.decode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }

  test('recipe catalog reaches 100 recipes', () {
    final baseRecipes = loadRecipes('assets/data/recipes.json');
    final extraRecipes = loadRecipes('assets/data/recipes_extra.json');

    expect(baseRecipes.length, 65);
    expect(extraRecipes.length, 35);
    expect(baseRecipes.length + extraRecipes.length, 100);
  });

  test('ingredient catalog reaches 200 ingredients', () {
    final baseIngredients = loadIngredients('assets/data/ingredients.json');
    final extraIngredients =
        loadIngredients('assets/data/ingredients_extra.json');

    expect(baseIngredients.length, 77);
    expect(extraIngredients.length, 135);
    expect(baseIngredients.length + extraIngredients.length, 212);
  });

  test('romantic tagged recipes stay dinner-friendly', () {
    final baseRecipes = loadRecipes('assets/data/recipes.json');
    final extraRecipes = loadRecipes('assets/data/recipes_extra.json');
    final allRecipes = [...baseRecipes, ...extraRecipes];

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
}
