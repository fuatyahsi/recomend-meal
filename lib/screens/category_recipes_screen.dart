import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/app_provider.dart';
import '../models/recipe.dart';
import '../utils/app_theme.dart';
import 'recipe_detail_screen.dart';

class CategoryRecipesScreen extends StatelessWidget {
  final String categoryId;
  final String categoryName;
  final String categoryEmoji;

  const CategoryRecipesScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    required this.categoryEmoji,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final locale = provider.languageCode;
    final isTr = locale == 'tr';

    final recipes = categoryId == 'all'
        ? provider.recipeService.recipes
        : provider.recipeService.getRecipesByCategory(categoryId);

    final gradientColors = AppTheme.categoryGradients[categoryId] ??
        [theme.colorScheme.primaryContainer, theme.colorScheme.primary.withOpacity(0.3)];

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Enhanced header with category gradient
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                '$categoryEmoji $categoryName',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black38)],
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          gradientColors[0],
                          gradientColors[1],
                          theme.colorScheme.primary.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                  // Subtle pattern
                  Positioned(
                    right: -20,
                    bottom: -10,
                    child: Text(
                      categoryEmoji,
                      style: TextStyle(
                        fontSize: 100,
                        color: Colors.black.withOpacity(0.04),
                      ),
                    ),
                  ),
                  // Recipe count badge
                  Positioned(
                    right: 16,
                    bottom: 50,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: Text(
                        '${recipes.length} ${isTr ? 'tarif' : 'recipes'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          recipes.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('📭', style: TextStyle(fontSize: 64)),
                        const SizedBox(height: 16),
                        Text(
                          isTr ? 'Bu kategoride tarif yok' : 'No recipes in this category',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final recipe = recipes[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 40.0,
                            child: FadeInAnimation(
                              child: _BrowseRecipeCard(
                                recipe: recipe,
                                locale: locale,
                                isFavorite: provider.isFavorite(recipe.id),
                                onFavoriteToggle: () => provider.toggleFavorite(recipe.id),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => RecipeDetailScreen(recipe: recipe),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: recipes.length,
                    ),
                  ),
                ),
        ],
      ),
    );
  }
}

class _BrowseRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final String locale;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  const _BrowseRecipeCard({
    required this.recipe,
    required this.locale,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradientColors = AppTheme.categoryGradients[recipe.category] ??
        [const Color(0xFFF5F5F5), const Color(0xFFE0E0E0)];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.15),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Gradient emoji container
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: gradientColors[1].withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(recipe.imageEmoji, style: const TextStyle(fontSize: 30)),
                  ),
                ),
                const SizedBox(width: 14),

                // Info
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
                      const SizedBox(height: 4),
                      Text(
                        recipe.getDescription(locale),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _InfoTag(
                            icon: Icons.schedule,
                            text: '${recipe.totalTimeMinutes}\'',
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 6),
                          _InfoTag(
                            icon: Icons.signal_cellular_alt,
                            text: recipe.getDifficultyText(locale),
                            color: _getDifficultyColor(recipe.difficulty),
                          ),
                          const SizedBox(width: 6),
                          _InfoTag(
                            icon: Icons.people_outline,
                            text: '${recipe.servings}',
                            color: Colors.teal,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Favorite + Arrow
                Column(
                  children: [
                    GestureDetector(
                      onTap: onFavoriteToggle,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isFavorite
                              ? Colors.red.shade50
                              : Colors.transparent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : theme.colorScheme.outline,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.chevron_right,
                          color: theme.colorScheme.outline, size: 16),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
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

class _InfoTag extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _InfoTag({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
