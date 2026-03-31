import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_chef/models/ingredient.dart';
import 'package:fridge_chef/models/kitchen_intelligence.dart';
import 'package:fridge_chef/models/kitchen_rpg.dart';
import 'package:fridge_chef/models/recipe.dart';
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

    test('surprise basket splits the route by cheapest market', () {
      const tomato = Ingredient(
        id: 'tomato',
        nameTr: 'Domates',
        nameEn: 'Tomato',
        category: IngredientCategory.vegetables,
        icon: 'T',
      );
      const milk = Ingredient(
        id: 'milk',
        nameTr: 'Süt',
        nameEn: 'Milk',
        category: IngredientCategory.dairy,
        icon: 'M',
      );
      const tomatoItem = SmartShoppingItem(
        ingredient: tomato,
        requiredCount: 1,
        availableCount: 0,
        missingCount: 1,
      );
      const milkItem = SmartShoppingItem(
        ingredient: milk,
        requiredCount: 1,
        availableCount: 0,
        missingCount: 1,
      );

      final plan = service.buildSurpriseBasketPlan(
        shoppingItems: const [tomatoItem, milkItem],
        comparisons: const [
          MarketBasketComparison(
            market: 'A101',
            deals: [
              MarketItemDeal(
                shoppingItem: tomatoItem,
                market: 'A101',
                unitPrice: 20,
                totalPrice: 20,
                isCampaign: true,
                isLiveData: true,
                campaignLabelTr: 'Kampanya',
                campaignLabelEn: 'Campaign',
              ),
              MarketItemDeal(
                shoppingItem: milkItem,
                market: 'A101',
                unitPrice: 32,
                totalPrice: 32,
                isCampaign: false,
                isLiveData: true,
                campaignLabelTr: 'Raf',
                campaignLabelEn: 'Shelf',
              ),
            ],
            totalPrice: 52,
            campaignCount: 1,
            estimatedSavingsVsHighest: 0,
            isLiveData: true,
            sourceLabel: 'fixture',
          ),
          MarketBasketComparison(
            market: 'ŞOK',
            deals: [
              MarketItemDeal(
                shoppingItem: tomatoItem,
                market: 'ŞOK',
                unitPrice: 24,
                totalPrice: 24,
                isCampaign: false,
                isLiveData: true,
                campaignLabelTr: 'Raf',
                campaignLabelEn: 'Shelf',
              ),
              MarketItemDeal(
                shoppingItem: milkItem,
                market: 'ŞOK',
                unitPrice: 18,
                totalPrice: 18,
                isCampaign: true,
                isLiveData: true,
                campaignLabelTr: 'Kampanya',
                campaignLabelEn: 'Campaign',
              ),
            ],
            totalPrice: 42,
            campaignCount: 1,
            estimatedSavingsVsHighest: 10,
            isLiveData: true,
            sourceLabel: 'fixture',
          ),
        ],
        locale: 'tr',
      );

      expect(plan, isNotNull);
      expect(plan!.stops.length, 2);
      expect(plan.estimatedSavings, greaterThan(0));
    });

    test('price ticker keeps the best visible market price', () {
      const tomato = Ingredient(
        id: 'tomato',
        nameTr: 'Domates',
        nameEn: 'Tomato',
        category: IngredientCategory.vegetables,
        icon: 'T',
      );
      const milk = Ingredient(
        id: 'milk',
        nameTr: 'Süt',
        nameEn: 'Milk',
        category: IngredientCategory.dairy,
        icon: 'M',
      );

      final entries = service.buildPriceTickerEntries(
        quotes: const [
          RemoteMarketQuote(
            ingredientId: 'tomato',
            market: 'bim',
            unitPrice: 19.9,
            isCampaign: true,
            campaignLabelTr: 'Kampanya',
            campaignLabelEn: 'Campaign',
          ),
          RemoteMarketQuote(
            ingredientId: 'tomato',
            market: 'migros',
            unitPrice: 24.9,
            isCampaign: false,
            campaignLabelTr: 'Raf',
            campaignLabelEn: 'Shelf',
          ),
          RemoteMarketQuote(
            ingredientId: 'milk',
            market: 'sok',
            unitPrice: 31.5,
            isCampaign: true,
            campaignLabelTr: 'Kampanya',
            campaignLabelEn: 'Campaign',
          ),
        ],
        ingredients: const [tomato, milk],
      );

      expect(entries, isNotEmpty);
      expect(entries.first.market, isNotEmpty);
      expect(entries.any((entry) => entry.ingredient.id == 'tomato'), isTrue);
    });

    test('sponsored placements prefer recipes with sponsor ingredients', () {
      const flour = Ingredient(
        id: 'flour',
        nameTr: 'Un',
        nameEn: 'Flour',
        category: IngredientCategory.grains,
        icon: 'U',
      );
      const yogurt = Ingredient(
        id: 'yogurt',
        nameTr: 'Yoğurt',
        nameEn: 'Yogurt',
        category: IngredientCategory.dairy,
        icon: 'Y',
      );
      const recipe = Recipe(
        id: 'pogaca',
        nameTr: 'Poğaça',
        nameEn: 'Pogaca',
        descriptionTr: 'Test',
        descriptionEn: 'Test',
        ingredients: [
          RecipeIngredient(
            ingredientId: 'flour',
            amountTr: '2 su bardağı',
            amountEn: '2 cups',
          ),
          RecipeIngredient(
            ingredientId: 'yogurt',
            amountTr: '1 çay bardağı',
            amountEn: '1 tea glass',
          ),
        ],
        stepsTr: [RecipeStep(stepNumber: 1, instruction: 'Karıştır')],
        stepsEn: [RecipeStep(stepNumber: 1, instruction: 'Mix')],
        prepTimeMinutes: 10,
        cookTimeMinutes: 20,
        servings: 4,
        difficulty: 'easy',
        category: 'bakery',
      );

      final placements = service.buildSponsoredPlacements(
        recipes: [recipe],
        shoppingItems: const [
          SmartShoppingItem(
            ingredient: flour,
            requiredCount: 1,
            availableCount: 0,
            missingCount: 1,
          ),
          SmartShoppingItem(
            ingredient: yogurt,
            requiredCount: 1,
            availableCount: 0,
            missingCount: 1,
          ),
        ],
        locale: 'tr',
      );

      expect(placements, isNotEmpty);
      expect(placements.first.recipe.id, 'pogaca');
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
