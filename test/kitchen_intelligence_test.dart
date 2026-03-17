import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_chef/models/ingredient.dart';
import 'package:fridge_chef/models/kitchen_rpg.dart';
import 'package:fridge_chef/models/smart_kitchen.dart';
import 'package:fridge_chef/services/kitchen_intelligence_service.dart';
import 'package:fridge_chef/services/kitchen_rpg_service.dart';

void main() {
  group('Kitchen intelligence', () {
    final service = KitchenIntelligenceService();

    test('receipt scan matches pantry ingredients from raw text', () {
      const ingredients = [
        Ingredient(
          id: 'tomato',
          nameTr: 'Domates',
          nameEn: 'Tomato',
          category: IngredientCategory.vegetables,
          icon: 'T',
        ),
        Ingredient(
          id: 'egg',
          nameTr: 'Yumurta',
          nameEn: 'Egg',
          category: IngredientCategory.other,
          icon: 'E',
        ),
      ];

      final result = service.analyzeReceiptText(
        'Domates\nYumurta\nBilinmeyen Urun',
        ingredients,
        'tr',
      );

      expect(result.matchedIngredients.length, 2);
      expect(result.unmatchedLines, contains('Bilinmeyen Urun'));
      expect(result.confidence, greaterThan(0.5));
    });

    test('receipt scan filters receipt noise and matches market receipt lines',
        () {
      const ingredients = [
        Ingredient(
          id: 'tomato',
          nameTr: 'Domates',
          nameEn: 'Tomato',
          category: IngredientCategory.vegetables,
          icon: 'T',
        ),
        Ingredient(
          id: 'egg',
          nameTr: 'Yumurta',
          nameEn: 'Egg',
          category: IngredientCategory.other,
          icon: 'E',
        ),
        Ingredient(
          id: 'cheese_kashar',
          nameTr: 'Kasar Peyniri',
          nameEn: 'Kashar Cheese',
          category: IngredientCategory.dairy,
          icon: 'C',
        ),
      ];

      final result = service.analyzeReceiptText(
        'MIGROS TIC A.S.\n'
            'TARIH 17.03.2026\n'
            'DOMATES 1 KG 42,95\n'
            'YUMURTA 10 LU M 64,50\n'
            'KASAR PEYNIRI 400 G 129,90\n'
            'TOPLAM 237,35',
        ingredients,
        'tr',
      );

      expect(
        result.matchedIngredients.map((ingredient) => ingredient.id),
        containsAll(['tomato', 'egg', 'cheese_kashar']),
      );
      expect(result.unmatchedLines, isEmpty);
      expect(result.confidence, greaterThan(0.7));
    });

    test('receipt scan tolerates common OCR token loss', () {
      const ingredients = [
        Ingredient(
          id: 'egg',
          nameTr: 'Yumurta',
          nameEn: 'Egg',
          category: IngredientCategory.other,
          icon: 'E',
        ),
        Ingredient(
          id: 'olive_oil',
          nameTr: 'Zeytinyagi',
          nameEn: 'Olive Oil',
          category: IngredientCategory.oils,
          icon: 'O',
        ),
        Ingredient(
          id: 'chicken_breast',
          nameTr: 'Tavuk Gogsu',
          nameEn: 'Chicken Breast',
          category: IngredientCategory.meat,
          icon: 'C',
        ),
      ];

      final result = service.analyzeReceiptText(
        'YUMRTA 10 LU\nZEYTNYAGI NAT SIZMA\nTAVK GOGSU',
        ingredients,
        'tr',
      );

      expect(
        result.matchedIngredients.map((ingredient) => ingredient.id),
        containsAll(['egg', 'olive_oil', 'chicken_breast']),
      );
      expect(result.confidence, greaterThan(0.55));
    });

    test('flavor pairings surface known pantry combinations', () {
      final suggestions = service.buildFlavorPairings({
        'salmon',
        'capers',
      });

      expect(suggestions, isNotEmpty);
      expect(suggestions.first.score, greaterThanOrEqualTo(90));
    });

    test('market comparison sorts cheapest basket first', () {
      const ingredient = Ingredient(
        id: 'tomato',
        nameTr: 'Domates',
        nameEn: 'Tomato',
        category: IngredientCategory.vegetables,
        icon: 'T',
      );
      const item = SmartShoppingItem(
        ingredient: ingredient,
        requiredCount: 2,
        availableCount: 0,
        missingCount: 2,
      );

      final comparisons = service.buildMarketComparisons([item]);

      expect(comparisons.length, greaterThan(2));
      expect(
        comparisons.first.totalPrice <= comparisons.last.totalPrice,
        isTrue,
      );
    });
  });

  group('Kitchen RPG', () {
    final service = KitchenRpgService();

    test('activities build xp and unlock streak badge', () {
      var profile = KitchenRpgProfile.initial(DateTime(2026, 3, 17));
      profile = service.registerActivity(
        profile,
        KitchenActivityType.pantrySync,
        now: DateTime(2026, 3, 17, 9),
      );
      profile = service.registerActivity(
        profile,
        KitchenActivityType.mealPlan,
        now: DateTime(2026, 3, 18, 9),
      );
      profile = service.registerActivity(
        profile,
        KitchenActivityType.menuCooked,
        now: DateTime(2026, 3, 19, 9),
      );

      expect(profile.level, greaterThanOrEqualTo(1));
      expect(profile.streakDays, 3);
      expect(profile.unlockedBadges, contains('streak_3'));
    });
  });
}
