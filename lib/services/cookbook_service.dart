import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cookbook_model.dart';

class CookbookService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _cookbooksRef => _firestore.collection('cookbooks');

  // Defter oluştur
  Future<String> createCookbook({
    required String userId,
    required String name,
    required String emoji,
  }) async {
    final doc = await _cookbooksRef.add(Cookbook(
      id: '',
      userId: userId,
      name: name,
      emoji: emoji,
      createdAt: DateTime.now(),
    ).toFirestore());
    return doc.id;
  }

  // Kullanıcının defterlerini getir
  Future<List<Cookbook>> getUserCookbooks(String userId) async {
    final snapshot = await _cookbooksRef
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => Cookbook.fromFirestore(doc)).toList();
  }

  // Deftere built-in tarif ekle/çıkar
  Future<void> toggleRecipeInCookbook(String cookbookId, String recipeId) async {
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

  // Deftere topluluk tarifi ekle/çıkar
  Future<void> toggleCommunityRecipeInCookbook(
      String cookbookId, String communityRecipeId) async {
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

  // Defter sil
  Future<void> deleteCookbook(String cookbookId) async {
    await _cookbooksRef.doc(cookbookId).delete();
  }

  // Defter güncelle
  Future<void> updateCookbook(
      String cookbookId, {String? name, String? emoji}) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (emoji != null) data['emoji'] = emoji;
    if (data.isNotEmpty) {
      await _cookbooksRef.doc(cookbookId).update(data);
    }
  }
}
