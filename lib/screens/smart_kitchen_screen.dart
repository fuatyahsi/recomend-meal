import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/smart_kitchen.dart';
import '../providers/app_provider.dart';
import '../services/notification_service.dart';
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
    final plannedShoppingSummary = provider.getPlannedShoppingSummary();
    final hasAnyPlannedMeal = prefs.mealSlots.any(
      (slot) => slot.enabled && provider.getPlannedRecipe(slot.id) != null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTr ? 'Akıllı Mutfak Asistanı' : 'Smart Kitchen Assistant',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _IntroCard(
            title: isTr
                ? 'Öğünlerini planla, eksikleri önceden gör'
                : 'Plan meals and spot gaps ahead of time',
            subtitle: isTr
                ? 'Önce hangi öğünde ne pişireceğini seç. Sonra uygulama eksik malzemeleri, alışveriş notlarını ve hatırlatmaları senin için toparlasın.'
                : 'Choose what you want to cook for each meal first. Then let the app organize missing ingredients, shopping notes, and reminders for you.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await NotificationService.instance.requestPermissions();
              await provider.syncSmartKitchenNotifications();
            },
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(
              isTr ? 'Bildirimleri Etkinleştir' : 'Enable Notifications',
            ),
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: isTr ? 'Öğün rutinleri' : 'Meal routines',
            subtitle: isTr
                ? 'Hafta içi ve hafta sonu saatlerini ayarla.'
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
            title: isTr ? 'Öğün planı' : 'Meal plan',
            subtitle: isTr
                ? 'Önce tarifini seç, sonra alışveriş açığını çıkaralım.'
                : 'Pick the recipe first, then let us prepare the shopping gap.',
          ),
          const SizedBox(height: 12),
          ...prefs.mealSlots.where((slot) => slot.enabled).map(
            (slot) {
              final plannedRecipe = provider.getPlannedRecipe(slot.id);
              final missingCount =
                  provider.getShoppingItemsForMeal(slot.id).length;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MealPlanCard(
                  isTr: isTr,
                  mealLabel: _mealLabelText(slot.id, isTr),
                  recipeName: plannedRecipe?.getName(isTr ? 'tr' : 'en'),
                  missingCount: missingCount,
                  onPick: () => _showMealPicker(
                    context,
                    provider: provider,
                    mealId: slot.id,
                    isTr: isTr,
                  ),
                  onClear: plannedRecipe == null
                      ? null
                      : () {
                          provider.clearPlannedRecipeForMeal(slot.id);
                        },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _SectionTitle(
            title: isTr ? 'Asistan tercihleri' : 'Assistant preferences',
            subtitle: isTr
                ? 'Bildirim ve kişiselleştirme davranışını hazırla.'
                : 'Prepare notification and personalization behavior.',
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
                        ? 'Öğünden önce öneriler hazır olsun'
                        : 'Prepare suggestions before meals',
                  ),
                  subtitle: Text(
                    isTr
                        ? 'Sıradaki öğün için seçenekler ve eksik malzemeler önceden görünsün.'
                        : 'Surface meal options and missing ingredients ahead of time.',
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
                        ? 'Erken saatli öğünleri hatırlat'
                        : 'Remind early-hour meals',
                  ),
                  subtitle: Text(
                    isTr
                        ? 'Erken planlanan öğünleri zamanı gelmeden hatırlat.'
                        : 'Remind meals planned for earlier hours before they start.',
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
                        ? 'Market fiyat karşılaştırma hazırlığı'
                        : 'Market price comparison prep',
                  ),
                  subtitle: Text(
                    isTr
                        ? 'Entegrasyon bağlandığında market seçimini buradan yöneteceğiz.'
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
                    isTr ? 'Kampanya alarmı hazırlığı' : 'Campaign alert prep',
                  ),
                  subtitle: Text(
                    isTr
                        ? 'Kampanya takibi açıldığında hangi marketlerin izleneceği kayıtlı kalır.'
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
            title: isTr ? 'Planlamak için öneriler' : 'Suggestions for planning',
            subtitle: isTr
                ? '${provider.getPlannerMealLabel(nextMealId)} için öneriler'
                : 'Suggestions for ${provider.getPlannerMealLabel(nextMealId).toLowerCase()}',
          ),
          const SizedBox(height: 12),
          if (suggestions.isEmpty)
            _InfoCard(
              message: isTr
                  ? 'Tarif verisi yüklendikten sonra burada kişiselleşmiş öneriler göreceksin.'
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
            title: isTr
                ? 'Planlanan öğünler için eksik alışveriş listesi'
                : 'Missing shopping list for planned meals',
            subtitle: isTr
                ? 'Seçtiğin tariflere göre eksik kalanları burada topluyoruz.'
                : 'We gather missing items here based on your selected recipes.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: !hasAnyPlannedMeal
                  ? Text(
                      isTr
                          ? 'Önce bir öğün için tarif seç. Alışveriş listesi seçtiğin planlara göre oluşacak.'
                          : 'Pick a recipe for at least one meal first. The shopping list will be built from your plan.',
                    )
                  : plannedShoppingSummary.isEmpty
                      ? Text(
                          isTr
                              ? 'Planladığın öğünler için seçili malzemelerin yeterli görünüyor.'
                              : 'Your current ingredients look enough for the meals you planned.',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: plannedShoppingSummary
                              .map(
                                (item) => Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 8),
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
            title: isTr ? 'Hatırlatma önizlemesi' : 'Reminder preview',
            subtitle: isTr
                ? 'Bildirim motoru bu plana göre çalışacak.'
                : 'The notification engine will follow this plan.',
          ),
          const SizedBox(height: 12),
          if (reminderPreviews.isEmpty)
            _InfoCard(
              message: isTr
                  ? 'En az bir öğünü aktifleştir; bir sonraki hatırlatma burada görünsün.'
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

  Future<void> _showMealPicker(
    BuildContext context, {
    required AppProvider provider,
    required String mealId,
    required bool isTr,
  }) async {
    final locale = isTr ? 'tr' : 'en';
    final candidates = provider.getMealPlanCandidates(mealId, limit: 8);
    final selectedIds = provider.selectedIngredientIds.toList();
    final selectedRecipeId = provider.getPlannedRecipe(mealId)?.id;
    final mealLabel = _mealLabelText(mealId, isTr);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTr
                      ? '$mealLabel için tarif seç'
                      : 'Choose a recipe for $mealLabel',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  isTr
                      ? 'Seçtiğin tarif bu öğünün alışveriş eksiğini belirleyecek.'
                      : 'The recipe you choose will define the shopping gap for this meal.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                if (candidates.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      isTr
                          ? 'Şu anda öneri hazırlayamadım. Malzeme seçimini güncelleyip tekrar dene.'
                          : 'No suggestions are ready right now. Update your ingredients and try again.',
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: candidates.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final recipe = candidates[index];
                        final missingCount = recipe
                            .getMissingIngredients(selectedIds)
                            .length;
                        final isSelected = recipe.id == selectedRecipeId;

                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Text(
                            recipe.imageEmoji,
                            style: const TextStyle(fontSize: 28),
                          ),
                          title: Text(recipe.getName(locale)),
                          subtitle: Text(
                            isTr
                                ? '${recipe.totalTimeMinutes} dk • $missingCount eksik'
                                : '${recipe.totalTimeMinutes} min • $missingCount missing',
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () async {
                            await provider.setPlannedRecipeForMeal(
                              mealId,
                              recipe.id,
                            );
                            if (!bottomSheetContext.mounted) return;
                            Navigator.pop(bottomSheetContext);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
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
                Icon(_mealIcon(slot.id), color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _mealLabelText(slot.id, isTr),
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
                    label: isTr ? 'Hafta içi' : 'Weekdays',
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
                  isTr ? 'Hatırlatma süresi:' : 'Remind before:',
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

  String _formatMinutes(BuildContext context, int minutes) {
    final localizations = MaterialLocalizations.of(context);
    return localizations.formatTimeOfDay(
      TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      alwaysUse24HourFormat: true,
    );
  }
}

class _MealPlanCard extends StatelessWidget {
  final bool isTr;
  final String mealLabel;
  final String? recipeName;
  final int missingCount;
  final VoidCallback onPick;
  final VoidCallback? onClear;

  const _MealPlanCard({
    required this.isTr,
    required this.mealLabel,
    required this.recipeName,
    required this.missingCount,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant_menu, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    mealLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (onClear != null)
                  IconButton(
                    onPressed: onClear,
                    tooltip: isTr ? 'Planı temizle' : 'Clear plan',
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              recipeName == null
                  ? (isTr
                      ? 'Bu öğün için önce bir tarif seç.'
                      : 'Pick a recipe for this meal first.')
                  : recipeName!,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight:
                    recipeName == null ? FontWeight.w500 : FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              recipeName == null
                  ? (isTr
                      ? 'Seçtiğin tarif eksik malzemeleri ve alışveriş listesini belirler.'
                      : 'The recipe you choose determines the missing ingredients and shopping list.')
                  : missingCount == 0
                      ? (isTr
                          ? 'Seçili malzemelerin bu plan için yeterli görünüyor.'
                          : 'Your current ingredients look enough for this plan.')
                      : (isTr
                          ? '$missingCount eksik malzeme var.'
                          : '$missingCount missing ingredients.'),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: onPick,
              icon: const Icon(Icons.edit_outlined),
              label: Text(
                recipeName == null
                    ? (isTr ? 'Tarif seç' : 'Choose recipe')
                    : (isTr ? 'Tarifi değiştir' : 'Change recipe'),
              ),
            ),
          ],
        ),
      ),
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
                  child: Text(
                    recipe.imageEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
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
                          label:
                              '${recipe.totalTimeMinutes} ${isTr ? 'dk' : 'min'}',
                        ),
                        _Badge(
                          icon: suggestion.canCookNow
                              ? Icons.check_circle
                              : Icons.shopping_bag_outlined,
                          label: suggestion.canCookNow
                              ? (isTr ? 'Hazır' : 'Ready')
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
              ? '${_mealLabelText(preview.mealId, true)} için $reminderText'
              : '$reminderText for ${_mealLabelText(preview.mealId, false)}',
        ),
        subtitle: Text(
          isTr
              ? '$mealText öğününden ${preview.leadMinutes} dk önce'
              : '${preview.leadMinutes} min before the $mealText meal',
        ),
        trailing: Icon(Icons.chevron_right, color: theme.colorScheme.outline),
      ),
    );
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

String _mealLabelText(String mealId, bool isTr) {
  switch (mealId) {
    case 'breakfast':
      return isTr ? 'Kahvaltı' : 'Breakfast';
    case 'lunch':
      return isTr ? 'Öğle yemeği' : 'Lunch';
    case 'dinner':
    default:
      return isTr ? 'Akşam yemeği' : 'Dinner';
  }
}

IconData _mealIcon(String mealId) {
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
