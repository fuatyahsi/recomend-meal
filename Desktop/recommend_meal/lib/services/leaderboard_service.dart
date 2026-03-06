import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/community_recipe_model.dart';

class LeaderboardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Top recipe sharers
  Future<List<AppUser>> getTopSharers({int limit = 20}) async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('totalRecipesShared', descending: true)
        .where('totalRecipesShared', isGreaterThan: 0)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
  }

  /// Users with most likes received
  Future<List<AppUser>> getMostLikedUsers({int limit = 20}) async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('totalLikesReceived', descending: true)
        .where('totalLikesReceived', isGreaterThan: 0)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
  }

  /// Most liked recipes
  Future<List<CommunityRecipe>> getMostLikedRecipes({int limit = 20}) async {
    final snapshot = await _firestore
        .collection('community_recipes')
        .where('isPublished', isEqualTo: true)
        .orderBy('totalLikes', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => CommunityRecipe.fromFirestore(doc))
        .toList();
  }

  /// Highest rated recipes (min 3 ratings)
  Future<List<CommunityRecipe>> getHighestRatedRecipes(
      {int limit = 20}) async {
    final snapshot = await _firestore
        .collection('community_recipes')
        .where('isPublished', isEqualTo: true)
        .where('totalRatings', isGreaterThanOrEqualTo: 3)
        .orderBy('totalRatings')
        .orderBy('averageRating', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => CommunityRecipe.fromFirestore(doc))
        .toList();
  }

  /// Newest community members
  Future<List<AppUser>> getNewestMembers({int limit = 20}) async {
    final snapshot = await _firestore
        .collection('users')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => AppUser.fromFirestore(doc)).toList();
  }
}
