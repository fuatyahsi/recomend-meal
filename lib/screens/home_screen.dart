import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../models/recipe.dart';
import 'ingredient_selection_screen.dart';
import 'category_recipes_screen.dart';
import 'recipe_detail_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _categories = [
    {'id': 'breakfast', 'emoji': '🍳', 'tr': 'Kahvaltı', 'en': 'Breakfast', 'color': 0xFFFFF3E0},
    {'id': 'soup', 'emoji': '🥣', 'tr': 'Çorba', 'en': 'Soup', 'color': 0xFFE8F5E9},
    {'id': 'main', 'emoji': '🍖', 'tr': 'Ana Yemek', 'en': 'Main', 'color': 0xFFFFEBEE},
    {'id': 'appetizer', 'emoji': '🥟', 'tr': 'Meze', 'en': 'Appetizer', 'color': 0xFFE3F2FD},
    {'id': 'salad', 'emoji': '🥗', 'tr': 'Salata', 'en': 'Salad', 'color': 0xFFE8F5E9},
    {'id': 'dessert', 'emoji': '🍰', 'tr': 'Tatlı', 'en': 'Dessert', 'color': 0xFFFCE4EC},
    {'id': 'beverage', 'emoji': '🥤', 'tr': 'İçecek', 'en': 'Beverage', 'color': 0xFFE0F7FA},
    {'id': 'side', 'emoji': '🍚', 'tr': 'Garnitür', 'en': 'Side', 'color': 0xFFFFF8E1},
  ];

  void _openCategory(BuildContext context, Map<String, dynamic> cat, String locale) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryRecipesScreen(
          categoryId: cat['id'] as String,
          categoryName: (locale == 'tr' ? cat['tr'] : cat['en']) as String,
          categoryEmoji: cat['emoji'] as String,
        ),
      ),
    );
  }

  void _openAllRecipes(BuildContext context, String locale) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryRecipesScreen(
          categoryId: 'all',
          categoryName: locale == 'tr' ? 'Tüm Tarifler' : 'All Recipes',
          categoryEmoji: '📋',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = provider.languageCode;
    final isTr = locale == 'tr';

    // Get a few popular recipes for the "Öne Çıkanlar" section
    final allRecipes = provider.recipeService.recipes;
    final popularRecipes = allRecipes.length > 6 ? allRecipes.sublist(0, 6) : allRecipes;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top Bar ──
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.appName,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          Text(
                            l10n.appTagline,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () => provider.toggleLanguage(),
                      child: Text(
                        locale == 'tr' ? '🇬🇧 EN' : '🇹🇷 TR',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_outlined, size: 22),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── "Buzdolabında Ne Var?" CTA ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const IngredientSelectionScreen()),
                  ),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary,
                          theme.colorScheme.primary.withOpacity(0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Text('🧊', style: TextStyle(fontSize: 28)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTr ? 'Buzdolabında Ne Var?' : "What's in Your Fridge?",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isTr
                                    ? 'Malzemelerini seç, sana tarif bulalım'
                                    : 'Select ingredients, we\'ll find recipes',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withOpacity(0.85),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.7), size: 18),
                      ],
                    ),
                  ),
                ),
              ),

              // Quick stats if ingredients already selected
              if (provider.selectedCount > 0)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            l10n.ingredientsSelected(provider.selectedCount),
                            style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const IngredientSelectionScreen()),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(l10n.findRecipes, style: const TextStyle(fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // ── Kategoriler ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTr ? 'Kategoriler' : 'Categories',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => _openAllRecipes(context, locale),
                      child: Text(
                        isTr ? 'Tümünü Gör' : 'See All',
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final count = provider.recipeService
                        .getRecipesByCategory(cat['id'] as String)
                        .length;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => _openCategory(context, cat, locale),
                        child: SizedBox(
                          width: 78,
                          height: 100,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: Color(cat['color'] as int),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Center(
                                  child: Text(
                                    cat['emoji'] as String,
                                    style: const TextStyle(fontSize: 26),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                '${isTr ? cat['tr'] : cat['en']}',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '($count)',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ── Öne Çıkan Tarifler ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isTr ? 'Öne Çıkanlar' : 'Popular Recipes',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => _openAllRecipes(context, locale),
                      child: Text(
                        isTr ? 'Tümünü Gör' : 'See All',
                        style: TextStyle(fontSize: 13, color: theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 170,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: popularRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = popularRecipes[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecipeDetailScreen(recipe: recipe),
                          ),
                        ),
                        child: _PopularRecipeCard(recipe: recipe, locale: locale),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // ── Hızlı Tarifler (< 20 dk) ──
              Builder(
                builder: (context) {
                  final quickRecipes = allRecipes
                      .where((r) => r.totalTimeMinutes <= 20)
                      .take(6)
                      .toList();
                  if (quickRecipes.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          isTr ? '⚡ Hızlı Tarifler (≤ 20 dk)' : '⚡ Quick Recipes (≤ 20 min)',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...quickRecipes.map((recipe) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
                        child: _QuickRecipeTile(
                          recipe: recipe,
                          locale: locale,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(recipe: recipe),
                            ),
                          ),
                        ),
                      )),
                    ],
                  );
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Popular Recipe Horizontal Card ──
class _PopularRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final String locale;

  const _PopularRecipeCard({required this.recipe, required this.locale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.4),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(recipe.imageEmoji, style: const TextStyle(fontSize: 32)),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              recipe.getName(locale),
              style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.access_time, size: 12, color: theme.colorScheme.outline),
              const SizedBox(width: 3),
              Text(
                '${recipe.totalTimeMinutes} dk',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick Recipe Tile ──
class _QuickRecipeTile extends StatelessWidget {
  final Recipe recipe;
  final String locale;
  final VoidCallback onTap;

  const _QuickRecipeTile({
    required this.recipe,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Text(recipe.imageEmoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recipe.getName(locale),
                  style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${recipe.totalTimeMinutes} dk',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, size: 18, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
