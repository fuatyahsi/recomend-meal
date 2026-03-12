import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/recipe.dart';
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

    final recipes = categoryId == 'all'
        ? provider.recipeService.recipes
        : provider.recipeService.getRecipesByCategory(categoryId);

    return Scaffold(
      appBar: AppBar(
        title: Text('$categoryEmoji $categoryName'),
      ),
      body: recipes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📭', style: TextStyle(fontSize: 64)),
                  const SizedBox(height: 16),
                  Text(
                    locale == 'tr'
                        ? 'Bu kategoride tarif yok'
                        : 'No recipes in this category',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: recipes.length,
              itemBuilder: (context, index) {
                final recipe = recipes[index];
                return _BrowseRecipeCard(
                  recipe: recipe,
                  locale: locale,
                  isFavorite: provider.isFavorite(recipe.id),
                  onFavoriteToggle: () => provider.toggleFavorite(recipe.id),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipe: recipe),
                      ),
                    );
                  },
                );
              },
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

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Emoji
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(recipe.imageEmoji, style: const TextStyle(fontSize: 28)),
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recipe.getDescription(locale),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.totalTimeMinutes} dk',
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.signal_cellular_alt, size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 3),
                        Text(
                          recipe.getDifficultyText(locale),
                          style: theme.textTheme.labelSmall,
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.people_outline, size: 14, color: theme.colorScheme.outline),
                        const SizedBox(width: 3),
                        Text(
                          '${recipe.servings}',
                          style: theme.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Favorite + Arrow
              Column(
                children: [
                  GestureDetector(
                    onTap: onFavoriteToggle,
                    child: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : theme.colorScheme.outline,
                      size: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Icon(Icons.chevron_right, color: theme.colorScheme.outline, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
