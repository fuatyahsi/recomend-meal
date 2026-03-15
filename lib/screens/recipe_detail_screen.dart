import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../l10n/app_localizations.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import '../utils/ingredient_substitutes.dart';
import 'cooking_mode_screen.dart';

class RecipeDetailScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailScreen({super.key, required this.recipe});

  @override
  State<RecipeDetailScreen> createState() => _RecipeDetailScreenState();
}

class _RecipeDetailScreenState extends State<RecipeDetailScreen> {
  late int _servings;
  late double _multiplier;

  @override
  void initState() {
    super.initState();
    _servings = widget.recipe.servings;
    _multiplier = 1.0;
  }

  void _updateServings(int newServings) {
    setState(() {
      _servings = newServings.clamp(1, 20);
      _multiplier = _servings / widget.recipe.servings;
    });
  }

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
    final recipe = widget.recipe;

    final steps = recipe.getSteps(locale);
    final isFavorite = provider.isFavorite(recipe.id);
    final gradientColors = AppTheme.categoryGradients[recipe.category] ??
        [const Color(0xFFF5F5F5), const Color(0xFFE0E0E0)];

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                recipe.getName(locale),
                style: const TextStyle(
                  fontWeight: FontWeight.w800, fontSize: 16,
                  shadows: [
                    Shadow(blurRadius: 12, color: Colors.black54),
                    Shadow(blurRadius: 24, color: Colors.black26),
                  ],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight,
                        colors: [gradientColors[0], gradientColors[1], theme.colorScheme.primary.withOpacity(0.6)],
                      ),
                    ),
                  ),
                  Positioned(right: -30, bottom: -20,
                    child: Text(recipe.imageEmoji, style: TextStyle(fontSize: 140, color: Colors.black.withOpacity(0.04))),
                  ),
                  Center(
                    child: Hero(
                      tag: 'recipe_${recipe.id}',
                      child: Text(recipe.imageEmoji, style: const TextStyle(fontSize: 80)),
                    ),
                  ),
                  Positioned(bottom: 0, left: 0, right: 0, height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
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
                decoration: BoxDecoration(color: Colors.black.withOpacity(0.15), shape: BoxShape.circle),
                child: IconButton(
                  icon: Icon(isFavorite ? Icons.favorite : Icons.favorite_border, color: isFavorite ? Colors.redAccent : Colors.white),
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
                      verticalOffset: 30.0, child: FadeInAnimation(child: widget),
                    ),
                    children: [
                      // Category badge & tags
                      Wrap(
                        spacing: 6, runSpacing: 6,
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
                      Text(recipe.getDescription(locale),
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
                      ),

                      const SizedBox(height: 20),

                      // Info cards row
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: AppTheme.softShadow,
                          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _InfoChip(icon: Icons.timer_outlined, label: l10n.prepTime, value: '${recipe.prepTimeMinutes}\'', color: Colors.blue),
                            _divider(theme),
                            _InfoChip(icon: Icons.local_fire_department_outlined, label: l10n.cookTime, value: '${recipe.cookTimeMinutes}\'', color: Colors.deepOrange),
                            _divider(theme),
                            _InfoChip(icon: Icons.people_outline, label: l10n.servings, value: '$_servings', color: Colors.teal),
                            _divider(theme),
                            _InfoChip(icon: Icons.signal_cellular_alt, label: l10n.difficulty, value: recipe.getDifficultyText(locale), color: _getDifficultyColor(recipe.difficulty)),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Total time
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [Colors.orange.shade50, Colors.orange.shade50.withOpacity(0.5)]),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.orange.shade100),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)),
                              child: Icon(Icons.schedule, color: Colors.deepOrange.shade700, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              isTr ? 'Toplam Süre: ${recipe.totalTimeMinutes} dakika' : 'Total Time: ${recipe.totalTimeMinutes} minutes',
                              style: TextStyle(fontWeight: FontWeight.w700, color: Colors.deepOrange.shade700, fontSize: 15),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ══════════════════════════════════════
                      // ══ PORSIYON HESAPLAYICI ══
                      // ══════════════════════════════════════
                      _PortionCalculator(
                        originalServings: recipe.servings,
                        currentServings: _servings,
                        isTr: isTr,
                        onChanged: _updateServings,
                      ),

                      const SizedBox(height: 20),

                      // Ingredients Section header
                      Row(
                        children: [
                          Container(width: 4, height: 24,
                            decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2)),
                          ),
                          const SizedBox(width: 10),
                          Text(l10n.ingredients,
                            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          if (_multiplier != 1.0) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.teal.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '×${_multiplier.toStringAsFixed(_multiplier == _multiplier.roundToDouble() ? 0 : 1)}',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.teal.shade700),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),

                      ...recipe.ingredients.map((ing) {
                        final ingredientData = provider.recipeService.getIngredientById(ing.ingredientId);
                        final hasIngredient = provider.isIngredientSelected(ing.ingredientId);
                        final name = ingredientData?.getName(locale) ?? ing.ingredientId;
                        final icon = ingredientData?.icon ?? '🥘';
                        final substitute = IngredientSubstitutes.getSubstitute(ing.ingredientId, locale);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: hasIngredient ? Colors.green.shade50
                                : ing.isOptional ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.5)
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: hasIngredient ? Colors.green.shade200
                                  : ing.isOptional ? theme.colorScheme.outlineVariant.withOpacity(0.3)
                                  : Colors.red.shade200,
                            ),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36, height: 36,
                                    decoration: BoxDecoration(
                                      color: hasIngredient ? Colors.green.shade100
                                          : ing.isOptional ? Colors.grey.shade100 : Colors.red.shade100,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(child: Text(icon, style: const TextStyle(fontSize: 20))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                                        // Scaled amount
                                        AnimatedSwitcher(
                                          duration: const Duration(milliseconds: 200),
                                          child: Text(
                                            ing.getScaledAmount(locale, _multiplier),
                                            key: ValueKey('${ing.ingredientId}_$_multiplier'),
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: _multiplier != 1.0
                                                  ? Colors.teal.shade700
                                                  : theme.colorScheme.onSurfaceVariant,
                                              fontWeight: _multiplier != 1.0 ? FontWeight.w600 : FontWeight.normal,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (ing.isOptional)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(8)),
                                      child: Text(l10n.optional, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                                    )
                                  else if (hasIngredient)
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: Colors.green.shade100, shape: BoxShape.circle),
                                      child: Icon(Icons.check, size: 14, color: Colors.green.shade700),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(color: Colors.red.shade100, shape: BoxShape.circle),
                                      child: Icon(Icons.close, size: 14, color: Colors.red.shade700),
                                    ),
                                ],
                              ),
                              // İkame önerisi (malzeme yoksa ve ikame varsa)
                              if (!hasIngredient && !ing.isOptional && substitute != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.amber.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.amber.shade200),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.swap_horiz, size: 16, color: Colors.amber.shade800),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            substitute,
                                            style: TextStyle(fontSize: 11, color: Colors.amber.shade900, fontWeight: FontWeight.w500),
                                          ),
                                        ),
                                      ],
                                    ),
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
                          Row(children: [
                            Container(width: 4, height: 24,
                              decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(2)),
                            ),
                            const SizedBox(width: 10),
                            Text(l10n.preparation, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                          ]),
                          _CookingModeButton(
                            isTr: isTr,
                            onPressed: () {
                              final ingredientNames = recipe.ingredients.map((ing) {
                                final data = provider.recipeService.getIngredientById(ing.ingredientId);
                                final n = data?.getName(locale) ?? ing.ingredientId;
                                return '${ing.getScaledAmount(locale, _multiplier)} $n';
                              }).toList();
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => CookingModeScreen(
                                  recipeName: recipe.getName(locale),
                                  emoji: recipe.imageEmoji,
                                  steps: steps.map((s) => s.instruction).toList(),
                                  ingredients: ingredientNames,
                                ),
                              ));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      ...steps.asMap().entries.map((entry) => _StepCard(
                        step: entry.value, index: entry.key, totalSteps: steps.length, locale: locale, l10n: l10n,
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
    return Container(width: 1, height: 30, color: theme.colorScheme.outlineVariant.withOpacity(0.3));
  }

  static Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy': case 'kolay': return Colors.green;
      case 'medium': case 'orta': return Colors.orange;
      case 'hard': case 'zor': return Colors.red;
      default: return Colors.grey;
    }
  }
}

// ══════════════════════════════════════
// ══ PORSIYON HESAPLAYICI WIDGET ══
// ══════════════════════════════════════
class _PortionCalculator extends StatelessWidget {
  final int originalServings;
  final int currentServings;
  final bool isTr;
  final ValueChanged<int> onChanged;

  const _PortionCalculator({
    required this.originalServings,
    required this.currentServings,
    required this.isTr,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isModified = currentServings != originalServings;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal.shade50,
            Colors.teal.shade50.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.teal.shade100),
        boxShadow: [
          BoxShadow(color: Colors.teal.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.teal.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.groups, size: 20, color: Colors.teal.shade700),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isTr ? 'Porsiyon Hesaplayıcı' : 'Portion Calculator',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              if (isModified)
                GestureDetector(
                  onTap: () => onChanged(originalServings),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isTr ? 'Sıfırla' : 'Reset',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.teal.shade800),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _PortionButton(
                icon: Icons.remove,
                onTap: currentServings > 1 ? () => onChanged(currentServings - 1) : null,
              ),
              const SizedBox(width: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) =>
                    ScaleTransition(scale: animation, child: child),
                child: Container(
                  key: ValueKey(currentServings),
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.teal.shade400, Colors.teal.shade600]),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.teal.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$currentServings',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, height: 1),
                      ),
                      Text(isTr ? 'kişi' : 'ppl',
                        style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              _PortionButton(
                icon: Icons.add,
                onTap: currentServings < 20 ? () => onChanged(currentServings + 1) : null,
              ),
            ],
          ),
          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.teal.shade400,
              inactiveTrackColor: Colors.teal.shade100,
              thumbColor: Colors.teal.shade600,
              overlayColor: Colors.teal.withOpacity(0.15),
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: Slider(
              value: currentServings.toDouble(),
              min: 1,
              max: 20,
              divisions: 19,
              onChanged: (v) => onChanged(v.round()),
            ),
          ),
          if (isModified)
            Text(
              isTr
                  ? 'Orijinal: $originalServings kişilik • Malzemeler otomatik güncellendi'
                  : 'Original: $originalServings servings • Ingredients auto-updated',
              style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontStyle: FontStyle.italic),
            ),
        ],
      ),
    );
  }
}

class _PortionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _PortionButton({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: enabled ? Colors.teal.shade100 : Colors.grey.shade200,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: enabled ? Colors.teal.shade700 : Colors.grey.shade400),
      ),
    );
  }
}

// ── Info Chip ──
class _InfoChip extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color color;
  const _InfoChip({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(height: 6),
      Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 10)),
      const SizedBox(height: 2),
      Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 13)),
    ]);
  }
}

// ── Cooking Mode Button ──
class _CookingModeButton extends StatelessWidget {
  final bool isTr; final VoidCallback onPressed;
  const _CookingModeButton({required this.isTr, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed, borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)]),
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: const Color(0xFFFF6B35).withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.support_agent, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(isTr ? 'Sesli Sous Chef' : 'Voice Sous Chef',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
        ),
      ),
    );
  }
}

// ── Step Card ──
class _StepCard extends StatelessWidget {
  final RecipeStep step; final int index; final int totalSteps; final String locale; final AppLocalizations l10n;
  const _StepCard({required this.step, required this.index, required this.totalSteps, required this.locale, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = index == totalSteps - 1;
    return IntrinsicHeight(
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(width: 40, child: Column(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primary.withOpacity(0.7)]),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.2), blurRadius: 6, offset: const Offset(0, 2))],
            ),
            child: Center(child: Text('${step.stepNumber}',
              style: TextStyle(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w800, fontSize: 14))),
          ),
          if (!isLast) Expanded(
            child: Container(width: 2, margin: const EdgeInsets.symmetric(vertical: 4),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [theme.colorScheme.primary.withOpacity(0.3), theme.colorScheme.primary.withOpacity(0.08)]),
              ),
            ),
          ),
        ])),
        const SizedBox(width: 12),
        Expanded(child: Container(
          margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(step.instruction, style: theme.textTheme.bodyMedium?.copyWith(height: 1.6)),
            if (step.durationMinutes != null)
              Padding(padding: const EdgeInsets.only(top: 8), child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.access_time, size: 13, color: Colors.blue.shade700),
                  const SizedBox(width: 4),
                  Text('~${step.durationMinutes} ${l10n.minutes}',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue.shade700)),
                ]),
              )),
          ]),
        )),
      ]),
    );
  }
}
