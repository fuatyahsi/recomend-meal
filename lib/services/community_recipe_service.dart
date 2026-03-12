import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/community_recipe_model.dart';
import 'cloudinary_service.dart';

class CommunityRecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _recipesRef =>
      _firestore.collection('community_recipes');

  // --- CRUD ---
  Future<String> submitRecipe(CommunityRecipe recipe) async {
    try {
      final docRef = await _recipesRef.add(recipe.toFirestore());
      debugPrint('Recipe submitted with ID: ${docRef.id}');

      // Update user's recipe count (use set+merge to avoid missing field error)
      try {
        await _firestore.collection('users').doc(recipe.userId).set({
          'totalRecipesShared': FieldValue.increment(1),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('User stats update failed: $e');
      }

      return docRef.id;
    } catch (e) {
      debugPrint('submitRecipe error: $e');
      rethrow;
    }
  }

  Future<void> updateRecipe(String recipeId, Map<String, dynamic> data) async {
    data['updatedAt'] = Timestamp.now();
    await _recipesRef.doc(recipeId).update(data);
  }

  Future<void> deleteRecipe(String recipeId, String userId) async {
    await _recipesRef.doc(recipeId).delete();
    try {
      await _firestore.collection('users').doc(userId).set({
        'totalRecipesShared': FieldValue.increment(-1),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // --- Queries ---
  // Removed composite index requirement: filter isPublished client-side
  Future<List<CommunityRecipe>> getLatestRecipes({int limit = 20}) async {
    try {
      final snapshot = await _recipesRef
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => CommunityRecipe.fromFirestore(doc))
          .where((r) => r.isPublished)
          .toList();
    } catch (e) {
      debugPrint('getLatestRecipes error: $e');
      // Fallback: no ordering
      try {
        final snapshot = await _recipesRef.limit(limit).get();
        final list = snapshot.docs
            .map((doc) => CommunityRecipe.fromFirestore(doc))
            .where((r) => r.isPublished)
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      } catch (e2) {
        debugPrint('getLatestRecipes fallback error: $e2');
        return [];
      }
    }
  }

  Future<List<CommunityRecipe>> getTrendingRecipes({int limit = 20}) async {
    try {
      final snapshot = await _recipesRef
          .orderBy('totalLikes', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => CommunityRecipe.fromFirestore(doc))
          .where((r) => r.isPublished)
          .toList();
    } catch (e) {
      debugPrint('getTrendingRecipes error: $e');
      try {
        final snapshot = await _recipesRef.limit(limit).get();
        final list = snapshot.docs
            .map((doc) => CommunityRecipe.fromFirestore(doc))
            .where((r) => r.isPublished)
            .toList();
        list.sort((a, b) => b.totalLikes.compareTo(a.totalLikes));
        return list;
      } catch (e2) {
        debugPrint('getTrendingRecipes fallback error: $e2');
        return [];
      }
    }
  }

  Future<List<CommunityRecipe>> getTopRatedRecipes({int limit = 20}) async {
    try {
      final snapshot = await _recipesRef
          .orderBy('averageRating', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => CommunityRecipe.fromFirestore(doc))
          .where((r) => r.isPublished && r.totalRatings >= 3)
          .toList();
    } catch (e) {
      debugPrint('getTopRatedRecipes error: $e');
      return [];
    }
  }

  Future<List<CommunityRecipe>> getUserRecipes(String userId,
      {int limit = 50}) async {
    try {
      final snapshot = await _recipesRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => CommunityRecipe.fromFirestore(doc))
          .toList();
    } catch (e) {
      debugPrint('getUserRecipes error: $e');
      // Fallback without ordering (avoids composite index)
      try {
        final snapshot = await _recipesRef
            .where('userId', isEqualTo: userId)
            .limit(limit)
            .get();
        final list = snapshot.docs
            .map((doc) => CommunityRecipe.fromFirestore(doc))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      } catch (e2) {
        debugPrint('getUserRecipes fallback error: $e2');
        return [];
      }
    }
  }

  Future<List<CommunityRecipe>> getRecipesByCategory(String category,
      {int limit = 20}) async {
    try {
      final snapshot = await _recipesRef
          .where('category', isEqualTo: category)
          .limit(limit)
          .get();
      final list = snapshot.docs
          .map((doc) => CommunityRecipe.fromFirestore(doc))
          .where((r) => r.isPublished)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('getRecipesByCategory error: $e');
      return [];
    }
  }

  Future<CommunityRecipe?> getRecipeById(String recipeId) async {
    try {
      final doc = await _recipesRef.doc(recipeId).get();
      if (!doc.exists) return null;
      return CommunityRecipe.fromFirestore(doc);
    } catch (e) {
      debugPrint('getRecipeById error: $e');
      return null;
    }
  }

  // --- Image Upload (Cloudinary) ---
  Future<String?> uploadRecipeImage(File imageFile) async {
    return await CloudinaryService.uploadImage(imageFile);
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
      final recipe = await getRecipeById(recipeId);
      if (recipe != null) {
        try {
          await _firestore.collection('users').doc(recipe.userId).set({
            'totalLikesReceived': FieldValue.increment(-1),
          }, SetOptions(merge: true));
        } catch (_) {}
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
        try {
          await _firestore.collection('users').doc(recipe.userId).set({
            'totalLikesReceived': FieldValue.increment(1),
          }, SetOptions(merge: true));
        } catch (_) {}
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
