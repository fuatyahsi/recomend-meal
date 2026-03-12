import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';
import 'cooking_mode_screen.dart';

class RecipeDetailScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  static Widget _buildCategoryBadge(String category, String locale, ThemeData theme) {
    const categoryMap = {
      'breakfast': {'emoji': '🍳', 'tr': 'Kahvaltı', 'en': 'Breakfast', 'color': 0xFFFFF3E0},
      'soup':      {'emoji': '🥣', 'tr': 'Çorba', 'en': 'Soup', 'color': 0xFFE8F5E9},
      'main':      {'emoji': '🍖', 'tr': 'Ana Yemek', 'en': 'Main Dish', 'color': 0xFFFFEBEE},
      'appetizer': {'emoji': '🥟', 'tr': 'Meze', 'en': 'Appetizer', 'color': 0xFFE3F2FD},
      'salad':     {'emoji': '🥗', 'tr': 'Salata', 'en': 'Salad', 'color': 0xFFE8F5E9},
      'dessert':   {'emoji': '🍰', 'tr': 'Tatlı', 'en': 'Dessert', 'color': 0xFFFCE4EC},
      'beverage':  {'emoji': '🥤', 'tr': 'İçecek', 'en': 'Beverage', 'color': 0xFFE0F7FA},
      'side':      {'emoji': '🍚', 'tr': 'Garnitür', 'en': 'Side', 'color': 0xFFFFF8E1},
    };
    final cat = categoryMap[category] ?? {'emoji': '🍽️', 'tr': category, 'en': category, 'color': 0xFFEEEEEE};
    final isTr = locale == 'tr';
    return Chip(
      avatar: Text(cat['emoji'] as String, style: const TextStyle(fontSize: 16)),
      label: Text(
        isTr ? cat['tr'] as String : cat['en'] as String,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Color(cat['color'] as int),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = provider.languageCode;

    final steps = recipe.getSteps(locale);
    final isFavorite = provider.isFavorite(recipe.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with emoji hero
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.getName(locale),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primaryContainer,
                      theme.colorScheme.primary.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    recipe.imageEmoji,
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: () => provider.toggleFavorite(recipe.id),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category badge & tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildCategoryBadge(recipe.category, locale, theme),
                      ...recipe.tags.take(3).map((tag) => Chip(
                            label: Text(tag, style: const TextStyle(fontSize: 11)),
                            visualDensity: VisualDensity.compact,
                            side: BorderSide.none,
                            backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          )),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Description
                  Text(
                    recipe.getDescription(locale),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Total time highlight
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.schedule, color: Colors.deepOrange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          locale == 'tr'
                              ? 'Toplam Süre: ${recipe.totalTimeMinutes} dakika'
                              : 'Total Time: ${recipe.totalTimeMinutes} minutes',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.deepOrange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Info Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _InfoChip(
                        icon: Icons.timer_outlined,
                        label: l10n.prepTime,
                        value: '${recipe.prepTimeMinutes} ${l10n.minutes}',
                      ),
                      _InfoChip(
                        icon: Icons.local_fire_department_outlined,
                        label: l10n.cookTime,
                        value: '${recipe.cookTimeMinutes} ${l10n.minutes}',
                      ),
                      _InfoChip(
                        icon: Icons.people_outline,
                        label: l10n.servings,
                        value: '${recipe.servings}',
                      ),
                      _InfoChip(
                        icon: Icons.signal_cellular_alt,
                        label: l10n.difficulty,
                        value: recipe.getDifficultyText(locale),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // Ingredients Section
                  Text(
                    l10n.ingredients,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...recipe.ingredients.map((ing) {
                    final ingredientData =
                        provider.recipeService.getIngredientById(ing.ingredientId);
                    final hasIngredient =
                        provider.isIngredientSelected(ing.ingredientId);
                    final name = ingredientData?.getName(locale) ??
                        ing.ingredientId;
                    final icon = ingredientData?.icon ?? '🥘';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: hasIngredient
                            ? Colors.green.shade50
                            : ing.isOptional
                                ? theme.colorScheme.surfaceContainerHighest
                                : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: hasIngredient
                              ? Colors.green.shade200
                              : ing.isOptional
                                  ? Colors.grey.shade300
                                  : Colors.red.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(icon, style: const TextStyle(fontSize: 22)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  ing.getAmount(locale),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (ing.isOptional)
                            Chip(
                              label: Text(
                                l10n.optional,
                                style: const TextStyle(fontSize: 10),
                              ),
                              padding: EdgeInsets.zero,
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              side: BorderSide.none,
                              backgroundColor: Colors.grey.shade200,
                            )
                          else if (hasIngredient)
                            Text(
                              l10n.youHaveThis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          else
                            Text(
                              l10n.youNeedThis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 28),

                  // Steps Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.preparation,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          final ingredientNames = recipe.ingredients.map((ing) {
                            final data = provider.recipeService.getIngredientById(ing.ingredientId);
                            final name = data?.getName(locale) ?? ing.ingredientId;
                            return '${ing.getAmount(locale)} $name';
                          }).toList();

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CookingModeScreen(
                                recipeName: recipe.getName(locale),
                                emoji: recipe.imageEmoji,
                                steps: steps.map((s) => s.instruction).toList(),
                                ingredients: ingredientNames,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.restaurant, size: 18),
                        label: Text(
                          locale == 'tr' ? 'Pişirme Modu' : 'Cooking Mode',
                          style: const TextStyle(fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  ...steps.map((step) => _StepCard(
                        step: step,
                        locale: locale,
                        l10n: l10n,
                      )),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  final RecipeStep step;
  final String locale;
  final AppLocalizations l10n;

  const _StepCard({
    required this.step,
    required this.locale,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '${step.stepNumber}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.instruction,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
                if (step.durationMinutes != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '~${step.durationMinutes} ${l10n.minutes}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
