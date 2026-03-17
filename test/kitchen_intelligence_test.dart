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
