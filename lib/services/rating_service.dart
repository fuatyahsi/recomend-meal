import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/rating_model.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _ratingsRef =>
      _firestore.collection('recipe_ratings');

  Future<void> addOrUpdateRating(RecipeRating rating) async {
    // Check if user already rated this recipe
    final existing = await _ratingsRef
        .where('recipeId', isEqualTo: rating.recipeId)
        .where('userId', isEqualTo: rating.userId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Update existing
      await existing.docs.first.reference.update({
        'rating': rating.rating,
        'comment': rating.comment,
        'updatedAt': Timestamp.now(),
      });
    } else {
      // Create new
      await _ratingsRef.add(rating.toFirestore());

      // Increment user's ratings given count
      await _firestore.collection('users').doc(rating.userId).update({
        'totalRatingsGiven': FieldValue.increment(1),
      });
    }

    // Recalculate recipe average
    await _recalculateRecipeRating(rating.recipeId);
  }

  Future<void> _recalculateRecipeRating(String recipeId) async {
    final snapshot = await _ratingsRef
        .where('recipeId', isEqualTo: recipeId)
        .get();

    if (snapshot.docs.isEmpty) return;

    double totalScore = 0;
    for (final doc in snapshot.docs) {
      totalScore += (doc.data() as Map<String, dynamic>)['rating'] ?? 0;
    }

    final average = totalScore / snapshot.docs.length;

    await _firestore.collection('community_recipes').doc(recipeId).update({
      'totalRatings': snapshot.docs.length,
      'averageRating': double.parse(average.toStringAsFixed(1)),
    });
  }

  Future<List<RecipeRating>> getRecipeRatings(String recipeId,
      {int limit = 50}) async {
    final snapshot = await _ratingsRef
        .where('recipeId', isEqualTo: recipeId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => RecipeRating.fromFirestore(doc))
        .toList();
  }

  Future<RecipeRating?> getUserRating(String recipeId, String userId) async {
    final snapshot = await _ratingsRef
        .where('recipeId', isEqualTo: recipeId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) return null;
    return RecipeRating.fromFirestore(snapshot.docs.first);
  }

  Future<void> deleteRating(String ratingId, String recipeId) async {
    await _ratingsRef.doc(ratingId).delete();
    await _recalculateRecipeRating(recipeId);
  }
}
