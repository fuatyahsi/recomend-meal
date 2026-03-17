enum KitchenActivityType {
  pantrySync,
  mealPlan,
  menuCooked,
  wasteRescue,
  receiptScan,
  visionAnalysis,
  roulettePlay,
}

extension KitchenActivityTypeKey on KitchenActivityType {
  String get key {
    switch (this) {
      case KitchenActivityType.pantrySync:
        return 'pantry_sync';
      case KitchenActivityType.mealPlan:
        return 'meal_plan';
      case KitchenActivityType.menuCooked:
        return 'menu_cooked';
      case KitchenActivityType.wasteRescue:
        return 'waste_rescue';
      case KitchenActivityType.receiptScan:
        return 'receipt_scan';
      case KitchenActivityType.visionAnalysis:
        return 'vision_analysis';
      case KitchenActivityType.roulettePlay:
        return 'roulette_play';
    }
  }
}

String kitchenWeekKey(DateTime date) {
  final startOfYear = DateTime(date.year, 1, 1);
  final weekOfYear = ((date.difference(startOfYear).inDays) / 7).floor();
  return '${date.year}-w$weekOfYear';
}

String kitchenMonthKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  return '${date.year}-$month';
}

class KitchenRpgProfile {
  final int xp;
  final int streakDays;
  final DateTime? lastActiveAt;
  final DateTime? lastPantrySyncAt;
  final String activeWeekKey;
  final String savingsMonthKey;
  final double monthlySavingsValue;
  final Map<String, int> weeklyCounters;
  final Map<String, int> lifetimeCounters;
  final List<String> unlockedBadges;
  final List<String> claimedChallengeIds;

  const KitchenRpgProfile({
    required this.xp,
    required this.streakDays,
    required this.lastActiveAt,
    required this.lastPantrySyncAt,
    required this.activeWeekKey,
    required this.savingsMonthKey,
    required this.monthlySavingsValue,
    required this.weeklyCounters,
    required this.lifetimeCounters,
    required this.unlockedBadges,
    required this.claimedChallengeIds,
  });

  factory KitchenRpgProfile.initial([DateTime? now]) {
    final safeNow = now ?? DateTime.now();
    return KitchenRpgProfile(
      xp: 0,
      streakDays: 0,
      lastActiveAt: null,
      lastPantrySyncAt: null,
      activeWeekKey: kitchenWeekKey(safeNow),
      savingsMonthKey: kitchenMonthKey(safeNow),
      monthlySavingsValue: 0,
      weeklyCounters: const {},
      lifetimeCounters: const {},
      unlockedBadges: const [],
      claimedChallengeIds: const [],
    );
  }

  factory KitchenRpgProfile.fromJson(Map<String, dynamic> json) {
    return KitchenRpgProfile(
      xp: json['xp'] as int? ?? 0,
      streakDays: json['streakDays'] as int? ?? 0,
      lastActiveAt: json['lastActiveAt'] == null
          ? null
          : DateTime.tryParse(json['lastActiveAt'].toString()),
      lastPantrySyncAt: json['lastPantrySyncAt'] == null
          ? null
          : DateTime.tryParse(json['lastPantrySyncAt'].toString()),
      activeWeekKey:
          json['activeWeekKey'] as String? ?? kitchenWeekKey(DateTime.now()),
      savingsMonthKey:
          json['savingsMonthKey'] as String? ?? kitchenMonthKey(DateTime.now()),
      monthlySavingsValue:
          (json['monthlySavingsValue'] as num?)?.toDouble() ?? 0,
      weeklyCounters:
          (json['weeklyCounters'] as Map<String, dynamic>? ?? const {})
              .map((key, value) => MapEntry(key, (value as num).round())),
      lifetimeCounters:
          (json['lifetimeCounters'] as Map<String, dynamic>? ?? const {})
              .map((key, value) => MapEntry(key, (value as num).round())),
      unlockedBadges: (json['unlockedBadges'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      claimedChallengeIds:
          (json['claimedChallengeIds'] as List<dynamic>? ?? const [])
              .map((value) => value.toString())
              .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'xp': xp,
        'streakDays': streakDays,
        'lastActiveAt': lastActiveAt?.toIso8601String(),
        'lastPantrySyncAt': lastPantrySyncAt?.toIso8601String(),
        'activeWeekKey': activeWeekKey,
        'savingsMonthKey': savingsMonthKey,
        'monthlySavingsValue': monthlySavingsValue,
        'weeklyCounters': weeklyCounters,
        'lifetimeCounters': lifetimeCounters,
        'unlockedBadges': unlockedBadges,
        'claimedChallengeIds': claimedChallengeIds,
      };

  KitchenRpgProfile copyWith({
    int? xp,
    int? streakDays,
    DateTime? lastActiveAt,
    DateTime? lastPantrySyncAt,
    String? activeWeekKey,
    String? savingsMonthKey,
    double? monthlySavingsValue,
    Map<String, int>? weeklyCounters,
    Map<String, int>? lifetimeCounters,
    List<String>? unlockedBadges,
    List<String>? claimedChallengeIds,
  }) {
    return KitchenRpgProfile(
      xp: xp ?? this.xp,
      streakDays: streakDays ?? this.streakDays,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      lastPantrySyncAt: lastPantrySyncAt ?? this.lastPantrySyncAt,
      activeWeekKey: activeWeekKey ?? this.activeWeekKey,
      savingsMonthKey: savingsMonthKey ?? this.savingsMonthKey,
      monthlySavingsValue: monthlySavingsValue ?? this.monthlySavingsValue,
      weeklyCounters: weeklyCounters ?? this.weeklyCounters,
      lifetimeCounters: lifetimeCounters ?? this.lifetimeCounters,
      unlockedBadges: unlockedBadges ?? this.unlockedBadges,
      claimedChallengeIds: claimedChallengeIds ?? this.claimedChallengeIds,
    );
  }

  int get level => 1 + (xp ~/ 120);
}

class KitchenWeeklyChallenge {
  final String id;
  final String titleTr;
  final String titleEn;
  final String descriptionTr;
  final String descriptionEn;
  final KitchenActivityType activityType;
  final int target;
  final int rewardXp;
  final String? rewardBadgeId;

  const KitchenWeeklyChallenge({
    required this.id,
    required this.titleTr,
    required this.titleEn,
    required this.descriptionTr,
    required this.descriptionEn,
    required this.activityType,
    required this.target,
    required this.rewardXp,
    this.rewardBadgeId,
  });

  String title(String locale) => locale == 'tr' ? titleTr : titleEn;
  String description(String locale) =>
      locale == 'tr' ? descriptionTr : descriptionEn;
}

class KitchenWeeklyChallengeProgress {
  final KitchenWeeklyChallenge challenge;
  final int progress;
  final bool claimed;

  const KitchenWeeklyChallengeProgress({
    required this.challenge,
    required this.progress,
    required this.claimed,
  });

  bool get completed => progress >= challenge.target;
}
