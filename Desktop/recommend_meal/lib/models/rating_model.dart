import 'package:cloud_firestore/cloud_firestore.dart';

class RecipeRating {
  final String id;
  final String recipeId;
  final String userId;
  final String userDisplayName;
  final String userPhotoURL;
  final int rating; // 1-5
  final String comment;
  final DateTime createdAt;

  const RecipeRating({
    required this.id,
    required this.recipeId,
    required this.userId,
    this.userDisplayName = '',
    this.userPhotoURL = '',
    required this.rating,
    this.comment = '',
    required this.createdAt,
  });

  factory RecipeRating.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecipeRating(
      id: doc.id,
      recipeId: data['recipeId'] ?? '',
      userId: data['userId'] ?? '',
      userDisplayName: data['userDisplayName'] ?? '',
      userPhotoURL: data['userPhotoURL'] ?? '',
      rating: data['rating'] ?? 0,
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'recipeId': recipeId,
        'userId': userId,
        'userDisplayName': userDisplayName,
        'userPhotoURL': userPhotoURL,
        'rating': rating,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class RecipeLike {
  final String id;
  final String recipeId;
  final String userId;
  final DateTime createdAt;

  const RecipeLike({
    required this.id,
    required this.recipeId,
    required this.userId,
    required this.createdAt,
  });

  factory RecipeLike.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return RecipeLike(
      id: doc.id,
      recipeId: data['recipeId'] ?? '',
      userId: data['userId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'recipeId': recipeId,
        'userId': userId,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
