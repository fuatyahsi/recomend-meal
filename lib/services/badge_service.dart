import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/badge_model.dart';
import '../models/user_model.dart';

class BadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check and award badges based on user stats
  Future<List<AppBadge>> checkAndAwardBadges(AppUser user) async {
    final allBadges = AppBadge.allBadges;
    final newlyAwarded = <AppBadge>[];

    for (final badge in allBadges) {
      if (user.badges.contains(badge.id)) continue; // Already has this badge

      bool earned = false;
      switch (badge.conditionType) {
        case 'recipes_shared':
          earned = user.totalRecipesShared >= badge.conditionValue;
          break;
        case 'likes_received':
          earned = user.totalLikesReceived >= badge.conditionValue;
          break;
        case 'ratings_given':
          earned = user.totalRatingsGiven >= badge.conditionValue;
          break;
      }

      if (earned) {
        await _awardBadge(user.uid, badge.id);
        newlyAwarded.add(badge);
      }
    }

    return newlyAwarded;
  }

  Future<void> _awardBadge(String userId, String badgeId) async {
    // Add to user_badges collection
    await _firestore.collection('user_badges').add({
      'userId': userId,
      'badgeId': badgeId,
      'unlockedAt': Timestamp.now(),
    });

    // Update user's badges array
    await _firestore.collection('users').doc(userId).update({
      'badges': FieldValue.arrayUnion([badgeId]),
    });
  }

  Future<List<UserBadge>> getUserBadges(String userId) async {
    final snapshot = await _firestore
        .collection('user_badges')
        .where('userId', isEqualTo: userId)
        .orderBy('unlockedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => UserBadge.fromFirestore(doc))
        .toList();
  }

  /// Get badge progress for a user (returns map of badgeId -> progress %)
  Map<String, double> getBadgeProgress(AppUser user) {
    final progress = <String, double>{};
    for (final badge in AppBadge.allBadges) {
      if (user.badges.contains(badge.id)) {
        progress[badge.id] = 1.0;
        continue;
      }

      double current = 0;
      switch (badge.conditionType) {
        case 'recipes_shared':
          current = user.totalRecipesShared.toDouble();
          break;
        case 'likes_received':
          current = user.totalLikesReceived.toDouble();
          break;
        case 'ratings_given':
          current = user.totalRatingsGiven.toDouble();
          break;
      }

      progress[badge.id] =
          (current / badge.conditionValue).clamp(0.0, 1.0);
    }
    return progress;
  }
}
