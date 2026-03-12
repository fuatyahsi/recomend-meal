import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/community_recipe_model.dart';
import '../../models/user_model.dart';
import '../../providers/app_provider.dart';
import '../../services/community_recipe_service.dart';
import '../../services/leaderboard_service.dart';
import '../community/community_recipe_detail_screen.dart';
import 'user_profile_screen.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _recipeService = CommunityRecipeService();
  final _leaderboardService = LeaderboardService();

  List<CommunityRecipe> _trendingRecipes = [];
  List<CommunityRecipe> _latestRecipes = [];
  List<AppUser> _popularUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final trending = await _recipeService.getTrendingRecipes(limit: 10);
      final latest = await _recipeService.getLatestRecipes(limit: 10);
      final popular = await _leaderboardService.getTopSharers(limit: 10);

      if (mounted) {
        setState(() {
          _trendingRecipes = trending;
          _latestRecipes = latest;
          _popularUsers = popular;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = context.read<AppProvider>().locale.languageCode == 'tr';
    final locale = isTr ? 'tr' : 'en';

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(isTr ? 'Keşfet' : 'Discover')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(isTr ? 'Keşfet' : 'Discover')),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Popüler Şefler
            Text(
              isTr ? '🌟 Popüler Şefler' : '🌟 Popular Chefs',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 120,
              child: _popularUsers.isEmpty
                  ? Center(
                      child: Text(
                        isTr ? 'Henüz kullanıcı yok' : 'No users yet',
                        style: TextStyle(color: theme.colorScheme.outline),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _popularUsers.length,
                      itemBuilder: (context, index) {
                        final user = _popularUsers[index];
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  UserProfileScreen(userId: user.uid),
                            ),
                          ),
                          child: Container(
                            width: 85,
                            margin: const EdgeInsets.only(right: 12),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 32,
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  child: Text(
                                    user.displayName.isNotEmpty
                                        ? user.displayName[0].toUpperCase()
                                        : '?',
                                    style: TextStyle(
                                      fontSize: 24,
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  user.displayName,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                                Text(
                                  '${user.totalRecipesShared} ${isTr ? 'tarif' : 'recipes'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 10,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 24),

            // Trend Tarifler
            Text(
              isTr ? '🔥 Trend Tarifler' : '🔥 Trending Recipes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (_trendingRecipes.isEmpty)
              _EmptyState(text: isTr ? 'Henüz tarif yok' : 'No recipes yet')
            else
              SizedBox(
                height: 220,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _trendingRecipes.length,
                  itemBuilder: (context, index) {
                    final recipe = _trendingRecipes[index];
                    return _RecipeCard(
                      recipe: recipe,
                      locale: locale,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CommunityRecipeDetailScreen(recipe: recipe),
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 24),

            // En Son Eklenenler
            Text(
              isTr ? '🆕 En Son Eklenenler' : '🆕 Recently Added',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (_latestRecipes.isEmpty)
              _EmptyState(text: isTr ? 'Henüz tarif yok' : 'No recipes yet')
            else
              ..._latestRecipes.map((recipe) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CommunityRecipeDetailScreen(recipe: recipe),
                        ),
                      ),
                      leading: recipe.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: recipe.imageUrl,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Text(
                                    recipe.imageEmoji,
                                    style: const TextStyle(fontSize: 28)),
                              ),
                            )
                          : Text(recipe.imageEmoji,
                              style: const TextStyle(fontSize: 28)),
                      title: Text(
                        recipe.getName(locale),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Row(
                        children: [
                          Text(recipe.userDisplayName,
                              style: theme.textTheme.bodySmall),
                          const SizedBox(width: 8),
                          const Icon(Icons.favorite,
                              size: 14, color: Colors.red),
                          const SizedBox(width: 2),
                          Text('${recipe.totalLikes}',
                              style: theme.textTheme.bodySmall),
                          const SizedBox(width: 8),
                          const Icon(Icons.star,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(recipe.averageRating.toStringAsFixed(1),
                              style: theme.textTheme.bodySmall),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final CommunityRecipe recipe;
  final String locale;
  final VoidCallback onTap;

  const _RecipeCard({
    required this.recipe,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Resim veya emoji
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14),
                ),
              ),
              child: recipe.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: recipe.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Center(
                          child: Text(recipe.imageEmoji,
                              style: const TextStyle(fontSize: 48)),
                        ),
                      ),
                    )
                  : Center(
                      child: Text(recipe.imageEmoji,
                          style: const TextStyle(fontSize: 48)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe.getName(locale),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 14, color: Colors.red),
                      const SizedBox(width: 2),
                      Text('${recipe.totalLikes}',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(width: 8),
                      const Icon(Icons.star, size: 14, color: Colors.amber),
                      const SizedBox(width: 2),
                      Text(recipe.averageRating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Text(text,
            style: TextStyle(color: Theme.of(context).colorScheme.outline)),
      ),
    );
  }
}
