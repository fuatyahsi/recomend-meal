import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_chef/models/smart_kitchen.dart';

void main() {
  test('smart kitchen preferences preserve meal routines after serialization', () {
    final original = SmartKitchenPreferences.defaults().copyWith(
      campaignAlertsEnabled: true,
      preferredMarkets: const ['Migros', 'A101'],
    ).replaceSlot(
      SmartKitchenPreferences.defaults()
          .slotById('dinner')
          .copyWith(weekdayMinutes: 1140, leadMinutes: 45),
    );

    final restored = SmartKitchenPreferences.fromJson(original.toJson());

    expect(restored.campaignAlertsEnabled, isTrue);
    expect(restored.preferredMarkets, ['Migros', 'A101']);
    expect(restored.slotById('dinner').weekdayMinutes, 1140);
    expect(restored.slotById('dinner').leadMinutes, 45);
  });
}
