import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/smart_kitchen.dart';
import '../providers/app_provider.dart';
import 'recipe_detail_screen.dart';

class SmartKitchenScreen extends StatelessWidget {
  const SmartKitchenScreen({super.key});

  static const _markets = ['Migros', 'CarrefourSA', 'A101', 'SOK', 'BIM'];
  static const _leadOptions = [15, 30, 45, 60, 90];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final isTr = provider.languageCode == 'tr';
    final prefs = provider.smartKitchenPreferences;
    final nextMealId = provider.getNextPlannedMealId();
    final suggestions =
        provider.getPersonalizedSuggestions(mealId: nextMealId, limit: 3);
    final reminderPreviews = provider.getUpcomingReminderPreviews(limit: 3);
    final shoppingList = provider.getSmartShoppingSummary(nextMealId);

    return Scaffold(
      appBar: AppBar(
        title: Text(isTr ? 'Akilli Mutfak Asistani' : 'Smart Kitchen Assistant'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _IntroCard(
            title: isTr
                ? 'Eve donmeden aksam planin hazir olsun'
                : 'Plan dinner before you get home',
            subtitle: isTr
                ? 'Rutinlerini kaydet, uygulama seni tanisin, ne pisirecegini ve ne alman gerektigini one cikarsin.'
                : 'Save routines so the app can learn your rhythm, suggest meals and surface what to buy.',
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: isTr ? 'Ogun rutinleri' : 'Meal routines',
            subtitle: isTr
                ? 'Hafta ici ve hafta sonu saatlerini ayarla.'
                : 'Set weekday and weekend times.',
          ),
          const SizedBox(height: 12),
          ...prefs.mealSlots.map(
            (slot) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _MealRoutineCard(
                slot: slot,
                isTr: isTr,
                onToggle: (value) {
                  provider.setMealSlotEnabled(slot.id, value);
                },
                onPickWeekday: () => _pickTime(
                  context,
                  initialMinutes: slot.weekdayMinutes,
                  onSelected: (minutes) {
                    provider.setMealSlotTime(
                      slot.id,
                      isWeekend: false,
                      minutesAfterMidnight: minutes,
                    );
                  },
                ),
                onPickWeekend: () => _pickTime(
                  context,
                  initialMinutes: slot.weekendMinutes,
                  onSelected: (minutes) {
                    provider.setMealSlotTime(
                      slot.id,
                      isWeekend: true,
                      minutesAfterMidnight: minutes,
                    );
                  },
                ),
                onLeadChanged: (minutes) {
                  provider.setMealLeadMinutes(slot.id, minutes);
                },
              ),
            ),
          ),
          const SizedBox(height: 8),
          _SectionTitle(
            title: isTr ? 'Asistan tercihleri' : 'Assistant preferences',
            subtitle: isTr
                ? 'Bildirim ve kisilesme davranisini hazirla.'
                : 'Prepare notifications and personalization behavior.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: prefs.eveningDriveHomeSuggestions,
                  onChanged: (value) {
                    provider.setEveningDriveHomeSuggestions(value);
                  },
                  title: Text(
                    isTr
                        ? 'Aksam arabada oneriler hazir olsun'
                        : 'Prepare evening commute suggestions',
                  ),
                  subtitle: Text(
                    isTr
                        ? 'Aksam yemegi icin secenekler ve eksik urunler one ciksin.'
                        : 'Surface dinner options and missing items before you get home.',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: prefs.schoolBreakfastNudges,
                  onChanged: (value) {
                    provider.setSchoolBreakfastNudges(value);
                  },
                  title: Text(
                    isTr
                        ? 'Sabah kahvalti hatirlatmasi'
                        : 'Morning breakfast nudges',
                  ),
                  subtitle: Text(
                    isTr
                        ? 'Cocuk okula gitmeden once kahvalti planini hatirlat.'
                        : 'Remind breakfast before school-time mornings.',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: prefs.priceComparisonEnabled,
                  onChanged: (value) {
                    provider.setPriceComparisonEnabled(value);
                  },
                  title: Text(
                    isTr
                        ? 'Market fiyat karsilastirma hazirligi'
                        : 'Market price comparison prep',
                  ),
                  subtitle: Text(
                    isTr
                        ? 'Entegrasyon baglandiginda market secimini buradan yonetecegiz.'
                        : 'When integrations land, market selection will be managed here.',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: prefs.campaignAlertsEnabled,
                  onChanged: (value) {
                    provider.setCampaignAlertsEnabled(value);
                  },
                  title: Text(
                    isTr
                        ? 'Kampanya alarmi hazirligi'
                        : 'Campaign alert prep',
                  ),
                  subtitle: Text(
                    isTr
                        ? 'Kampanya takibi acildiginda hangi marketlerin izlenecegi kayitli kalir.'
                        : 'Preferred markets will already be saved once campaign tracking is connected.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _markets.map((market) {
                        final selected =
                            prefs.preferredMarkets.contains(market);
                        return FilterChip(
                          label: Text(market),
                          selected: selected,
                          onSelected: (_) {
                            provider.togglePreferredMarket(market);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(
            title: isTr ? 'Siradaki ogun plani' : 'Next meal plan',
            subtitle: isTr
                ? '${provider.getMealLabel(nextMealId)} icin oneriler ve aciklar'
                : 'Suggestions and gaps for ${provider.getMealLabel(nextMealId).toLowerCase()}',
          ),
          const SizedBox(height: 12),
          if (suggestions.isEmpty)
            _InfoCard(
              message: isTr
                  ? 'Tarif verisi yuklendikten sonra burada kisilesmis oneriler goreceksin.'
                  : 'Personalized suggestions will appear here once recipe data is loaded.',
            )
          else
            ...suggestions.map(
              (suggestion) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SuggestionCard(
                  suggestion: suggestion,
                  isTr: isTr,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          RecipeDetailScreen(recipe: suggestion.recipe),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          _SectionTitle(
            title: isTr ? 'Eksik alisveris listesi' : 'Missing shopping list',
            subtitle: isTr
                ? 'Siradaki ogun icin eksik kalanlar.'
                : 'Missing items for the next meal.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: shoppingList.isEmpty
                  ? Text(
                      isTr
                          ? 'Secili malzemelerinle en az bir oneriyi hemen yapabiliyorsun.'
                          : 'You can already cook at least one suggestion with your current ingredients.',
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: shoppingList
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.shopping_bag_outlined,
                                    size: 18,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(child: Text(item)),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(
            title: isTr ? 'Hatirlatma onizlemesi' : 'Reminder preview',
            subtitle: isTr
                ? 'Bildirim motorunu bu plana baglayacagiz.'
                : 'The notification engine will be connected to this plan.',
          ),
          const SizedBox(height: 12),
          if (reminderPreviews.isEmpty)
            _InfoCard(
              message: isTr
                  ? 'En az bir ogunu aktiflestir; bir sonraki hatirlatma burada gorunsun.'
                  : 'Enable at least one meal to see the next reminder.',
            )
          else
            ...reminderPreviews.map(
              (preview) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReminderCard(preview: preview, isTr: isTr),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _pickTime(
    BuildContext context, {
    required int initialMinutes,
    required ValueChanged<int> onSelected,
  }) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: initialMinutes ~/ 60,
        minute: initialMinutes % 60,
      ),
    );

    if (picked == null) return;
    onSelected(picked.hour * 60 + picked.minute);
  }
}

class _IntroCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _IntroCard({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            const Color(0xFFFF8C42),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 28),
          const SizedBox(height: 16),
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MealRoutineCard extends StatelessWidget {
  final MealRoutineSlot slot;
  final bool isTr;
  final ValueChanged<bool> onToggle;
  final VoidCallback onPickWeekday;
  final VoidCallback onPickWeekend;
  final ValueChanged<int> onLeadChanged;

  const _MealRoutineCard({
    required this.slot,
    required this.isTr,
    required this.onToggle,
    required this.onPickWeekday,
    required this.onPickWeekend,
    required this.onLeadChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final leadOptions = {
      ...SmartKitchenScreen._leadOptions,
      slot.leadMinutes,
    }.toList()
      ..sort();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconForMeal(slot.id), color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _mealLabel(slot.id, isTr),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Switch(
                  value: slot.enabled,
                  onChanged: onToggle,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _TimeButton(
                    label: isTr ? 'Hafta ici' : 'Weekdays',
                    timeText: _formatMinutes(context, slot.weekdayMinutes),
                    onTap: onPickWeekday,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimeButton(
                    label: isTr ? 'Hafta sonu' : 'Weekend',
                    timeText: _formatMinutes(context, slot.weekendMinutes),
                    onTap: onPickWeekend,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  isTr ? 'Hatirlatma once:' : 'Remind before:',
                  style: theme.textTheme.bodyMedium,
                ),
                const Spacer(),
                DropdownButton<int>(
                  value: slot.leadMinutes,
                  items: leadOptions
                      .map(
                        (minutes) => DropdownMenuItem(
                          value: minutes,
                          child: Text(
                            isTr ? '$minutes dk' : '$minutes min',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) onLeadChanged(value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconForMeal(String mealId) {
    switch (mealId) {
      case 'breakfast':
        return Icons.wb_sunny_outlined;
      case 'lunch':
        return Icons.lunch_dining_outlined;
      case 'dinner':
      default:
        return Icons.nightlight_round;
    }
  }

  String _mealLabel(String mealId, bool isTr) {
    switch (mealId) {
      case 'breakfast':
        return isTr ? 'Kahvalti' : 'Breakfast';
      case 'lunch':
        return isTr ? 'Oglen yemegi' : 'Lunch';
      case 'dinner':
      default:
        return isTr ? 'Aksam yemegi' : 'Dinner';
    }
  }

  String _formatMinutes(BuildContext context, int minutes) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      alwaysUse24HourFormat: true,
    );
  }
}

class _TimeButton extends StatelessWidget {
  final String label;
  final String timeText;
  final VoidCallback onTap;

  const _TimeButton({
    required this.label,
    required this.timeText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      child: Column(
        children: [
          Text(label),
          const SizedBox(height: 4),
          Text(
            timeText,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final PersonalizedRecipeSuggestion suggestion;
  final bool isTr;
  final VoidCallback onTap;

  const _SuggestionCard({
    required this.suggestion,
    required this.isTr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = suggestion.recipe;
    final locale = isTr ? 'tr' : 'en';

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(recipe.imageEmoji, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.getName(locale),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Badge(
                          icon: Icons.schedule,
                          label: '${recipe.totalTimeMinutes} ${isTr ? 'dk' : 'min'}',
                        ),
                        _Badge(
                          icon: suggestion.canCookNow
                              ? Icons.check_circle
                              : Icons.shopping_bag_outlined,
                          label: suggestion.canCookNow
                              ? (isTr ? 'Hazir' : 'Ready')
                              : (isTr
                                  ? '${suggestion.missingItems.length} eksik'
                                  : '${suggestion.missingItems.length} missing'),
                        ),
                        if (suggestion.matchPercent > 0)
                          _Badge(
                            icon: Icons.kitchen_outlined,
                            label: '%${suggestion.matchPercent}',
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Badge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ReminderCard extends StatelessWidget {
  final ReminderPreview preview;
  final bool isTr;

  const _ReminderCard({
    required this.preview,
    required this.isTr,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final reminderText = localizations.formatTimeOfDay(
      TimeOfDay(
        hour: preview.remindAt.hour,
        minute: preview.remindAt.minute,
      ),
      alwaysUse24HourFormat: true,
    );
    final mealText = localizations.formatTimeOfDay(
      TimeOfDay(
        hour: preview.mealAt.hour,
        minute: preview.mealAt.minute,
      ),
      alwaysUse24HourFormat: true,
    );

    return Card(
      child: ListTile(
        leading: const Icon(Icons.notifications_active_outlined),
        title: Text(
          isTr
              ? '${_mealLabel(preview.mealId)} icin $reminderText'
              : '$reminderText for ${_mealLabel(preview.mealId)}',
        ),
        subtitle: Text(
          isTr
              ? '$mealText yemeginden ${preview.leadMinutes} dk once'
              : '${preview.leadMinutes} min before the $mealText meal',
        ),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
      ),
    );
  }

  String _mealLabel(String mealId) {
    switch (mealId) {
      case 'breakfast':
        return isTr ? 'kahvalti' : 'breakfast';
      case 'lunch':
        return isTr ? 'ogle yemegi' : 'lunch';
      case 'dinner':
      default:
        return isTr ? 'aksam yemegi' : 'dinner';
    }
  }
}

class _InfoCard extends StatelessWidget {
  final String message;

  const _InfoCard({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
