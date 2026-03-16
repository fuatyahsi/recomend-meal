import 'ingredient.dart';
import 'recipe.dart';

class MealRoutineSlot {
  final String id;
  final int weekdayMinutes;
  final int weekendMinutes;
  final int leadMinutes;
  final bool enabled;

  const MealRoutineSlot({
    required this.id,
    required this.weekdayMinutes,
    required this.weekendMinutes,
    required this.leadMinutes,
    required this.enabled,
  });

  factory MealRoutineSlot.defaults(String id) {
    switch (id) {
      case 'breakfast':
        return const MealRoutineSlot(
          id: 'breakfast',
          weekdayMinutes: 420,
          weekendMinutes: 540,
          leadMinutes: 30,
          enabled: true,
        );
      case 'lunch':
        return const MealRoutineSlot(
          id: 'lunch',
          weekdayMinutes: 750,
          weekendMinutes: 810,
          leadMinutes: 45,
          enabled: false,
        );
      case 'dinner':
      default:
        return const MealRoutineSlot(
          id: 'dinner',
          weekdayMinutes: 1110,
          weekendMinutes: 1170,
          leadMinutes: 60,
          enabled: true,
        );
    }
  }

  MealRoutineSlot copyWith({
    int? weekdayMinutes,
    int? weekendMinutes,
    int? leadMinutes,
    bool? enabled,
  }) {
    return MealRoutineSlot(
      id: id,
      weekdayMinutes: weekdayMinutes ?? this.weekdayMinutes,
      weekendMinutes: weekendMinutes ?? this.weekendMinutes,
      leadMinutes: leadMinutes ?? this.leadMinutes,
      enabled: enabled ?? this.enabled,
    );
  }

  factory MealRoutineSlot.fromJson(Map<String, dynamic> json) {
    return MealRoutineSlot(
      id: json['id'] as String,
      weekdayMinutes: json['weekdayMinutes'] as int,
      weekendMinutes: json['weekendMinutes'] as int,
      leadMinutes: json['leadMinutes'] as int,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'weekdayMinutes': weekdayMinutes,
        'weekendMinutes': weekendMinutes,
        'leadMinutes': leadMinutes,
        'enabled': enabled,
      };
}

class SmartKitchenPreferences {
  final List<MealRoutineSlot> mealSlots;
  final bool eveningDriveHomeSuggestions;
  final bool schoolBreakfastNudges;
  final bool priceComparisonEnabled;
  final bool campaignAlertsEnabled;
  final List<String> preferredMarkets;
  final Map<String, List<String>> plannedRecipeIdsByMeal;

  const SmartKitchenPreferences({
    required this.mealSlots,
    required this.eveningDriveHomeSuggestions,
    required this.schoolBreakfastNudges,
    required this.priceComparisonEnabled,
    required this.campaignAlertsEnabled,
    required this.preferredMarkets,
    required this.plannedRecipeIdsByMeal,
  });

  factory SmartKitchenPreferences.defaults() {
    return const SmartKitchenPreferences(
      mealSlots: [
        MealRoutineSlot(
          id: 'breakfast',
          weekdayMinutes: 420,
          weekendMinutes: 540,
          leadMinutes: 30,
          enabled: true,
        ),
        MealRoutineSlot(
          id: 'lunch',
          weekdayMinutes: 750,
          weekendMinutes: 810,
          leadMinutes: 45,
          enabled: false,
        ),
        MealRoutineSlot(
          id: 'dinner',
          weekdayMinutes: 1110,
          weekendMinutes: 1170,
          leadMinutes: 60,
          enabled: true,
        ),
      ],
      eveningDriveHomeSuggestions: true,
      schoolBreakfastNudges: true,
      priceComparisonEnabled: false,
      campaignAlertsEnabled: false,
      preferredMarkets: ['Migros', 'CarrefourSA'],
      plannedRecipeIdsByMeal: {},
    );
  }

  MealRoutineSlot slotById(String id) {
    return mealSlots.firstWhere(
      (slot) => slot.id == id,
      orElse: () => MealRoutineSlot.defaults(id),
    );
  }

  SmartKitchenPreferences copyWith({
    List<MealRoutineSlot>? mealSlots,
    bool? eveningDriveHomeSuggestions,
    bool? schoolBreakfastNudges,
    bool? priceComparisonEnabled,
    bool? campaignAlertsEnabled,
    List<String>? preferredMarkets,
    Map<String, List<String>>? plannedRecipeIdsByMeal,
  }) {
    return SmartKitchenPreferences(
      mealSlots: mealSlots ?? this.mealSlots,
      eveningDriveHomeSuggestions:
          eveningDriveHomeSuggestions ?? this.eveningDriveHomeSuggestions,
      schoolBreakfastNudges:
          schoolBreakfastNudges ?? this.schoolBreakfastNudges,
      priceComparisonEnabled:
          priceComparisonEnabled ?? this.priceComparisonEnabled,
      campaignAlertsEnabled:
          campaignAlertsEnabled ?? this.campaignAlertsEnabled,
      preferredMarkets: preferredMarkets ?? this.preferredMarkets,
      plannedRecipeIdsByMeal:
          plannedRecipeIdsByMeal ?? this.plannedRecipeIdsByMeal,
    );
  }

  SmartKitchenPreferences replaceSlot(MealRoutineSlot updatedSlot) {
    final slots = mealSlots
        .map((slot) => slot.id == updatedSlot.id ? updatedSlot : slot)
        .toList();
    return copyWith(mealSlots: slots);
  }

  factory SmartKitchenPreferences.fromJson(Map<String, dynamic> json) {
    final plannedRecipeIdsByMeal = <String, List<String>>{};
    final rawPlannedRecipes = json['plannedRecipeIdsByMeal'];
    if (rawPlannedRecipes is Map<String, dynamic>) {
      for (final entry in rawPlannedRecipes.entries) {
        plannedRecipeIdsByMeal[entry.key] = (entry.value as List<dynamic>? ?? const [])
            .map((value) => value.toString())
            .toList();
      }
    } else {
      final legacyPlannedRecipes = json['plannedRecipeIds'];
      if (legacyPlannedRecipes is Map<String, dynamic>) {
        for (final entry in legacyPlannedRecipes.entries) {
          final recipeId = entry.value.toString();
          if (recipeId.isNotEmpty) {
            plannedRecipeIdsByMeal[entry.key] = [recipeId];
          }
        }
      }
    }

    return SmartKitchenPreferences(
      mealSlots: (json['mealSlots'] as List<dynamic>? ?? const [])
          .map((slot) => MealRoutineSlot.fromJson(slot as Map<String, dynamic>))
          .toList(),
      eveningDriveHomeSuggestions:
          json['eveningDriveHomeSuggestions'] as bool? ?? true,
      schoolBreakfastNudges: json['schoolBreakfastNudges'] as bool? ?? true,
      priceComparisonEnabled:
          json['priceComparisonEnabled'] as bool? ?? false,
      campaignAlertsEnabled:
          json['campaignAlertsEnabled'] as bool? ?? false,
      preferredMarkets:
          (json['preferredMarkets'] as List<dynamic>? ?? const ['Migros'])
              .cast<String>(),
      plannedRecipeIdsByMeal: plannedRecipeIdsByMeal,
    );
  }

  Map<String, dynamic> toJson() => {
        'mealSlots': mealSlots.map((slot) => slot.toJson()).toList(),
        'eveningDriveHomeSuggestions': eveningDriveHomeSuggestions,
        'schoolBreakfastNudges': schoolBreakfastNudges,
        'priceComparisonEnabled': priceComparisonEnabled,
        'campaignAlertsEnabled': campaignAlertsEnabled,
        'preferredMarkets': preferredMarkets,
        'plannedRecipeIdsByMeal': plannedRecipeIdsByMeal,
      };
}

class SmartShoppingItem {
  final Ingredient ingredient;
  final RecipeIngredient? requirement;
  final int requiredCount;
  final int availableCount;
  final int missingCount;
  final List<String> recipeNames;

  const SmartShoppingItem({
    required this.ingredient,
    this.requirement,
    required this.requiredCount,
    required this.availableCount,
    required this.missingCount,
    this.recipeNames = const [],
  });
}

class PantryStockItem {
  final Ingredient ingredient;
  final int count;

  const PantryStockItem({
    required this.ingredient,
    required this.count,
  });
}

class PersonalizedRecipeSuggestion {
  final Recipe recipe;
  final int score;
  final int matchPercent;
  final bool canCookNow;
  final List<SmartShoppingItem> missingItems;

  const PersonalizedRecipeSuggestion({
    required this.recipe,
    required this.score,
    required this.matchPercent,
    required this.canCookNow,
    required this.missingItems,
  });
}

class ReminderPreview {
  final String mealId;
  final DateTime remindAt;
  final DateTime mealAt;
  final int leadMinutes;

  const ReminderPreview({
    required this.mealId,
    required this.remindAt,
    required this.mealAt,
    required this.leadMinutes,
  });
}
