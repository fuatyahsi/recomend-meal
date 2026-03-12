import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../services/recipe_service.dart';
import 'recipe_detail_screen.dart';

class RecipeListScreen extends StatefulWidget {
  const RecipeListScreen({super.key});

  @override
  State<RecipeListScreen> createState() => _RecipeListScreenState();
}

class _RecipeListScreenState extends State<RecipeListScreen> {
  bool _showOnlyFullMatch = false;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = provider.languageCode;

    List<RecipeMatch> recipes = provider.matchingRecipes;
    if (_showOnlyFullMatch) {
      recipes = recipes.where((r) => r.canMake).toList();
    }

    final fullMatchCount =
        provider.matchingRecipes.where((r) => r.canMake).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.recipesFound),
        actions: [
          if (provider.matchingRecipes.isNotEmpty)
            IconButton(
              icon: Icon(
                _showOnlyFullMatch
                    ? Icons.filter_alt
                    : Icons.filter_alt_outlined,
              ),
              onPressed: () =>
                  setState(() => _showOnlyFullMatch = !_showOnlyFullMatch),
              tooltip: _showOnlyFullMatch
                  ? l10n.showAll
                  : l10n.showOnlyFullMatch,
            ),
        ],
      ),
      body: recipes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('😔', style: TextStyle(fontSize: 64)),
                    const SizedBox(height: 16),
                    Text(
                      l10n.noRecipesFound,
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Stats bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: Row(
                    children: [
                      Icon(Icons.restaurant,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Text(
                        '${recipes.length} ${l10n.recipesFound.toLowerCase()}',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (fullMatchCount > 0)
                        Chip(
                          label: Text(
                            '$fullMatchCount ${l10n.canMake}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor:
                              Colors.green.shade100,
                          side: BorderSide.none,
                        ),
                    ],
                  ),
                ),

                // Recipe List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final match = recipes[index];
                      return _RecipeCard(
                        match: match,
                        locale: locale,
                        isFavorite: provider.isFavorite(match.recipe.id),
                        onFavoriteToggle: () =>
                            provider.toggleFavorite(match.recipe.id),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RecipeDetailScreen(
                                recipe: match.recipe,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final RecipeMatch match;
  final String locale;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.match,
    required this.locale,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = match.recipe;
    final l10n = AppLocalizations.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Emoji icon
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: match.canMake
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        recipe.imageEmoji,
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.getName(locale),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recipe.getDescription(locale),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  // Favorite
                  IconButton(
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color:
                          isFavorite ? Colors.red : theme.colorScheme.outline,
                    ),
                    onPressed: onFavoriteToggle,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Match percentage bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: match.matchPercentage,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        color: match.canMake
                            ? Colors.green
                            : match.matchPercent >= 70
                                ? Colors.orange
                                : Colors.red.shade300,
                        minHeight: 8,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '%${match.matchPercent} ${l10n.matchPercentage}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: match.canMake
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Bottom row - time, difficulty, missing
              Row(
                children: [
                  // Time
                  Icon(Icons.access_time,
                      size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.totalTimeMinutes} ${l10n.minutes}',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(width: 16),

                  // Difficulty
                  Icon(Icons.signal_cellular_alt,
                      size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text(
                    recipe.getDifficultyText(locale),
                    style: theme.textTheme.bodySmall,
                  ),

                  const Spacer(),

                  // Status badge
                  if (match.canMake)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '✅ ${l10n.canMake}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '⚠️ ${l10n.missingIngredients(match.missingIngredients.length)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
