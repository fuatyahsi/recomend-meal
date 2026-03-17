import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_chef/models/ingredient.dart';
import 'package:fridge_chef/services/market_watch_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('market watch parses grouped market feed items', () async {
    final client = MockClient((request) async {
      return http.Response(
        '''
        {
          "sourceLabel": "FridgeChef Live",
          "updatedAt": "2026-03-17T09:15:00Z",
          "markets": [
            {
              "market": "Migros",
              "items": [
                {
                  "ingredientId": "tomato",
                  "unitPrice": 18.5,
                  "campaign": true
                }
              ]
            },
            {
              "market": "A101",
              "items": [
                {
                  "nameTr": "Yumurta",
                  "price": 42.0
                }
              ]
            }
          ]
        }
        ''',
        200,
      );
    });

    final service = MarketWatchService(client: client);
    const ingredients = [
      Ingredient(
        id: 'tomato',
        nameTr: 'Domates',
        nameEn: 'Tomato',
        category: IngredientCategory.vegetables,
        icon: '*',
      ),
      Ingredient(
        id: 'egg',
        nameTr: 'Yumurta',
        nameEn: 'Egg',
        category: IngredientCategory.other,
        icon: '*',
      ),
    ];

    final snapshot = await service.fetchFeed(
      feedUrl: 'https://example.com/feed.json',
      ingredients: ingredients,
    );

    expect(snapshot.sourceLabel, 'FridgeChef Live');
    expect(snapshot.quotes.length, 2);
    expect(
      snapshot.quotes.any(
        (quote) =>
            quote.market == 'Migros' &&
            quote.ingredientId == 'tomato' &&
            quote.isCampaign,
      ),
      isTrue,
    );
    expect(
      snapshot.quotes.any(
        (quote) =>
            quote.market == 'A101' &&
            quote.ingredientId == 'egg' &&
            quote.unitPrice == 42.0,
      ),
      isTrue,
    );
  });
}
