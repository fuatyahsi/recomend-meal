import '../models/kitchen_rpg.dart';

class KitchenRpgService {
  static const pantrySyncCooldown = Duration(minutes: 20);

  static const List<KitchenWeeklyChallenge> weeklyChallenges = [
    KitchenWeeklyChallenge(
      id: 'pantry_guard',
      titleTr: 'Dolap Nobeti',
      titleEn: 'Pantry Watch',
      descriptionTr: 'Bu hafta dolabini 3 kez guncelle.',
      descriptionEn: 'Update your pantry 3 times this week.',
      activityType: KitchenActivityType.pantrySync,
      target: 3,
      rewardXp: 90,
      rewardBadgeId: 'pantry_guard',
    ),
    KitchenWeeklyChallenge(
      id: 'menu_architect',
      titleTr: 'Menu Mimari',
      titleEn: 'Menu Architect',
      descriptionTr: 'Bu hafta 4 ogun menusu planla.',
      descriptionEn: 'Plan 4 meal menus this week.',
      activityType: KitchenActivityType.mealPlan,
      target: 4,
      rewardXp: 120,
      rewardBadgeId: 'menu_architect',
    ),
    KitchenWeeklyChallenge(
      id: 'waste_rescue',
      titleTr: 'Israf Avcisi',
      titleEn: 'Waste Rescue',
      descriptionTr: 'Riskli 2 malzemeyi menulere dahil ederek kurtar.',
      descriptionEn: 'Rescue 2 risky ingredients through planned meals.',
      activityType: KitchenActivityType.wasteRescue,
      target: 2,
      rewardXp: 140,
      rewardBadgeId: 'waste_rescue',
    ),
    KitchenWeeklyChallenge(
      id: 'scanner_blitz',
      titleTr: 'Fis Blitz',
      titleEn: 'Receipt Blitz',
      descriptionTr: 'Bu hafta 2 kez fis veya tabak analizi yap.',
      descriptionEn: 'Run 2 receipt or plate analyses this week.',
      activityType: KitchenActivityType.receiptScan,
      target: 2,
      rewardXp: 80,
      rewardBadgeId: 'scanner_blitz',
    ),
    KitchenWeeklyChallenge(
      id: 'roulette_host',
      titleTr: 'Rulet Sunucusu',
      titleEn: 'Roulette Host',
      descriptionTr: 'Rulet ya da sosyal duelloyu 2 kez calistir.',
      descriptionEn: 'Run roulette or a social duel 2 times.',
      activityType: KitchenActivityType.roulettePlay,
      target: 2,
      rewardXp: 70,
      rewardBadgeId: 'roulette_host',
    ),
  ];

  KitchenRpgProfile registerActivity(
    KitchenRpgProfile profile,
    KitchenActivityType type, {
    DateTime? now,
    int amount = 1,
    double savedValue = 0,
  }) {
    final safeNow = now ?? DateTime.now();
    var next = _normalizeProfile(profile, safeNow);
    final activityKey = type.key;

    final weeklyCounters = {...next.weeklyCounters};
    weeklyCounters.update(
      activityKey,
      (value) => value + amount,
      ifAbsent: () => amount,
    );

    final lifetimeCounters = {...next.lifetimeCounters};
    lifetimeCounters.update(
      activityKey,
      (value) => value + amount,
      ifAbsent: () => amount,
    );

    final nextSavingsMonthKey = kitchenMonthKey(safeNow);
    final monthlySavings = next.savingsMonthKey == nextSavingsMonthKey
        ? next.monthlySavingsValue + savedValue
        : savedValue;

    next = next.copyWith(
      xp: next.xp + (_xpFor(type) * amount),
      streakDays: _nextStreakDays(next.lastActiveAt, safeNow, next.streakDays),
      lastActiveAt: safeNow,
      lastPantrySyncAt: type == KitchenActivityType.pantrySync
          ? safeNow
          : next.lastPantrySyncAt,
      savingsMonthKey: nextSavingsMonthKey,
      monthlySavingsValue: monthlySavings,
      weeklyCounters: weeklyCounters,
      lifetimeCounters: lifetimeCounters,
    );

    next = _awardMilestoneBadges(next);
    next = _claimCompletedChallenges(next);
    return next;
  }

  bool shouldGrantPantrySync(KitchenRpgProfile profile, DateTime now) {
    final last = profile.lastPantrySyncAt;
    if (last == null) return true;
    return now.difference(last) >= pantrySyncCooldown;
  }

  List<KitchenWeeklyChallengeProgress> buildWeeklyChallengeProgress(
    KitchenRpgProfile profile,
  ) {
    return weeklyChallenges.map((challenge) {
      final progress = profile.weeklyCounters[challenge.activityType.key] ?? 0;
      return KitchenWeeklyChallengeProgress(
        challenge: challenge,
        progress: progress,
        claimed: profile.claimedChallengeIds.contains(challenge.id),
      );
    }).toList();
  }

  String titleForLevel(int level, String locale) {
    final titlesTr = [
      'Acemi Cirak',
      'Tarif Nobetcisi',
      'Planlama Ustasi',
      'Lezzet Avcisi',
      'Mutfak Taktikcisi',
      'Fridge Hero',
      'MasterChef Modu',
    ];
    final titlesEn = [
      'Rookie Prep',
      'Recipe Scout',
      'Planning Pro',
      'Flavor Hunter',
      'Kitchen Tactician',
      'Fridge Hero',
      'MasterChef Mode',
    ];
    final index = ((level - 1) ~/ 2).clamp(0, titlesTr.length - 1);
    return locale == 'tr' ? titlesTr[index] : titlesEn[index];
  }

  KitchenRpgProfile _normalizeProfile(
    KitchenRpgProfile profile,
    DateTime now,
  ) {
    final currentWeekKey = kitchenWeekKey(now);
    if (profile.activeWeekKey == currentWeekKey &&
        profile.savingsMonthKey == kitchenMonthKey(now)) {
      return profile;
    }

    return profile.copyWith(
      activeWeekKey: currentWeekKey,
      weeklyCounters:
          profile.activeWeekKey == currentWeekKey ? profile.weeklyCounters : {},
      claimedChallengeIds: profile.activeWeekKey == currentWeekKey
          ? profile.claimedChallengeIds
          : [],
      savingsMonthKey: kitchenMonthKey(now),
      monthlySavingsValue: profile.savingsMonthKey == kitchenMonthKey(now)
          ? profile.monthlySavingsValue
          : 0,
    );
  }

  int _nextStreakDays(DateTime? lastActiveAt, DateTime now, int streakDays) {
    if (lastActiveAt == null) return 1;
    final lastDate = DateTime(
      lastActiveAt.year,
      lastActiveAt.month,
      lastActiveAt.day,
    );
    final currentDate = DateTime(now.year, now.month, now.day);
    final diffDays = currentDate.difference(lastDate).inDays;
    if (diffDays <= 0) return streakDays;
    if (diffDays == 1) return streakDays + 1;
    return 1;
  }

  int _xpFor(KitchenActivityType type) {
    switch (type) {
      case KitchenActivityType.pantrySync:
        return 20;
      case KitchenActivityType.mealPlan:
        return 35;
      case KitchenActivityType.menuCooked:
        return 50;
      case KitchenActivityType.wasteRescue:
        return 60;
      case KitchenActivityType.receiptScan:
        return 30;
      case KitchenActivityType.visionAnalysis:
        return 18;
      case KitchenActivityType.roulettePlay:
        return 24;
    }
  }

  KitchenRpgProfile _awardMilestoneBadges(KitchenRpgProfile profile) {
    final badges = [...profile.unlockedBadges];

    void unlock(String id) {
      if (!badges.contains(id)) {
        badges.add(id);
      }
    }

    final lifetime = profile.lifetimeCounters;
    if (profile.streakDays >= 3) unlock('streak_3');
    if (profile.streakDays >= 7) unlock('streak_7');
    if ((lifetime[KitchenActivityType.mealPlan.key] ?? 0) >= 10) {
      unlock('menu_master');
    }
    if ((lifetime[KitchenActivityType.wasteRescue.key] ?? 0) >= 5) {
      unlock('zero_waste_guard');
    }
    if ((lifetime[KitchenActivityType.receiptScan.key] ?? 0) >= 3) {
      unlock('scanner_ready');
    }
    if ((lifetime[KitchenActivityType.roulettePlay.key] ?? 0) >= 5) {
      unlock('roulette_regular');
    }

    return profile.copyWith(unlockedBadges: badges);
  }

  KitchenRpgProfile _claimCompletedChallenges(KitchenRpgProfile profile) {
    var next = profile;
    final claimed = [...profile.claimedChallengeIds];
    final badges = [...profile.unlockedBadges];

    for (final challenge in weeklyChallenges) {
      if (claimed.contains(challenge.id)) continue;
      final progress = profile.weeklyCounters[challenge.activityType.key] ?? 0;
      if (progress < challenge.target) continue;

      claimed.add(challenge.id);
      if (challenge.rewardBadgeId != null &&
          !badges.contains(challenge.rewardBadgeId)) {
        badges.add(challenge.rewardBadgeId!);
      }
      next = next.copyWith(
        xp: next.xp + challenge.rewardXp,
        claimedChallengeIds: claimed,
        unlockedBadges: badges,
      );
    }

    return next;
  }
}
