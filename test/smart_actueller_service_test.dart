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
    test('ignores implausible savings signals and far future dates', () {
      final result = service.analyzeFlyerText(
        rawText: 'A101\nSiyah Zeytin 25,00 TL 1299,00 TL 30.09.2033',
        ingredients: const [blackOlive],
        detectedStore: 'A101',
      );

      expect(result.deals, hasLength(1));
      expect(result.deals.single.regularPrice, isNull);
      expect(result.deals.single.validUntil, isNull);

      final suggestions = service.buildPersonalizedSuggestions(
        scanResult: result,
        pantryCounts: const {'black_olive': 0},
        pantryRiskItems: const [],
        shoppingItems: const [
          SmartShoppingItem(
            ingredient: blackOlive,
            requiredCount: 12,
            availableCount: 0,
            missingCount: 12,
            recipeNames: ['Kahvalti tabagi'],
          ),
        ],
        preferredMarkets: const ['A101'],
      );

      expect(suggestions, isNotEmpty);
      expect(suggestions.single.estimatedSavings, lessThan(100));
      expect(suggestions.single.body('tr'), isNot(contains('2033')));
    });

    test('does not treat dimensions as prices', () {
      final result = service.analyzeFlyerText(
        rawText: 'BIM\nGRAN TOYS Oyun Arkadasim Pelus Zurafa 100cm 525,00 TL',
        ingredients: const [],
        detectedStore: 'BIM',
      );

      expect(result.catalogItems, hasLength(1));
      expect(
        result.catalogItems.single.productTitle,
        'GRAN TOYS Oyun Arkadasim Pelus Zurafa 100cm',
      );
      expect(result.catalogItems.single.price, 525.0);
    });

    test('does not treat model numbers as prices', () {
      final result = service.analyzeFlyerText(
        rawText:
            'BIM\nCasio G-Shock G-Squad GMD-B300SC-4DR Pembe Kadin Kol Saati 3500,00 TL',
        ingredients: const [],
        detectedStore: 'BIM',
      );

      expect(result.catalogItems, hasLength(1));
      expect(
        result.catalogItems.single.productTitle,
        'Casio G-Shock G-Squad GMD-B300SC-4DR Pembe Kadin Kol Saati',
      );
      expect(result.catalogItems.single.price, 3500.0);
    });

    test('preserves valid measurements in parsed product titles', () {
      final result = service.analyzeFlyerText(
        rawText:
            "BIM\nChef's Plus Cam Saklama Kabi 250 cc 27,50 TL\nAlpro Badem Sutu 1 lt 149,00 TL\nAbs Valiz Cesitleri Buyuk Boy 76x49x32 cm 899,00 TL",
        ingredients: const [],
        detectedStore: 'BIM',
      );

      expect(result.catalogItems, hasLength(3));
      expect(
        result.catalogItems.map((item) => item.productTitle),
        containsAll(const [
          "Chef's Plus Cam Saklama Kabi 250 cc",
          'Alpro Badem Sutu 1 lt',
          'Abs Valiz Cesitleri Buyuk Boy 76x49x32 cm',
        ]),
      );
    });

    test('removes orphan unit tails from malformed titles', () {
      final result = service.analyzeFlyerText(
        rawText:
            "BIM\nAknaz Tam Yagli Tava Peyniri g 155,00 TL\nAbs Valiz Cesitleri Buyuk Boy x x cm 899,00 TL\nBolbol Sos Cesitleri g/ g/ g/ g 35,00 TL\nBaskili Balonlar 'lu 32,00 TL",
        ingredients: const [],
        detectedStore: 'BIM',
      );

      expect(result.catalogItems, hasLength(4));
      expect(
        result.catalogItems.map((item) => item.productTitle),
        containsAll(const [
          'Aknaz Tam Yagli Tava Peyniri',
          'Abs Valiz Cesitleri Buyuk Boy',
          'Bolbol Sos Cesitleri',
          'Baskili Balonlar',
        ]),
      );
      expect(
        result.catalogItems.map((item) => item.price),
        containsAll(const [155.0, 899.0, 35.0, 32.0]),
      );
    });

    test('drops orphan count suffix tokens but preserves valid counts', () {
      final result = service.analyzeFlyerText(
        rawText:
            "BIM\nBora 'lu Dikis Ipi Seti 69,00 TL\nPasabahce Bouquet Su Bardagi 3'lu 290 cc 89,90 TL",
        ingredients: const [],
        detectedStore: 'BIM',
      );

      expect(result.catalogItems, hasLength(2));
      expect(
        result.catalogItems.map((item) => item.productTitle),
        containsAll(const [
          'Bora Dikis Ipi Seti',
          "Pasabahce Bouquet Su Bardagi 3'lu 290 cc",
        ]),
      );
    });
  });
}
