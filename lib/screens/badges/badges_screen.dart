import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/badge_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/badge_service.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isTr = AppLocalizations.of(context).languageCode == 'tr';
    final locale = isTr ? 'tr' : 'en';

    final user = auth.currentUser;
    final allBadges = AppBadge.allBadges;
    final badgeService = BadgeService();
    final progress = user != null ? badgeService.getBadgeProgress(user) : <String, double>{};

    return Scaffold(
      appBar: AppBar(
        title: Text(isTr ? 'Rozet Koleksiyonu' : 'Badge Collection'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.secondary,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🏅', style: TextStyle(fontSize: 36)),
                const SizedBox(width: 16),
                Column(
                  children: [
                    Text(
                      '${user?.badges.length ?? 0} / ${allBadges.length}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      isTr ? 'Rozet Kazanıldı' : 'Badges Earned',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Badge grid
          ...allBadges.map((badge) {
            final isEarned = user?.badges.contains(badge.id) ?? false;
            final prog = progress[badge.id] ?? 0.0;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Badge icon
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isEarned
                            ? _getRarityColor(badge.rarity).withOpacity(0.15)
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          isEarned ? badge.icon : '🔒',
                          style: TextStyle(
                            fontSize: isEarned ? 28 : 24,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                badge.getName(locale),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isEarned ? null : Colors.grey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getRarityColor(badge.rarity)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _getRarityText(badge.rarity, isTr),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _getRarityColor(badge.rarity),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            badge.getDescription(locale),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isEarned
                                  ? theme.colorScheme.onSurfaceVariant
                                  : Colors.grey,
                            ),
                          ),
                          if (!isEarned) ...[
                            const SizedBox(height: 8),
                            // Progress bar
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: prog,
                                      backgroundColor: Colors.grey.shade200,
                                      color: _getRarityColor(badge.rarity),
                                      minHeight: 6,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${(prog * 100).round()}%',
                                  style: theme.textTheme.bodySmall
                                      ?.copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (isEarned)
                      const Icon(Icons.check_circle, color: Colors.green),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'common': return Colors.blue;
      case 'rare': return Colors.purple;
      case 'epic': return Colors.orange;
      case 'legendary': return Colors.amber;
      default: return Colors.grey;
    }
  }

  String _getRarityText(String rarity, bool isTr) {
    switch (rarity) {
      case 'common': return isTr ? 'Yaygın' : 'Common';
      case 'rare': return isTr ? 'Nadir' : 'Rare';
      case 'epic': return isTr ? 'Epik' : 'Epic';
      case 'legendary': return isTr ? 'Efsanevi' : 'Legendary';
      default: return rarity;
    }
  }
}
