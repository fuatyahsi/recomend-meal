import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityRecipe {
  final String id;
  final String userId;
  final String userDisplayName;
  final String userPhotoURL;
  final String nameTr;
  final String nameEn;
  final String descriptionTr;
  final String descriptionEn;
  final List<CommunityRecipeIngredient> ingredients;
  final List<CommunityRecipeStep> stepsTr;
  final List<CommunityRecipeStep> stepsEn;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final String difficulty;
  final String category;
  final String imageUrl;
  final String imageEmoji;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPublished;
  final int totalLikes;
  final int totalRatings;
  final double averageRating;

  const CommunityRecipe({
    required this.id,
    required this.userId,
    this.userDisplayName = '',
    this.userPhotoURL = '',
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
    this.imageUrl = '',
    this.imageEmoji = '🍽️',
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.isPublished = true,
    this.totalLikes = 0,
    this.totalRatings = 0,
    this.averageRating = 0.0,
  });

  factory CommunityRecipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CommunityRecipe(
      id: doc.id,
      userId: data['userId'] ?? '',
      userDisplayName: data['userDisplayName'] ?? '',
      userPhotoURL: data['userPhotoURL'] ?? '',
      nameTr: data['nameTr'] ?? '',
      nameEn: data['nameEn'] ?? '',
      descriptionTr: data['descriptionTr'] ?? '',
      descriptionEn: data['descriptionEn'] ?? '',
      ingredients: (data['ingredients'] as List?)
              ?.map((e) => CommunityRecipeIngredient.fromMap(e))
              .toList() ??
          [],
      stepsTr: (data['stepsTr'] as List?)
              ?.map((e) => CommunityRecipeStep.fromMap(e))
              .toList() ??
          [],
      stepsEn: (data['stepsEn'] as List?)
              ?.map((e) => CommunityRecipeStep.fromMap(e))
              .toList() ??
          [],
      prepTimeMinutes: data['prepTimeMinutes'] ?? 0,
      cookTimeMinutes: data['cookTimeMinutes'] ?? 0,
      servings: data['servings'] ?? 1,
      difficulty: data['difficulty'] ?? 'easy',
      category: data['category'] ?? 'main',
      imageUrl: data['imageUrl'] ?? '',
      imageEmoji: data['imageEmoji'] ?? '🍽️',
      tags: List<String>.from(data['tags'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isPublished: data['isPublished'] ?? true,
      totalLikes: data['totalLikes'] ?? 0,
      totalRatings: data['totalRatings'] ?? 0,
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'userDisplayName': userDisplayName,
        'userPhotoURL': userPhotoURL,
        'nameTr': nameTr,
        'nameEn': nameEn,
        'descriptionTr': descriptionTr,
        'descriptionEn': descriptionEn,
        'ingredients': ingredients.map((e) => e.toMap()).toList(),
        'stepsTr': stepsTr.map((e) => e.toMap()).toList(),
        'stepsEn': stepsEn.map((e) => e.toMap()).toList(),
        'prepTimeMinutes': prepTimeMinutes,
        'cookTimeMinutes': cookTimeMinutes,
        'servings': servings,
        'difficulty': difficulty,
        'category': category,
        'imageUrl': imageUrl,
        'imageEmoji': imageEmoji,
        'tags': tags,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'isPublished': isPublished,
        'totalLikes': totalLikes,
        'totalRatings': totalRatings,
        'averageRating': averageRating,
      };

  String getName(String locale) => locale == 'tr' ? nameTr : nameEn;
  String getDescription(String locale) =>
      locale == 'tr' ? descriptionTr : descriptionEn;
  List<CommunityRecipeStep> getSteps(String locale) =>
      locale == 'tr' ? stepsTr : stepsEn;

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  String getDifficultyText(String locale) {
    if (locale == 'tr') {
      switch (difficulty) {
        case 'easy': return 'Kolay';
        case 'medium': return 'Orta';
        case 'hard': return 'Zor';
        default: return difficulty;
      }
    }
    switch (difficulty) {
      case 'easy': return 'Easy';
      case 'medium': return 'Medium';
      case 'hard': return 'Hard';
      default: return difficulty;
    }
  }
}

class CommunityRecipeIngredient {
  final String ingredientId;
  final String amountTr;
  final String amountEn;
  final bool isOptional;

  const CommunityRecipeIngredient({
    required this.ingredientId,
    required this.amountTr,
    required this.amountEn,
    this.isOptional = false,
  });

  factory CommunityRecipeIngredient.fromMap(Map<String, dynamic> map) {
    return CommunityRecipeIngredient(
      ingredientId: map['ingredientId'] ?? '',
      amountTr: map['amountTr'] ?? '',
      amountEn: map['amountEn'] ?? '',
      isOptional: map['isOptional'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'ingredientId': ingredientId,
        'amountTr': amountTr,
        'amountEn': amountEn,
        'isOptional': isOptional,
      };

  String getAmount(String locale) => locale == 'tr' ? amountTr : amountEn;
}

class CommunityRecipeStep {
  final int stepNumber;
  final String instruction;
  final int? durationMinutes;

  const CommunityRecipeStep({
    required this.stepNumber,
    required this.instruction,
    this.durationMinutes,
  });

  factory CommunityRecipeStep.fromMap(Map<String, dynamic> map) {
    return CommunityRecipeStep(
      stepNumber: map['stepNumber'] ?? 0,
      instruction: map['instruction'] ?? '',
      durationMinutes: map['durationMinutes'],
    );
  }

  Map<String, dynamic> toMap() => {
        'stepNumber': stepNumber,
        'instruction': instruction,
        'durationMinutes': durationMinutes,
      };
}
