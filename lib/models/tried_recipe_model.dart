import 'package:cloud_firestore/cloud_firestore.dart';

class TriedRecipe {
  final String id;
  final String recipeId; // community recipe ID
  final String userId;
  final String userDisplayName;
  final String imageUrl; // Cloudinary URL
  final String comment;
  final DateTime createdAt;

  const TriedRecipe({
    required this.id,
    required this.recipeId,
    required this.userId,
    required this.userDisplayName,
    required this.imageUrl,
    this.comment = '',
    required this.createdAt,
  });

  factory TriedRecipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TriedRecipe(
      id: doc.id,
      recipeId: data['recipeId'] ?? '',
      userId: data['userId'] ?? '',
      userDisplayName: data['userDisplayName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      comment: data['comment'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'recipeId': recipeId,
        'userId': userId,
        'userDisplayName': userDisplayName,
        'imageUrl': imageUrl,
        'comment': comment,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
