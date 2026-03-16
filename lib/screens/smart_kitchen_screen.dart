import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../models/smart_kitchen.dart';
import '../providers/app_provider.dart';
import '../services/notification_service.dart';
import 'ingredient_selection_screen.dart';
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
    final reminderPreviews = provider.getUpcomingReminderPreviews(limit: 3);
    final plannedShoppingSummary = provider.getPlannedShoppingSummary();
    final pantryCount = provider.selectedCount;
    final pantryItems = provider.pantryItems;
    final featuredMealId = provider.getNextPlannedMealId();
    final featuredMealLabel = provider.getPlannerMealLabel(featuredMealId);
    final featuredSuggestions = provider.getMenuSuggestionsForMeal(
      featuredMealId,
      limit: 4,
    );
    final hasAnyPlannedMeal = prefs.mealSlots.any(
      (slot) => provider.getPlannedRecipes(slot.id).isNotEmpty,
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
                ? 'Önce menünü kur, sonra zamanını ayarla'
                : 'Build your menus first, then set your timing',
            subtitle: isTr
                ? 'Kahvaltı, öğle ve akşam için menünü oluştur. Uygulama dolabındaki malzemelere göre öneri sunsun, eksikleri çıkarsın ve alışveriş listesini hazırlasın.'
                : 'Create menus for breakfast, lunch, and dinner. Let the app suggest options from your pantry, find the gaps, and prepare the shopping list.',
          ),
          const SizedBox(height: 16),
          _SuggestionSpotlightCard(
            isTr: isTr,
            mealLabel: featuredMealLabel,
            suggestions: featuredSuggestions,
            onPreviewRecipe: (recipe) => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RecipeDetailScreen(recipe: recipe),
              ),
            ),
            onAddSuggestion: (recipeId) {
              provider.setPlannedRecipeForMeal(featuredMealId, recipeId);
            },
          ),
          const SizedBox(height: 16),
          _SectionTitle(
            title: isTr ? '1. Menü planı' : '1. Meal plan',
            subtitle: isTr
                ? 'Her öğün için birden fazla tarif seçebilirsin.'
                : 'You can choose multiple recipes for each meal.',
          ),
          const SizedBox(height: 12),
          ...prefs.mealSlots.map(
            (slot) {
              final plannedRecipes = provider.getPlannedRecipes(slot.id);
              final suggestions = provider.getMenuSuggestionsForMeal(
                slot.id,
                limit: 3,
              );
              final missingCount = provider
                  .getShoppingItemsForMeal(slot.id)
                  .fold<int>(
                    0,
                    (sum, item) => sum + item.missingCount,
                  );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _MealPlanCard(
                  isTr: isTr,
                  mealLabel: _mealLabel(slot.id, isTr),
                  plannedRecipes: plannedRecipes,
                  suggestedRecipes: suggestions,
                  missingCount: missingCount,
                  onManageMenu: () => _showMealPicker(
                    context,
                    provider: provider,
                    mealId: slot.id,
                    isTr: isTr,
                  ),
                  onRemoveRecipe: (recipeId) {
                    provider.removePlannedRecipeForMeal(slot.id, recipeId);
                  },
                  onPreviewRecipe: (recipe) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => RecipeDetailScreen(recipe: recipe),
                    ),
                  ),
                  onAddSuggestion: (recipeId) {
                    provider.setPlannedRecipeForMeal(slot.id, recipeId);
                  },
                  onConsumeMenu: () {
                    provider.consumePlannedRecipesForMeal(slot.id);
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          _SectionTitle(
            title: isTr ? '2. Dolap durumu' : '2. Pantry status',
            subtitle: isTr
                ? 'Alışveriş listesi için dolabındaki malzemeleri güncel tut.'
                : 'Keep your pantry current so shopping lists stay accurate.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.kitchen_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          isTr
                              ? '$pantryCount malzeme dolapta işaretli'
                              : '$pantryCount ingredients marked in pantry',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTr
                        ? 'Menülerdeki eksikler seçtiğin dolap durumuna göre hesaplanır.'
                        : 'Missing items are calculated from the ingredients you marked as available.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (pantryItems.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: pantryItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = pantryItems[index];
                          return _PantryPreviewTile(
                            item: item,
                            locale: provider.languageCode,
                            onIncrement: () =>
                                provider.incrementIngredient(item.ingredient.id),
                            onDecrement: () =>
                                provider.decrementIngredient(item.ingredient.id),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    Text(
                      isTr
                          ? 'Henüz dolap listesi yok. Önce mevcut malzemelerini ekle.'
                          : 'Your pantry list is empty. Add what you already have first.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const IngredientSelectionScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: Text(
                      isTr
                          ? 'Dolaptaki malzemeleri güncelle'
                          : 'Update pantry ingredients',
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          _SectionTitle(
            title: isTr
                ? '3. Eksik malzemeler ve alışveriş listesi'
                : '3. Missing ingredients and shopping list',
            subtitle: isTr
                ? 'Seçtiğin menülere ve dolap durumuna göre hazırlanır.'
                : 'Built from your selected menus and pantry status.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: !hasAnyPlannedMeal
                  ? Text(
                      isTr
                          ? 'Önce en az bir öğün için menü oluştur. Alışveriş listesi seçtiğin menülere göre oluşacak.'
                          : 'Build at least one meal menu first. The shopping list will be generated from your selected menus.',
                    )
                  : plannedShoppingSummary.isEmpty
                      ? Text(
                          isTr
                              ? 'Planladığın menüler için dolaptaki malzemeler yeterli görünüyor.'
                              : 'Your pantry looks enough for the menus you planned.',
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: plannedShoppingSummary
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
          const SizedBox(height: 8),
          _SectionTitle(
            title: isTr ? '4. Öğün rutinleri' : '4. Meal routines',
            subtitle: isTr
                ? 'Menünü kurduktan sonra saatleri ayarla.'
                : 'Set your times after building your menus.',
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
            title: isTr ? '5. Hatırlatmalar' : '5. Reminders',
            subtitle: isTr
                ? 'Öğün yaklaşırken bildirim hazırlayalım.'
                : 'Prepare notifications before each meal.',
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () async {
              await NotificationService.instance.requestPermissions();
              await provider.syncSmartKitchenNotifications();
            },
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(
              isTr ? 'Bildirimleri etkinleştir' : 'Enable notifications',
            ),
          ),
          const SizedBox(height: 12),
          if (reminderPreviews.isEmpty)
            _InfoCard(
              message: isTr
                  ? 'En az bir öğünü etkinleştir; hatırlatma önizlemesi burada görünsün.'
                  : 'Enable at least one meal to see the reminder preview here.',
            )
          else
            ...reminderPreviews.map(
              (preview) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ReminderCard(preview: preview, isTr: isTr),
              ),
            ),
          const SizedBox(height: 8),
          _SectionTitle(
            title: isTr ? 'Asistan tercihleri' : 'Assistant preferences',
            subtitle: isTr
                ? 'Genel davranışı burada tut.'
                : 'Keep the overall assistant behavior here.',
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: prefs.eveningDriveHomeSuggestions,
                  onChanged: provider.setEveningDriveHomeSuggestions,
                  title: Text(
                    isTr
                        ? 'Öğünden önce öneriler hazır olsun'
                        : 'Prepare suggestions before meals',
                  ),
                  subtitle: Text(
                    isTr
                        ? 'Sıradaki öğün için menü önerileri önceden gelsin.'
                        : 'Show menu suggestions ahead of the next meal.',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: prefs.schoolBreakfastNudges,
                  onChanged: provider.setSchoolBreakfastNudges,
                  title: Text(
                    isTr
                        ? 'Erken saatli öğünleri hatırlat'
                        : 'Remind early-hour meals',
                  ),
                  subtitle: Text(
                    isTr
                        ? 'Erken saatlerdeki öğünleri önceden hatırlat.'
                        : 'Send reminders before earlier meals.',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: prefs.priceComparisonEnabled,
                  onChanged: provider.setPriceComparisonEnabled,
                  title: Text(
                    isTr
                        ? 'Market fiyat karşılaştırma hazırlığı'
                        : 'Market price comparison prep',
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: prefs.campaignAlertsEnabled,
                  onChanged: provider.setCampaignAlertsEnabled,
                  title: Text(
                    isTr ? 'Kampanya alarmı hazırlığı' : 'Campaign alert prep',
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
    final candidates = provider.getMealPlanCandidates(mealId, limit: 24);
    final selectedRecipeIds =
        provider.getPlannedRecipes(mealId).map((recipe) => recipe.id).toSet();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (bottomSheetContext) {
        final workingSelection = {...selectedRecipeIds};
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTr
                          ? '${_mealLabel(mealId, true)} menüsünü seç'
                          : 'Select the ${_mealLabel(mealId, false)} menu',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isTr
                          ? 'Birden fazla tarif seçebilirsin. Seçtiklerin alışveriş listesine birlikte yansır.'
                          : 'You can select multiple recipes. Everything you pick will feed the shopping list together.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 420,
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: candidates.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final recipe = candidates[index];
                          final isSelected =
                              workingSelection.contains(recipe.id);
                          final missingCount = recipe
                              .getMissingIngredients(
                                provider.selectedIngredientIds.toList(),
                              )
                              .length;
                          return CheckboxListTile(
                            value: isSelected,
                            controlAffinity: ListTileControlAffinity.trailing,
                            contentPadding: EdgeInsets.zero,
                            secondary: Text(
                              recipe.imageEmoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                            title: Text(recipe.getName(locale)),
                            subtitle: Text(
                              isTr
                                  ? '${recipe.totalTimeMinutes} dk • $missingCount eksik'
                                  : '${recipe.totalTimeMinutes} min • $missingCount missing',
                            ),
                            onChanged: (value) {
                              setModalState(() {
                                if (value == true) {
                                  workingSelection.add(recipe.id);
                                } else {
                                  workingSelection.remove(recipe.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () async {
                          await provider.replacePlannedRecipesForMeal(
                            mealId,
                            workingSelection.toList(),
                          );
                          if (!bottomSheetContext.mounted) return;
                          Navigator.pop(bottomSheetContext);
                        },
                        child: Text(
                          isTr ? 'Menüyü kaydet' : 'Save menu',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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

class _SuggestionSpotlightCard extends StatelessWidget {
  final bool isTr;
  final String mealLabel;
  final List<PersonalizedRecipeSuggestion> suggestions;
  final ValueChanged<Recipe> onPreviewRecipe;
  final ValueChanged<String> onAddSuggestion;

  const _SuggestionSpotlightCard({
    required this.isTr,
    required this.mealLabel,
    required this.suggestions,
    required this.onPreviewRecipe,
    required this.onAddSuggestion,
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
                Icon(Icons.auto_awesome, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isTr
                        ? '$mealLabel için menü öner'
                        : 'Menu ideas for $mealLabel',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isTr
                  ? 'Önce menüyü seçmeye başla. Eklediklerin alışveriş listesine otomatik yansısın.'
                  : 'Start building the menu first. Added recipes will feed the shopping list automatically.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (suggestions.isEmpty)
              Text(
                isTr
                    ? 'Bu öğün için yeni öneri hazırlanamadı.'
                    : 'No menu suggestion is ready for this meal yet.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...suggestions.map((suggestion) {
                final recipe = suggestion.recipe;
                final missingUnits = suggestion.missingItems.fold<int>(
                  0,
                  (sum, item) => sum + item.missingCount,
                );
                final statusText = suggestion.canCookNow
                    ? (isTr ? 'Dolapta hazır' : 'Ready from pantry')
                    : (isTr
                        ? '$missingUnits birim eksik'
                        : '$missingUnits units missing');

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Text(
                    recipe.imageEmoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                  title: Text(recipe.getName(isTr ? 'tr' : 'en')),
                  subtitle: Text(
                    isTr
                        ? '${recipe.totalTimeMinutes} dk • $statusText'
                        : '${recipe.totalTimeMinutes} min • $statusText',
                  ),
                  trailing: IconButton(
                    onPressed: () => onAddSuggestion(recipe.id),
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                  onTap: () => onPreviewRecipe(recipe),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _MealPlanCard extends StatelessWidget {
  final bool isTr;
  final String mealLabel;
  final List<Recipe> plannedRecipes;
  final List<PersonalizedRecipeSuggestion> suggestedRecipes;
  final int missingCount;
  final VoidCallback onManageMenu;
  final VoidCallback onConsumeMenu;
  final ValueChanged<String> onRemoveRecipe;
  final ValueChanged<Recipe> onPreviewRecipe;
  final ValueChanged<String> onAddSuggestion;

  const _MealPlanCard({
    required this.isTr,
    required this.mealLabel,
    required this.plannedRecipes,
    required this.suggestedRecipes,
    required this.missingCount,
    required this.onManageMenu,
    required this.onConsumeMenu,
    required this.onRemoveRecipe,
    required this.onPreviewRecipe,
    required this.onAddSuggestion,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = isTr ? 'tr' : 'en';

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
                FilledButton.tonalIcon(
                  onPressed: onManageMenu,
                  icon: const Icon(Icons.edit_outlined),
                  label: Text(isTr ? 'Menüyü düzenle' : 'Edit menu'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              plannedRecipes.isEmpty
                  ? (isTr
                      ? 'Bu öğün için önce menü oluştur.'
                      : 'Create a menu for this meal first.')
                  : (isTr
                      ? '${plannedRecipes.length} tarif seçili'
                      : '${plannedRecipes.length} recipes selected'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (plannedRecipes.isEmpty)
              Text(
                isTr
                    ? 'Menü seçimi sonrası eksik malzemeler otomatik çıkarılır.'
                    : 'Missing ingredients will be calculated after menu selection.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: plannedRecipes.map((recipe) {
                  return InputChip(
                    avatar: Text(recipe.imageEmoji),
                    label: Text(recipe.getName(locale)),
                    onPressed: () => onPreviewRecipe(recipe),
                    onDeleted: () => onRemoveRecipe(recipe.id),
                  );
                }).toList(),
              ),
            const SizedBox(height: 12),
            _InfoBadge(
              icon: Icons.shopping_bag_outlined,
              label: isTr
                  ? '$missingCount stok birimi eksik'
                  : '$missingCount stock units missing',
            ),
            if (plannedRecipes.isNotEmpty) ...[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: onConsumeMenu,
                icon: const Icon(Icons.inventory_2_outlined),
                label: Text(
                  isTr
                      ? 'Bu menüyü pişirdim, dolaptan düş'
                      : 'Cooked this menu, deduct from pantry',
                ),
              ),
            ],
            const SizedBox(height: 14),
            Text(
              isTr ? 'Önerilen menü parçaları' : 'Suggested menu ideas',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (suggestedRecipes.isEmpty)
              Text(
                isTr
                    ? 'Bu öğün için yeni öneri hazırlanamadı.'
                    : 'No additional suggestions are ready for this meal.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              Column(
                children: suggestedRecipes.map((suggestion) {
                  final recipe = suggestion.recipe;
                  final missingUnits = suggestion.missingItems.fold<int>(
                    0,
                    (sum, item) => sum + item.missingCount,
                  );
                  final statusLabel = suggestion.canCookNow
                      ? (isTr ? 'Dolapta hazır' : 'Ready from pantry')
                      : (isTr
                          ? '$missingUnits birim eksik'
                          : '$missingUnits units missing');

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Text(
                      recipe.imageEmoji,
                      style: const TextStyle(fontSize: 26),
                    ),
                    title: Text(recipe.getName(locale)),
                    subtitle: Text(
                      isTr
                          ? '${recipe.totalTimeMinutes} dk • $statusLabel'
                          : '${recipe.totalTimeMinutes} min • $statusLabel',
                    ),
                    trailing: IconButton(
                      onPressed: () => onAddSuggestion(recipe.id),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                    onTap: () => onPreviewRecipe(recipe),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

class _PantryPreviewTile extends StatelessWidget {
  final PantryStockItem item;
  final String locale;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _PantryPreviewTile({
    required this.item,
    required this.locale,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Text(item.ingredient.icon, style: const TextStyle(fontSize: 24)),
      title: Text(item.ingredient.getName(locale)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove_circle_outline),
            color: theme.colorScheme.primary,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 34),
            alignment: Alignment.center,
            child: Text(
              '${item.count}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add_circle_outline),
            color: theme.colorScheme.primary,
          ),
        ],
      ),
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
                          child: Text(isTr ? '$minutes dk' : '$minutes min'),
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
              ? '${_mealLabel(preview.mealId, true)} için $reminderText'
              : '$reminderText for ${_mealLabel(preview.mealId, false)}',
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

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoBadge({
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

String _mealLabel(String mealId, bool isTr) {
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
