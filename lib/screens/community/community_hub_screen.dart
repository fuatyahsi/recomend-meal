import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../models/community_recipe_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_recipe_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/community_challenges.dart';
import '../../utils/text_repair.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/rating_stars_widget.dart';
import '../auth/login_screen.dart';
import 'community_recipe_detail_screen.dart';
import 'submit_recipe_screen.dart';

class CommunityHubScreen extends StatefulWidget {
  const CommunityHubScreen({super.key});

  @override
  State<CommunityHubScreen> createState() => _CommunityHubScreenState();
}

class _CommunityHubScreenState extends State<CommunityHubScreen>
    with SingleTickerProviderStateMixin {
  final _recipeService = CommunityRecipeService();
  late final TabController _tabController;

  List<CommunityRecipe> _trending = [];
  List<CommunityRecipe> _latest = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecipes();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    } catch (error) {
      debugPrint('CommunityHub load error: $error');
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
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
    final theme = Theme.of(context);
    final activeChallenge = CommunityChallenges.active();
    final challengeRecipes = {
      for (final recipe in [..._trending, ..._latest]) recipe.id: recipe,
    }
        .values
        .where((recipe) => recipe.tags.contains(activeChallenge.tag))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(isTr ? 'Leziz Tarifler' : 'Community Recipes'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.local_fire_department_rounded),
              text: isTr ? 'Öne çıkanlar' : 'Trending',
            ),
            Tab(
              icon: const Icon(Icons.schedule_rounded),
              text: isTr ? 'Yeni gelenler' : 'Latest',
            ),
            Tab(
              icon: const Icon(Icons.emoji_events_rounded),
              text: isTr ? 'Haftanın görevi' : 'Challenge',
            ),
          ],
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.26),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.18, 1.0],
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              child: _CommunityHeroCard(
                isTr: isTr,
                recipeCount: _trending.length + _latest.length,
                activeChallenge: activeChallenge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: _ChallengeBanner(
                challenge: activeChallenge,
                recipes: challengeRecipes,
                isTr: isTr,
                onParticipate: () async {
                  final isAuthenticated = await _ensureAuthenticated();
                  if (!isAuthenticated || !context.mounted) return;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SubmitRecipeScreen(challenge: activeChallenge),
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
                              ? 'Henüz tarif yok. İlk tarifi sen paylaş.'
                              : 'No recipes yet. Be the first to share one.',
                          onRefresh: _loadRecipes,
                        ),
                        _RecipeList(
                          recipes: _latest,
                          locale: locale,
                          emptyMessage: isTr
                              ? 'Henüz yeni tarif yok.'
                              : 'No new recipes yet.',
                          onRefresh: _loadRecipes,
                        ),
                        _RecipeList(
                          recipes: challengeRecipes,
                          locale: locale,
                          emptyMessage: isTr
                              ? 'Bu haftanın görevi için henüz tarif yok.'
                              : 'No recipes have been submitted for this challenge yet.',
                          onRefresh: _loadRecipes,
                        ),
                      ],
                    ),
            ),
            const BannerAdWidget(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final isAuthenticated = await _ensureAuthenticated();
          if (!isAuthenticated || !context.mounted) return;
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SubmitRecipeScreen()),
          );
          _loadRecipes();
        },
        icon: const Icon(Icons.add_rounded),
        label: Text(isTr ? 'Tarif paylaş' : 'Share recipe'),
      ),
    );
  }
}

class _CommunityHeroCard extends StatelessWidget {
  final bool isTr;
  final int recipeCount;
  final CommunityChallenge activeChallenge;

  const _CommunityHeroCard({
    required this.isTr,
    required this.recipeCount,
    required this.activeChallenge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D3557), Color(0xFF457B9D), Color(0xFFF4A261)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF457B9D).withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.forum_rounded,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              _HeroPill(
                label: isTr
                    ? '$recipeCount tarif canlı'
                    : '$recipeCount live recipes',
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            isTr ? 'Mahallenin tarif akışı burada' : 'Your local recipe pulse',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isTr
                ? 'Toplulukta ne pişiyor, hangi görev yükseliyor ve en sevilen tarifler hangileri tek yerde.'
                : 'See what people are cooking, which challenge is rising, and which recipes are getting the most love.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          _HeroPill(
            icon: Icons.emoji_events_rounded,
            label: activeChallenge.title(isTr),
          ),
        ],
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
    final theme = Theme.of(context);
    if (recipes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 44),
                const SizedBox(height: 14),
                Text(
                  emptyMessage,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
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

  const _CommunityRecipeCard({
    required this.recipe,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = locale == 'tr';
    final title = repairTurkishText(recipe.getName(locale));
    final author = repairTurkishText(recipe.userDisplayName);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CommunityRecipeDetailScreen(recipe: recipe),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primaryContainer,
                          theme.colorScheme.secondaryContainer,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        repairTurkishText(recipe.imageEmoji),
                        style: const TextStyle(fontSize: 30),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isTr ? 'Paylaşan: $author' : 'By $author',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (recipe.tags.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recipe.tags.take(3).map((tag) {
                    final prettyTag =
                        tag.replaceFirst('challenge_', '').replaceAll('_', ' ');
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.65),
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
              if (recipe.tags.isNotEmpty) const SizedBox(height: 12),
              Row(
                children: [
                  if (recipe.totalRatings > 0)
                    RatingStarsWidget(
                      rating: recipe.averageRating,
                      size: 16,
                    ),
                  if (recipe.totalRatings > 0) const SizedBox(width: 8),
                  Text(
                    '(${recipe.totalRatings})',
                    style: theme.textTheme.bodySmall,
                  ),
                  const Spacer(),
                  Icon(Icons.favorite_rounded,
                      size: 16, color: Colors.red.shade300),
                  const SizedBox(width: 4),
                  Text('${recipe.totalLikes}',
                      style: theme.textTheme.bodySmall),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.schedule_rounded,
                    size: 16,
                    color: theme.colorScheme.outline,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${recipe.totalTimeMinutes} ${isTr ? "dk" : "min"}',
                    style: theme.textTheme.bodySmall,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            challenge.accentColor.withValues(alpha: 0.95),
            challenge.accentColor.withValues(alpha: 0.72),
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
              Text(challenge.emoji, style: const TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTr ? 'Haftanın görevi' : 'Weekly challenge',
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
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      challenge.subtitle(isTr),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
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
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroPill(
                label: isTr
                    ? '${recipes.length} tarif geldi'
                    : '${recipes.length} recipes joined',
                dark: true,
              ),
              _HeroPill(
                label: '#${challenge.tag.replaceFirst('challenge_', '')}',
                dark: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final bool dark;

  const _HeroPill({
    this.icon,
    required this.label,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: dark
            ? Colors.white.withValues(alpha: 0.16)
            : Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
