import 'package:cloud_firestore/cloud_firestore.dart';

class Cookbook {
  final String id;
  final String userId;
  final String name;
  final String emoji;
  final List<String> recipeIds; // built-in recipe IDs
  final List<String> communityRecipeIds; // community recipe IDs
  final DateTime createdAt;

  const Cookbook({
    required this.id,
    required this.userId,
    required this.name,
    required this.emoji,
    this.recipeIds = const [],
    this.communityRecipeIds = const [],
    required this.createdAt,
  });

  factory Cookbook.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Cookbook(
      id: doc.id,
      userId: data['userId'] ?? '',
      name: data['name'] ?? '',
      emoji: data['emoji'] ?? '📒',
      recipeIds: List<String>.from(data['recipeIds'] ?? []),
      communityRecipeIds: List<String>.from(data['communityRecipeIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'emoji': emoji,
        'recipeIds': recipeIds,
        'communityRecipeIds': communityRecipeIds,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  int get totalRecipes => recipeIds.length + communityRecipeIds.length;

  Cookbook copyWith({
    String? name,
    String? emoji,
    List<String>? recipeIds,
    List<String>? communityRecipeIds,
  }) {
    return Cookbook(
      id: id,
      userId: userId,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      recipeIds: recipeIds ?? this.recipeIds,
      communityRecipeIds: communityRecipeIds ?? this.communityRecipeIds,
      createdAt: createdAt,
    );
  }
}
