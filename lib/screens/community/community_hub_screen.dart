import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/community_recipe_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_recipe_service.dart';
import '../../utils/community_challenges.dart';
import '../../widgets/rating_stars_widget.dart';
import '../../widgets/banner_ad_widget.dart';
import '../auth/login_screen.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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

  Future<bool> _ensureAuthenticated() async {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      return true;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );

    if (!mounted) {
      return false;
    }

    return context.read<AuthProvider>().isAuthenticated;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = l10n.languageCode;
    final isTr = locale == 'tr';
    final activeChallenge = CommunityChallenges.active();
    final challengeRecipes = {
      for (final recipe in [..._trending, ..._latest]) recipe.id: recipe,
    }.values.where((recipe) => recipe.tags.contains(activeChallenge.tag)).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
            const Tab(
              icon: Icon(Icons.emoji_events_outlined),
              text: 'Challenge',
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _ChallengeBanner(
              challenge: activeChallenge,
              recipes: challengeRecipes,
              isTr: isTr,
              onParticipate: () async {
                final isAuthenticated = await _ensureAuthenticated();
                if (!isAuthenticated || !mounted) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SubmitRecipeScreen(challenge: activeChallenge),
                  ),
                );
                _loadRecipes();
              },
            ),
          ),
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
                      _RecipeList(
                        recipes: challengeRecipes,
                        locale: locale,
                        emptyMessage: isTr
                            ? 'Bu haftanin challenge akisi henuz bos. Ilk tarifi sen gonder.'
                            : 'This week\'s challenge feed is still empty. Be the first entry.',
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
          final isAuthenticated = await _ensureAuthenticated();
          if (!isAuthenticated || !mounted) return;
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
              if (recipe.tags.isNotEmpty) ...[
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: recipe.tags.take(2).map((tag) {
                    final prettyTag = tag
                        .replaceFirst('challenge_', '')
                        .replaceAll('_', ' ');
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '#$prettyTag',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],
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

class _ChallengeBanner extends StatelessWidget {
  final CommunityChallenge challenge;
  final List<CommunityRecipe> recipes;
  final bool isTr;
  final VoidCallback onParticipate;

  const _ChallengeBanner({
    required this.challenge,
    required this.recipes,
    required this.isTr,
    required this.onParticipate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            challenge.accentColor.withValues(alpha: 0.92),
            challenge.accentColor.withValues(alpha: 0.68),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: challenge.accentColor.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(challenge.emoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTr ? 'Haftalık Challenge' : 'Weekly Challenge',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.title(isTr),
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.subtitle(isTr),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: onParticipate,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: challenge.accentColor,
                ),
                child: Text(isTr ? 'Katıl' : 'Join'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            challenge.description(isTr),
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ChallengeStat(
                label: isTr ? 'Katılım' : 'Entries',
                value: '${recipes.length}',
              ),
              _ChallengeStat(
                label: isTr ? 'Etiket' : 'Tag',
                value: '#${challenge.tag.replaceFirst('challenge_', '')}',
              ),
              if (recipes.isNotEmpty)
                _ChallengeStat(
                  label: isTr ? 'Son Gönderi' : 'Latest',
                  value: recipes.first.getName(isTr ? 'tr' : 'en'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChallengeStat extends StatelessWidget {
  final String label;
  final String value;

  const _ChallengeStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
