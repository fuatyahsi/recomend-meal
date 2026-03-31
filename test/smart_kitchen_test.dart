import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_chef/models/market_fiyati.dart';
import 'package:fridge_chef/models/smart_kitchen.dart';

void main() {
  test('smart kitchen preferences preserve meal routines after serialization',
      () {
    final original = SmartKitchenPreferences.defaults()
        .copyWith(
          campaignAlertsEnabled: true,
          preferredMarkets: const ['migros', 'a101'],
          marketFeedUrl: 'https://example.com/feed.json',
          marketFeedLabel: 'FridgeChef Live',
          marketFiyatiSession: const MarketFiyatiSession(
            locationLabel: 'Aşağı Öveçler, Çankaya, Ankara',
            depots: ['migros-8926', 'a101-8887'],
            distance: 5,
            latitude: 39.8867769953312,
            longitude: 32.8167366992369,
          ),
          plannedRecipeIdsByMeal: const {
            'dinner': ['mercimek-corbasi', 'coban-salata'],
          },
        )
        .replaceSlot(
          SmartKitchenPreferences.defaults()
              .slotById('dinner')
              .copyWith(weekdayMinutes: 1140, leadMinutes: 45),
        );

    final restored = SmartKitchenPreferences.fromJson(original.toJson());

    expect(restored.campaignAlertsEnabled, isTrue);
    expect(restored.preferredMarkets, ['migros', 'a101']);
    expect(restored.marketFeedUrl, 'https://example.com/feed.json');
    expect(restored.marketFeedLabel, 'FridgeChef Live');
    expect(
      restored.marketFiyatiSession?.locationLabel,
      'Aşağı Öveçler, Çankaya, Ankara',
    );
    expect(
      restored.marketFiyatiSession?.depots,
      ['migros-8926', 'a101-8887'],
    );
    expect(
      restored.plannedRecipeIdsByMeal['dinner'],
      ['mercimek-corbasi', 'coban-salata'],
    );
    expect(restored.slotById('dinner').weekdayMinutes, 1140);
    expect(restored.slotById('dinner').leadMinutes, 45);
  });

  test('smart kitchen preferences migrate legacy single recipe plans', () {
    final restored = SmartKitchenPreferences.fromJson({
      'mealSlots': [],
      'plannedRecipeIds': {
        'breakfast': 'menemen',
        'dinner': 'mercimek-corbasi',
      },
    });

    expect(restored.plannedRecipeIdsByMeal['breakfast'], ['menemen']);
    expect(
      restored.plannedRecipeIdsByMeal['dinner'],
      ['mercimek-corbasi'],
    );
  });

  test('smart kitchen preferences migrate legacy market names to ids', () {
    final restored = SmartKitchenPreferences.fromJson({
      'mealSlots': const [],
      'preferredMarkets': const ['Migros', 'A101', 'CarrefourSA'],
    });

    expect(restored.preferredMarkets, ['migros', 'a101', 'carrefoursa']);
  });

  test('smart kitchen preferences start with no selected markets by default',
      () {
    final defaults = SmartKitchenPreferences.defaults();
    final restored = SmartKitchenPreferences.fromJson({
      'mealSlots': const [],
      'preferredMarkets': const [],
    });

    expect(defaults.preferredMarkets, isEmpty);
    expect(restored.preferredMarkets, isEmpty);
  });

  test('smart kitchen preferences migrate legacy payloads without market ids',
      () {
    final restored = SmartKitchenPreferences.fromJson({
      'mealSlots': const [],
      'campaignAlertsEnabled': true,
    });

    expect(
      restored.preferredMarkets,
      SmartKitchenPreferences.legacyDefaultMarketIds,
    );
  });
}
