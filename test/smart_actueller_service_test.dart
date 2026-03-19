import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_chef/models/ingredient.dart';
import 'package:fridge_chef/models/kitchen_intelligence.dart';
import 'package:fridge_chef/models/smart_kitchen.dart';
import 'package:fridge_chef/services/smart_actueller_service.dart';

void main() {
  group('SmartActuellerService', () {
    final service = SmartActuellerService();

    const blackOlive = Ingredient(
      id: 'black_olive',
      nameTr: 'Siyah Zeytin',
      nameEn: 'Black Olive',
      category: IngredientCategory.other,
      icon: 'O',
    );
    const egg = Ingredient(
      id: 'egg',
      nameTr: 'Yumurta',
      nameEn: 'Egg',
      category: IngredientCategory.other,
      icon: 'E',
    );
    const kasar = Ingredient(
      id: 'cheese_kashar',
      nameTr: 'Kaşar Peyniri',
      nameEn: 'Kashar Cheese',
      category: IngredientCategory.dairy,
      icon: 'C',
    );

    test('parses OCR-like flyer blocks into ingredient deals', () {
      final result = service.analyzeFlyerText(
        rawText:
            'BİM 21.03.2026\nİnci Siyah Zeytin 46,09 TL\nYUMRTA 10 LU 62,50 TL\nKaşar Peyniri 129,90 TL',
        ingredients: const [blackOlive, egg, kasar],
        detectedStore: 'BIM',
        ocrBlocks: const [
          'BIM 21.03.2026',
          'İnci Siyah Zeytin 46,09 TL',
          'YUMRTA 10 LU 62,50 TL',
          'Kaşar Peyniri 129,90 TL',
        ],
      );

      expect(result.deals.length, 3);
      expect(
        result.deals.map((deal) => deal.ingredient.id),
        containsAll(['black_olive', 'egg', 'cheese_kashar']),
      );
      expect(result.detectedStore, 'BIM');
      expect(result.confidence, greaterThan(0.45));
    });

    test('prioritizes missing items from planned menus', () {
      final result = service.analyzeFlyerText(
        rawText: 'BIM\nSiyah Zeytin 46,09 TL\nYumurta 62,50 TL',
        ingredients: const [blackOlive, egg],
        detectedStore: 'BIM',
      );

      final suggestions = service.buildPersonalizedSuggestions(
        scanResult: result,
        pantryCounts: const {
          'black_olive': 0,
          'egg': 3,
        },
        pantryRiskItems: [
          PantryRiskItem(
            ingredient: blackOlive,
            count: 0,
            lastUpdatedAt: DateTime(2026, 3, 17),
            ageDays: 0,
            shelfLifeDays: 7,
            riskScore: 0.2,
            estimatedLossValue: 0,
          ),
        ],
        shoppingItems: const [
          SmartShoppingItem(
            ingredient: blackOlive,
            requiredCount: 2,
            availableCount: 0,
            missingCount: 2,
            recipeNames: ['Kahvaltı tabağı'],
          ),
        ],
        preferredMarkets: const ['BIM'],
      );

      expect(suggestions, isNotEmpty);
      expect(suggestions.first.deal.ingredient.id, 'black_olive');
      expect(suggestions.first.neededCount, 2);
      expect(suggestions.first.estimatedSavings, greaterThan(0));
    });

    test('converts flyer deals into remote market quotes', () {
      final result = service.analyzeFlyerText(
        rawText: 'Migros\nKaşar Peyniri 129,90 TL',
        ingredients: const [kasar],
        detectedStore: 'Migros',
      );

      final quotes = service.toRemoteQuotes(result);

      expect(quotes, hasLength(1));
      expect(quotes.first.ingredientId, 'cheese_kashar');
      expect(quotes.first.market, 'Migros');
      expect(quotes.first.isCampaign, isTrue);
    });

    test('filters out unreasonable OCR prices', () {
      final result = service.analyzeFlyerText(
        rawText: 'Migros\nKaşar Peyniri 600,00 TL\nYumurta 20,00 TL',
        ingredients: const [kasar, egg],
        detectedStore: 'Migros',
      );

      expect(
        result.deals.map((deal) => deal.ingredient.id),
        equals(['egg']),
      );
    });
  });
}
