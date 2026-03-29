import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/cookbook_model.dart';

class CookbookAlreadyExistsException implements Exception {
  final String normalizedName;

  const CookbookAlreadyExistsException(this.normalizedName);

  @override
  String toString() => 'CookbookAlreadyExistsException($normalizedName)';
}

class CookbookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _cookbooksRef => _firestore.collection('cookbooks');

  String _normalizeCookbookName(String name) {
    return name.trim().toLowerCase();
  }

  String _buildCookbookDocId(String userId, String name) {
    final normalizedName = _normalizeCookbookName(name);
    return '$userId:${Uri.encodeComponent(normalizedName)}';
  }

  Future<String> createCookbook({
    required String userId,
    required String name,
    required String emoji,
  }) async {
    final trimmedName = name.trim();
    final docRef = _cookbooksRef.doc(_buildCookbookDocId(userId, trimmedName));

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (snapshot.exists) {
        throw CookbookAlreadyExistsException(
          _normalizeCookbookName(trimmedName),
        );
      }

      transaction.set(
        docRef,
        Cookbook(
          id: docRef.id,
          userId: userId,
          name: trimmedName,
          emoji: emoji,
          createdAt: DateTime.now(),
        ).toFirestore(),
      );

      return docRef.id;
    });
  }

  Future<List<Cookbook>> getUserCookbooks(String userId) async {
    final snapshot = await _cookbooksRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Cookbook.fromFirestore(doc)).toList();
  }

  Future<void> toggleRecipeInCookbook(
      String cookbookId, String recipeId) async {
    final doc = await _cookbooksRef.doc(cookbookId).get();
    final cookbook = Cookbook.fromFirestore(doc);

    if (cookbook.recipeIds.contains(recipeId)) {
      await _cookbooksRef.doc(cookbookId).update({
        'recipeIds': FieldValue.arrayRemove([recipeId]),
      });
    } else {
      await _cookbooksRef.doc(cookbookId).update({
        'recipeIds': FieldValue.arrayUnion([recipeId]),
      });
    }
  }

  Future<void> toggleCommunityRecipeInCookbook(
    String cookbookId,
    String communityRecipeId,
  ) async {
    final doc = await _cookbooksRef.doc(cookbookId).get();
    final cookbook = Cookbook.fromFirestore(doc);

    if (cookbook.communityRecipeIds.contains(communityRecipeId)) {
      await _cookbooksRef.doc(cookbookId).update({
        'communityRecipeIds': FieldValue.arrayRemove([communityRecipeId]),
      });
    } else {
      await _cookbooksRef.doc(cookbookId).update({
        'communityRecipeIds': FieldValue.arrayUnion([communityRecipeId]),
      });
    }
  }

  Future<void> deleteCookbook(String cookbookId) async {
    await _cookbooksRef.doc(cookbookId).delete();
  }

  Future<void> updateCookbook(
    String cookbookId, {
    String? name,
    String? emoji,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name.trim();
    if (emoji != null) data['emoji'] = emoji;
    if (data.isNotEmpty) {
      await _cookbooksRef.doc(cookbookId).update(data);
    }
  }
}
