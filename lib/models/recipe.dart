class Recipe {
  final String id;
  final String nameTr;
  final String nameEn;
  final String descriptionTr;
  final String descriptionEn;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> stepsTr;
  final List<RecipeStep> stepsEn;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final String difficulty;
  final String category;
  final String imageEmoji;
  final List<String> tags;

  const Recipe({
    required this.id,
    required this.nameTr,
    required this.nameEn,
    required this.descriptionTr,
    required this.descriptionEn,
    required this.ingredients,
    required this.stepsTr,
    required this.stepsEn,
    required this.prepTimeMinutes,
    required this.cookTimeMinutes,
    required this.servings,
    required this.difficulty,
    required this.category,
    this.imageEmoji = '🍽️',
    this.tags = const [],
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String,
      nameTr: json['name_tr'] as String,
      nameEn: json['name_en'] as String,
      descriptionTr: json['description_tr'] as String,
      descriptionEn: json['description_en'] as String,
      ingredients: (json['ingredients'] as List)
          .map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
          .toList(),
      stepsTr: (json['steps_tr'] as List)
          .map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      stepsEn: (json['steps_en'] as List)
          .map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
          .toList(),
      prepTimeMinutes: json['prep_time_minutes'] as int,
      cookTimeMinutes: json['cook_time_minutes'] as int,
      servings: json['servings'] as int,
      difficulty: json['difficulty'] as String,
      category: json['category'] as String,
      imageEmoji: json['image_emoji'] as String? ?? '🍽️',
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
    );
  }

  String getName(String locale) => locale == 'tr' ? nameTr : nameEn;
  String getDescription(String locale) =>
      locale == 'tr' ? descriptionTr : descriptionEn;
  List<RecipeStep> getSteps(String locale) =>
      locale == 'tr' ? stepsTr : stepsEn;

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  String getDifficultyText(String locale) {
    if (locale == 'tr') {
      switch (difficulty) {
        case 'easy':
          return 'Kolay';
        case 'medium':
          return 'Orta';
        case 'hard':
          return 'Zor';
        default:
          return difficulty;
      }
    } else {
      switch (difficulty) {
        case 'easy':
          return 'Easy';
        case 'medium':
          return 'Medium';
        case 'hard':
          return 'Hard';
        default:
          return difficulty;
      }
    }
  }

  /// Returns list of ingredient IDs that are required but not in userIngredients
  List<RecipeIngredient> getMissingIngredients(List<String> userIngredientIds) {
    return ingredients
        .where((ing) => !userIngredientIds.contains(ing.ingredientId))
        .toList();
  }

  /// Returns match percentage (0.0 - 1.0)
  double getMatchPercentage(List<String> userIngredientIds) {
    if (ingredients.isEmpty) return 0.0;
    final matched = ingredients
        .where((ing) => userIngredientIds.contains(ing.ingredientId))
        .length;
    return matched / ingredients.length;
  }

  bool canMakeWith(List<String> userIngredientIds) {
    return ingredients
        .every((ing) => userIngredientIds.contains(ing.ingredientId));
  }
}

class RecipeIngredient {
  final String ingredientId;
  final String amountTr;
  final String amountEn;
  final bool isOptional;

  const RecipeIngredient({
    required this.ingredientId,
    required this.amountTr,
    required this.amountEn,
    this.isOptional = false,
  });

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      ingredientId: json['ingredient_id'] as String,
      amountTr: json['amount_tr'] as String,
      amountEn: json['amount_en'] as String,
      isOptional: json['is_optional'] as bool? ?? false,
    );
  }

  String getAmount(String locale) => locale == 'tr' ? amountTr : amountEn;

  /// Porsiyon çarpanına göre miktarı hesapla
  String getScaledAmount(String locale, double multiplier) {
    final amount = locale == 'tr' ? amountTr : amountEn;
    if (multiplier == 1.0) return amount;

    final regex = RegExp(r'(\d+[.,]?\d*)');
    return amount.replaceAllMapped(regex, (match) {
      final original = double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
      final scaled = original * multiplier;
      if (scaled == scaled.roundToDouble()) {
        return scaled.round().toString();
      } else {
        return scaled.toStringAsFixed(1);
      }
    });
  }
}

class RecipeStep {
  final int stepNumber;
  final String instruction;
  final int? durationMinutes;

  const RecipeStep({
    required this.stepNumber,
    required this.instruction,
    this.durationMinutes,
  });

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      stepNumber: json['step_number'] as int,
      instruction: json['instruction'] as String,
      durationMinutes: json['duration_minutes'] as int?,
    );
  }
}
