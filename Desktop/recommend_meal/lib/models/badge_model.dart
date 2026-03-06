import 'package:cloud_firestore/cloud_firestore.dart';

class AppBadge {
  final String id;
  final String nameTr;
  final String nameEn;
  final String descriptionTr;
  final String descriptionEn;
  final String icon;
  final String rarity; // common, rare, epic, legendary
  final String conditionType; // recipes_shared, likes_received, ratings_given, special
  final int conditionValue; // threshold

  const AppBadge({
    required this.id,
    required this.nameTr,
    required this.nameEn,
    required this.descriptionTr,
    required this.descriptionEn,
    required this.icon,
    required this.rarity,
    required this.conditionType,
    required this.conditionValue,
  });

  factory AppBadge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppBadge(
      id: doc.id,
      nameTr: data['nameTr'] ?? '',
      nameEn: data['nameEn'] ?? '',
      descriptionTr: data['descriptionTr'] ?? '',
      descriptionEn: data['descriptionEn'] ?? '',
      icon: data['icon'] ?? '🏆',
      rarity: data['rarity'] ?? 'common',
      conditionType: data['conditionType'] ?? '',
      conditionValue: data['conditionValue'] ?? 0,
    );
  }

  factory AppBadge.fromJson(Map<String, dynamic> json) {
    return AppBadge(
      id: json['id'] ?? '',
      nameTr: json['nameTr'] ?? '',
      nameEn: json['nameEn'] ?? '',
      descriptionTr: json['descriptionTr'] ?? '',
      descriptionEn: json['descriptionEn'] ?? '',
      icon: json['icon'] ?? '🏆',
      rarity: json['rarity'] ?? 'common',
      conditionType: json['conditionType'] ?? '',
      conditionValue: json['conditionValue'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nameTr': nameTr,
        'nameEn': nameEn,
        'descriptionTr': descriptionTr,
        'descriptionEn': descriptionEn,
        'icon': icon,
        'rarity': rarity,
        'conditionType': conditionType,
        'conditionValue': conditionValue,
      };

  String getName(String locale) => locale == 'tr' ? nameTr : nameEn;
  String getDescription(String locale) =>
      locale == 'tr' ? descriptionTr : descriptionEn;

  /// Predefined badges
  static List<AppBadge> get allBadges => [
        const AppBadge(
          id: 'first_recipe',
          nameTr: 'İlk Tarif',
          nameEn: 'First Recipe',
          descriptionTr: 'İlk tarifini paylaş',
          descriptionEn: 'Share your first recipe',
          icon: '🍳',
          rarity: 'common',
          conditionType: 'recipes_shared',
          conditionValue: 1,
        ),
        const AppBadge(
          id: 'chef_5',
          nameTr: 'Aşçıbaşı',
          nameEn: 'Head Chef',
          descriptionTr: '5 tarif paylaş',
          descriptionEn: 'Share 5 recipes',
          icon: '👨‍🍳',
          rarity: 'common',
          conditionType: 'recipes_shared',
          conditionValue: 5,
        ),
        const AppBadge(
          id: 'master_chef',
          nameTr: 'Usta Şef',
          nameEn: 'Master Chef',
          descriptionTr: '25 tarif paylaş',
          descriptionEn: 'Share 25 recipes',
          icon: '🏆',
          rarity: 'rare',
          conditionType: 'recipes_shared',
          conditionValue: 25,
        ),
        const AppBadge(
          id: 'legend_chef',
          nameTr: 'Efsane Şef',
          nameEn: 'Legendary Chef',
          descriptionTr: '100 tarif paylaş',
          descriptionEn: 'Share 100 recipes',
          icon: '👑',
          rarity: 'legendary',
          conditionType: 'recipes_shared',
          conditionValue: 100,
        ),
        const AppBadge(
          id: 'liked_10',
          nameTr: 'Beğenilen',
          nameEn: 'Liked',
          descriptionTr: '10 beğeni al',
          descriptionEn: 'Receive 10 likes',
          icon: '⭐',
          rarity: 'common',
          conditionType: 'likes_received',
          conditionValue: 10,
        ),
        const AppBadge(
          id: 'popular_50',
          nameTr: 'Popüler Şef',
          nameEn: 'Popular Chef',
          descriptionTr: '50 beğeni al',
          descriptionEn: 'Receive 50 likes',
          icon: '🌟',
          rarity: 'rare',
          conditionType: 'likes_received',
          conditionValue: 50,
        ),
        const AppBadge(
          id: 'superstar',
          nameTr: 'Süperstar',
          nameEn: 'Superstar',
          descriptionTr: '100 beğeni al',
          descriptionEn: 'Receive 100 likes',
          icon: '💎',
          rarity: 'legendary',
          conditionType: 'likes_received',
          conditionValue: 100,
        ),
        const AppBadge(
          id: 'critic_10',
          nameTr: 'Eleştirmen',
          nameEn: 'Critic',
          descriptionTr: '10 tarif puanla',
          descriptionEn: 'Rate 10 recipes',
          icon: '📊',
          rarity: 'common',
          conditionType: 'ratings_given',
          conditionValue: 10,
        ),
        const AppBadge(
          id: 'critic_50',
          nameTr: 'Baş Eleştirmen',
          nameEn: 'Head Critic',
          descriptionTr: '50 tarif puanla',
          descriptionEn: 'Rate 50 recipes',
          icon: '🎯',
          rarity: 'rare',
          conditionType: 'ratings_given',
          conditionValue: 50,
        ),
      ];
}

class UserBadge {
  final String id;
  final String userId;
  final String badgeId;
  final DateTime unlockedAt;

  const UserBadge({
    required this.id,
    required this.userId,
    required this.badgeId,
    required this.unlockedAt,
  });

  factory UserBadge.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserBadge(
      id: doc.id,
      userId: data['userId'] ?? '',
      badgeId: data['badgeId'] ?? '',
      unlockedAt:
          (data['unlockedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'badgeId': badgeId,
        'unlockedAt': Timestamp.fromDate(unlockedAt),
      };
}
