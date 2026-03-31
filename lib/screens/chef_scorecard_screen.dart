import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/text_repair.dart';

class ChefScorecardScreen extends StatelessWidget {
  const ChefScorecardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isTr = provider.languageCode == 'tr';
    final completedChallenges =
        provider.weeklyChallengeProgress.where((item) => item.completed).length;
    final board = provider.neighborhoodSavingsBoard.take(6).toList();

    String clean(String value) => repairTurkishText(value);

    Widget metricCard({
      required IconData icon,
      required String label,
      required String value,
      required List<Color> colors,
    }) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: theme.colorScheme.onPrimaryContainer),
            const SizedBox(height: 18),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer
                    .withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(isTr ? 'Şef Karnem' : 'Chef Scorecard'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.22),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.18, 1.0],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2A1A5E),
                    Color(0xFF6847B5),
                    Color(0xFFF4A261)
                  ],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6847B5).withValues(alpha: 0.22),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.18),
                      ),
                    ),
                    child: const Icon(
                      Icons.workspace_premium_rounded,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    '${isTr ? "Seviye" : "Level"} ${provider.kitchenRpgProfile.level}',
                    style: theme.textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    clean(provider.kitchenLevelTitle),
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTr
                        ? 'Serini, görevlerini ve mutfaktaki yükselişini tek ekranda takip et.'
                        : 'Track your streak, missions, and kitchen growth in one place.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.15,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                metricCard(
                  icon: Icons.local_fire_department_rounded,
                  label: isTr ? 'Günlük seri' : 'Streak',
                  value: '${provider.kitchenRpgProfile.streakDays}',
                  colors: const [Color(0xFFFFE5D1), Color(0xFFFFF1E7)],
                ),
                metricCard(
                  icon: Icons.emoji_events_rounded,
                  label: isTr ? 'Tamamlanan görev' : 'Completed missions',
                  value: '$completedChallenges',
                  colors: const [Color(0xFFE8E1FF), Color(0xFFF3EEFF)],
                ),
                metricCard(
                  icon: Icons.savings_rounded,
                  label: isTr ? 'Aylık tasarruf' : 'Monthly savings',
                  value: '${provider.monthlySavingsEstimate.round()} TL',
                  colors: const [Color(0xFFDFF6EA), Color(0xFFF0FBF5)],
                ),
                metricCard(
                  icon: Icons.kitchen_rounded,
                  label: isTr ? 'Dolaptaki malzeme' : 'Pantry items',
                  value: '${provider.selectedCount}',
                  colors: const [Color(0xFFFFEADF), Color(0xFFFFF5EF)],
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              isTr ? 'Mahalle liginde durumun' : 'Your neighborhood rank',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            if (board.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.4,
                  ),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Text(
                  isTr
                      ? 'Gerçek topluluk verisi bağlanınca mahalle sıralaması burada görünecek.'
                      : 'Neighborhood rankings will appear here once real community data is connected.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              )
            else
              ...board.map(
                (entry) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: entry.isCurrentUser
                        ? theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.62)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: AppTheme.softShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: entry.isCurrentUser
                              ? theme.colorScheme.primary
                              : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '${entry.rank}',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                              color: entry.isCurrentUser
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              clean(entry.name),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${clean(entry.district(provider.languageCode))} • ${entry.completedChallenges} ${isTr ? "görev" : "missions"}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${entry.savingsValue.round()} TL',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
