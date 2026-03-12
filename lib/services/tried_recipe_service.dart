import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/tried_recipe_model.dart';
import 'cloudinary_service.dart';

class TriedRecipeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _triedRef => _firestore.collection('tried_recipes');

  // "Denedim" fotoğrafı paylaş
  Future<TriedRecipe?> submitTriedRecipe({
    required String recipeId,
    required String userId,
    required String userDisplayName,
    required File imageFile,
    String comment = '',
  }) async {
    try {
      // Cloudinary'ye yükle
      debugPrint('TriedService: Uploading image for recipe $recipeId');
      final imageUrl = await CloudinaryService.uploadImage(imageFile);
      if (imageUrl == null) {
        debugPrint('TriedService: Cloudinary upload returned null');
        throw Exception('Image upload failed');
      }

      debugPrint('TriedService: Image uploaded, saving to Firestore...');
      final tried = TriedRecipe(
        id: '',
        recipeId: recipeId,
        userId: userId,
        userDisplayName: userDisplayName,
        imageUrl: imageUrl,
        comment: comment,
        createdAt: DateTime.now(),
      );

      final docRef = await _triedRef.add(tried.toFirestore());
      debugPrint('TriedService: Saved to Firestore with ID: ${docRef.id}');

      return TriedRecipe(
        id: docRef.id,
        recipeId: recipeId,
        userId: userId,
        userDisplayName: userDisplayName,
        imageUrl: imageUrl,
        comment: comment,
        createdAt: tried.createdAt,
      );
    } catch (e) {
      debugPrint('TriedService: ERROR: $e');
      rethrow;
    }
  }

  // Bir tarifin "denedim" fotoğraflarını getir
  Future<List<TriedRecipe>> getTriedPhotos(String recipeId, {int limit = 20}) async {
    debugPrint('TriedService: getTriedPhotos called for recipeId: $recipeId');

    // Yöntem 1: where + orderBy (composite index gerekli)
    try {
      final snapshot = await _triedRef
          .where('recipeId', isEqualTo: recipeId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      debugPrint('TriedService: Method 1 success, found ${snapshot.docs.length} docs');
      return snapshot.docs.map((doc) => TriedRecipe.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('TriedService: Method 1 failed: $e');
    }

    // Yöntem 2: sadece where (index gerekmez)
    try {
      final snapshot = await _triedRef
          .where('recipeId', isEqualTo: recipeId)
          .limit(limit)
          .get();
      debugPrint('TriedService: Method 2 success, found ${snapshot.docs.length} docs');
      final list = snapshot.docs.map((doc) => TriedRecipe.fromFirestore(doc)).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    } catch (e) {
      debugPrint('TriedService: Method 2 failed: $e');
    }

    // Yöntem 3: tüm koleksiyonu çek, client-side filtrele
    try {
      final snapshot = await _triedRef.limit(200).get();
      debugPrint('TriedService: Method 3 fetched ${snapshot.docs.length} total docs');
      final list = snapshot.docs
          .map((doc) => TriedRecipe.fromFirestore(doc))
          .where((t) => t.recipeId == recipeId)
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      debugPrint('TriedService: Method 3 filtered to ${list.length} docs for recipe');
      return list.take(limit).toList();
    } catch (e) {
      debugPrint('TriedService: Method 3 failed: $e');
      return [];
    }
  }

  // Kullanıcının tüm "denedim" fotoğrafları
  Future<List<TriedRecipe>> getUserTriedPhotos(String userId, {int limit = 50}) async {
    try {
      final snapshot = await _triedRef
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) => TriedRecipe.fromFirestore(doc)).toList();
    } catch (e) {
      debugPrint('TriedService: getUserTriedPhotos error: $e');
      try {
        final snapshot = await _triedRef
            .where('userId', isEqualTo: userId)
            .limit(limit)
            .get();
        final list = snapshot.docs.map((doc) => TriedRecipe.fromFirestore(doc)).toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      } catch (e2) {
        debugPrint('TriedService: getUserTriedPhotos fallback error: $e2');
        return [];
      }
    }
  }

  // Denedim fotoğrafı sil
  Future<void> deleteTriedRecipe(String triedId) async {
    await _triedRef.doc(triedId).delete();
  }
}
