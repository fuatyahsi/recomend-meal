import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class FollowService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _followsRef => _firestore.collection('follows');

  // Takip et / takipten çık
  Future<bool> toggleFollow(String currentUserId, String targetUserId) async {
    final existing = await _followsRef
        .where('followerId', isEqualTo: currentUserId)
        .where('followingId', isEqualTo: targetUserId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      // Takipten çık
      await existing.docs.first.reference.delete();
      return false;
    } else {
      // Takip et
      await _followsRef.add({
        'followerId': currentUserId,
        'followingId': targetUserId,
        'createdAt': Timestamp.now(),
      });
      return true;
    }
  }

  // Takip ediyor mu?
  Future<bool> isFollowing(String currentUserId, String targetUserId) async {
    final snapshot = await _followsRef
        .where('followerId', isEqualTo: currentUserId)
        .where('followingId', isEqualTo: targetUserId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  // Takipçi sayısı
  Future<int> getFollowerCount(String userId) async {
    final snapshot = await _followsRef
        .where('followingId', isEqualTo: userId)
        .get();
    return snapshot.docs.length;
  }

  // Takip edilen sayısı
  Future<int> getFollowingCount(String userId) async {
    final snapshot = await _followsRef
        .where('followerId', isEqualTo: userId)
        .get();
    return snapshot.docs.length;
  }

  // Takip ettiğim kullanıcıların ID'leri
  Future<List<String>> getFollowingIds(String userId) async {
    final snapshot = await _followsRef
        .where('followerId', isEqualTo: userId)
        .get();
    return snapshot.docs
        .map((doc) => doc['followingId'] as String)
        .toList();
  }

  // Takipçi listesi (AppUser olarak)
  Future<List<AppUser>> getFollowers(String userId) async {
    final snapshot = await _followsRef
        .where('followingId', isEqualTo: userId)
        .get();
    final followerIds = snapshot.docs
        .map((doc) => doc['followerId'] as String)
        .toList();

    if (followerIds.isEmpty) return [];

    final users = <AppUser>[];
    // Firestore 'in' query max 10 item
    for (var i = 0; i < followerIds.length; i += 10) {
      final batch = followerIds.skip(i).take(10).toList();
      final userSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      users.addAll(
          userSnapshot.docs.map((doc) => AppUser.fromFirestore(doc)));
    }
    return users;
  }

  // Takip ettiklerim listesi (AppUser olarak)
  Future<List<AppUser>> getFollowing(String userId) async {
    final snapshot = await _followsRef
        .where('followerId', isEqualTo: userId)
        .get();
    final followingIds = snapshot.docs
        .map((doc) => doc['followingId'] as String)
        .toList();

    if (followingIds.isEmpty) return [];

    final users = <AppUser>[];
    for (var i = 0; i < followingIds.length; i += 10) {
      final batch = followingIds.skip(i).take(10).toList();
      final userSnapshot = await _firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: batch)
          .get();
      users.addAll(
          userSnapshot.docs.map((doc) => AppUser.fromFirestore(doc)));
    }
    return users;
  }
}
