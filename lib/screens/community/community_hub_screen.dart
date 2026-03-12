import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/community_recipe_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_recipe_service.dart';
import '../../widgets/rating_stars_widget.dart';
import '../../widgets/banner_ad_widget.dart';
import 'submit_recipe_screen.dart';
import 'community_recipe_detail_screen.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen>
    with SingleTickerProviderStateMixin {
  final _recipeService = CommunityRecipeService();
  late TabController _tabController;

  List<CommunityRecipe> _trending = [];
  List<CommunityRecipe> _latest = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _recipeService.getTrendingRecipes(),
        _recipeService.getLatestRecipes(),
      ]);
      _trending = results[0];
      _latest = results[1];
    } catch (e) {
      debugPrint('CommunityHub load error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = l10n.languageCode;
    final isTr = locale == 'tr';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTr ? 'Topluluk Tarifleri' : 'Community Recipes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.trending_up),
              text: isTr ? 'Trend' : 'Trending',
            ),
            Tab(
              icon: const Icon(Icons.new_releases_outlined),
              text: isTr ? 'Yeni' : 'Latest',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _RecipeList(
                        recipes: _trending,
                        locale: locale,
                        emptyMessage: isTr
                            ? 'Henüz tarif yok. İlk tarifi sen paylaş!'
                            : 'No recipes yet. Be the first to share!',
                        onRefresh: _loadRecipes,
                      ),
                      _RecipeList(
                        recipes: _latest,
                        locale: locale,
                        emptyMessage: isTr
                            ? 'Henüz tarif yok.'
                            : 'No recipes yet.',
                        onRefresh: _loadRecipes,
                      ),
                    ],
                  ),
          ),
          const BannerAdWidget(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final auth = context.read<AuthProvider>();
          if (!auth.isAuthenticated) return;
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubmitRecipeScreen()),
          );
          _loadRecipes();
        },
        icon: const Icon(Icons.add),
        label: Text(isTr ? 'Tarif Paylaş' : 'Share Recipe'),
      ),
    );
  }
}

class _RecipeList extends StatelessWidget {
  final List<CommunityRecipe> recipes;
  final String locale;
  final String emptyMessage;
  final VoidCallback onRefresh;

  const _RecipeList({
    required this.recipes,
    required this.locale,
    required this.emptyMessage,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📭', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(emptyMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: recipes.length,
        itemBuilder: (context, index) {
          final recipe = recipes[index];
          return _CommunityRecipeCard(recipe: recipe, locale: locale);
        },
      ),
    );
  }
}

class _CommunityRecipeCard extends StatelessWidget {
  final CommunityRecipe recipe;
  final String locale;

  const _CommunityRecipeCard({required this.recipe, required this.locale});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = locale == 'tr';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommunityRecipeDetailScreen(recipe: recipe),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Recipe emoji
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(recipe.imageEmoji,
                          style: const TextStyle(fontSize: 28)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recipe.getName(locale),
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${isTr ? "Paylaşan" : "By"}: ${recipe.userDisplayName}',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Stats row
              Row(
                children: [
                  if (recipe.totalRatings > 0)
                    RatingStarsWidget(
                        rating: recipe.averageRating, size: 16),
                  if (recipe.totalRatings > 0) const SizedBox(width: 8),
                  Text('(${recipe.totalRatings})',
                      style: theme.textTheme.bodySmall),
                  const Spacer(),
                  Icon(Icons.favorite, size: 16, color: Colors.red.shade300),
                  const SizedBox(width: 4),
                  Text('${recipe.totalLikes}',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                  Icon(Icons.access_time,
                      size: 16, color: theme.colorScheme.outline),
                  const SizedBox(width: 4),
                  Text('${recipe.totalTimeMinutes} ${isTr ? "dk" : "min"}',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
