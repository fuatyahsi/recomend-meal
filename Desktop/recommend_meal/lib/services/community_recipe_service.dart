import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/community_recipe_model.dart';

class CommunityRecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  CollectionReference get _recipesRef =>
      _firestore.collection('community_recipes');

  // --- CRUD ---
  Future<String> submitRecipe(CommunityRecipe recipe) async {
    final docRef = await _recipesRef.add(recipe.toFirestore());

    // Update user's recipe count
    await _firestore.collection('users').doc(recipe.userId).update({
      'totalRecipesShared': FieldValue.increment(1),
    });

    return docRef.id;
  }

  Future<void> updateRecipe(String recipeId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _recipesRef.doc(recipeId).update(data);
  }

  Future<void> deleteRecipe(String recipeId, String userId) async {
    await _recipesRef.doc(recipeId).delete();
    await _firestore.collection('users').doc(userId).update({
      'totalRecipesShared': FieldValue.increment(-1),
    });
  }

  // --- Queries ---
  Future<List<CommunityRecipe>> getLatestRecipes({int limit = 20}) async {
    final snapshot = await _recipesRef
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => CommunityRecipe.fromFirestore(doc))
        .toList();
  }

  Future<List<CommunityRecipe>> getTrendingRecipes({int limit = 20}) async {
    final snapshot = await _recipesRef
        .where('isPublished', isEqualTo: true)
        .orderBy('totalLikes', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => CommunityRecipe.fromFirestore(doc))
        .toList();
  }

  Future<List<CommunityRecipe>> getTopRatedRecipes({int limit = 20}) async {
    final snapshot = await _recipesRef
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

  Future<List<CommunityRecipe>> getUserRecipes(String userId,
      {int limit = 50}) async {
    final snapshot = await _recipesRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => CommunityRecipe.fromFirestore(doc))
        .toList();
  }

  Future<List<CommunityRecipe>> getRecipesByCategory(String category,
      {int limit = 20}) async {
    final snapshot = await _recipesRef
        .where('isPublished', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => CommunityRecipe.fromFirestore(doc))
        .toList();
  }

  Future<CommunityRecipe?> getRecipeById(String recipeId) async {
    final doc = await _recipesRef.doc(recipeId).get();
    if (!doc.exists) return null;
    return CommunityRecipe.fromFirestore(doc);
  }

  // --- Image Upload ---
  Future<String> uploadRecipeImage(
      String userId, String recipeId, File imageFile) async {
    final ref = _storage
        .ref()
        .child('recipe_images/$userId/$recipeId/${DateTime.now().millisecondsSinceEpoch}.jpg');
    await ref.putFile(imageFile);
    return await ref.getDownloadURL();
  }

  // --- Like System ---
  Future<bool> toggleLike(String recipeId, String userId) async {
    final likesRef = _firestore.collection('recipe_likes');
    final existing = await likesRef
        .where('recipeId', isEqualTo: recipeId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Unlike
      await existing.docs.first.reference.delete();
      await _recipesRef.doc(recipeId).update({
        'totalLikes': FieldValue.increment(-1),
      });
      // Update recipe owner's total likes
      final recipe = await getRecipeById(recipeId);
      if (recipe != null) {
        await _firestore.collection('users').doc(recipe.userId).update({
          'totalLikesReceived': FieldValue.increment(-1),
        });
      }
      return false; // unliked
    } else {
      // Like
      await likesRef.add({
        'recipeId': recipeId,
        'userId': userId,
        'createdAt': Timestamp.now(),
      });
      await _recipesRef.doc(recipeId).update({
        'totalLikes': FieldValue.increment(1),
      });
      final recipe = await getRecipeById(recipeId);
      if (recipe != null) {
        await _firestore.collection('users').doc(recipe.userId).update({
          'totalLikesReceived': FieldValue.increment(1),
        });
      }
      return true; // liked
    }
  }

  Future<bool> isLikedByUser(String recipeId, String userId) async {
    final snapshot = await _firestore
        .collection('recipe_likes')
        .where('recipeId', isEqualTo: recipeId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }
}
