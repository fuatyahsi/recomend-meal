import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../l10n/app_localizations.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
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
    final isTr = locale == 'tr';

    final steps = recipe.getSteps(locale);
    final isFavorite = provider.isFavorite(recipe.id);
    final gradientColors = AppTheme.categoryGradients[recipe.category] ??
        [const Color(0xFFF5F5F5), const Color(0xFFE0E0E0)];

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Enhanced App Bar with glassmorphism
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.getName(locale),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  shadows: [
                    Shadow(blurRadius: 12, color: Colors.black54),
                    Shadow(blurRadius: 24, color: Colors.black26),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          gradientColors[0],
                          gradientColors[1],
                          theme.colorScheme.primary.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                  // Background pattern
                  Positioned(
                    right: -30,
                    bottom: -20,
                    child: Text(
                      recipe.imageEmoji,
                      style: TextStyle(
                        fontSize: 140,
                        color: Colors.black.withOpacity(0.04),
                      ),
                    ),
                  ),
                  // Main emoji
                  Center(
                    child: Hero(
                      tag: 'recipe_${recipe.id}',
                      child: Text(
                        recipe.imageEmoji,
                        style: const TextStyle(fontSize: 80),
                      ),
                    ),
                  ),
                  // Bottom gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? Colors.redAccent : Colors.white,
                  ),
                  onPressed: () => provider.toggleFavorite(recipe.id),
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AnimationLimiter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: AnimationConfiguration.toStaggeredList(
                    duration: const Duration(milliseconds: 375),
                    childAnimationBuilder: (widget) => SlideAnimation(
                      verticalOffset: 30.0,
                      child: FadeInAnimation(child: widget),
                    ),
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

                      const SizedBox(height: 14),

                      // Description
                      Text(
                        recipe.getDescription(locale),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.5,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Enhanced info cards row
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.softShadow,
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _InfoChip(
                              icon: Icons.timer_outlined,
                              label: l10n.prepTime,
                              value: '${recipe.prepTimeMinutes}\'',
                              color: Colors.blue,
                            ),
                            _divider(theme),
                            _InfoChip(
                              icon: Icons.local_fire_department_outlined,
                              label: l10n.cookTime,
                              value: '${recipe.cookTimeMinutes}\'',
                              color: Colors.deepOrange,
                            ),
                            _divider(theme),
                            _InfoChip(
                              icon: Icons.people_outline,
                              label: l10n.servings,
                              value: '${recipe.servings}',
                              color: Colors.teal,
                            ),
                            _divider(theme),
                            _InfoChip(
                              icon: Icons.signal_cellular_alt,
                              label: l10n.difficulty,
                              value: recipe.getDifficultyText(locale),
                              color: _getDifficultyColor(recipe.difficulty),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Total time highlight
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.orange.shade50,
                              Colors.orange.shade50.withOpacity(0.5),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.schedule,
                                  color: Colors.deepOrange.shade700, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isTr
                                  ? 'Toplam Süre: ${recipe.totalTimeMinutes} dakika'
                                  : 'Total Time: ${recipe.totalTimeMinutes} minutes',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Colors.deepOrange.shade700,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Ingredients Section
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            l10n.ingredients,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

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
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: hasIngredient
                                ? Colors.green.shade50
                                : ing.isOptional
                                    ? theme.colorScheme.surfaceContainerHighest
                                        .withOpacity(0.5)
                                    : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: hasIngredient
                                  ? Colors.green.shade200
                                  : ing.isOptional
                                      ? theme.colorScheme.outlineVariant
                                          .withOpacity(0.3)
                                      : Colors.red.shade200,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: hasIngredient
                                      ? Colors.green.shade100
                                      : ing.isOptional
                                          ? Colors.grey.shade100
                                          : Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text(icon,
                                      style: const TextStyle(fontSize: 20)),
                                ),
                              ),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    l10n.optional,
                                    style: const TextStyle(
                                        fontSize: 10, fontWeight: FontWeight.w600),
                                  ),
                                )
                              else if (hasIngredient)
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.check,
                                      size: 14, color: Colors.green.shade700),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(Icons.close,
                                      size: 14, color: Colors.red.shade700),
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
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                l10n.preparation,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          _CookingModeButton(
                            isTr: isTr,
                            onPressed: () {
                              final ingredientNames = recipe.ingredients.map((ing) {
                                final data = provider.recipeService
                                    .getIngredientById(ing.ingredientId);
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
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      ...steps.asMap().entries.map((entry) => _StepCard(
                            step: entry.value,
                            index: entry.key,
                            totalSteps: steps.length,
                            locale: locale,
                            l10n: l10n,
                          )),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider(ThemeData theme) {
    return Container(
      width: 1,
      height: 30,
      color: theme.colorScheme.outlineVariant.withOpacity(0.3),
    );
  }

  static Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
      case 'kolay':
        return Colors.green;
      case 'medium':
      case 'orta':
        return Colors.orange;
      case 'hard':
      case 'zor':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// ── Enhanced Info Chip ──
class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ── Cooking Mode Button ──
class _CookingModeButton extends StatelessWidget {
  final bool isTr;
  final VoidCallback onPressed;

  const _CookingModeButton({required this.isTr, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
            ),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF6B35).withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.restaurant, size: 16, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                isTr ? 'Pişirme Modu' : 'Cooking Mode',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Enhanced Step Card ──
class _StepCard extends StatelessWidget {
  final RecipeStep step;
  final int index;
  final int totalSteps;
  final String locale;
  final AppLocalizations l10n;

  const _StepCard({
    required this.step,
    required this.index,
    required this.totalSteps,
    required this.locale,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = index == totalSteps - 1;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline column
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${step.stepNumber}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            theme.colorScheme.primary.withOpacity(0.3),
                            theme.colorScheme.primary.withOpacity(0.08),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.instruction,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.6,
                    ),
                  ),
                  if (step.durationMinutes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.access_time,
                                size: 13, color: Colors.blue.shade700),
                            const SizedBox(width: 4),
                            Text(
                              '~${step.durationMinutes} ${l10n.minutes}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
