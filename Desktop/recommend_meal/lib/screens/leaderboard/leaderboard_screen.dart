import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/user_model.dart';
import '../../models/community_recipe_model.dart';
import '../../services/leaderboard_service.dart';
import '../../widgets/banner_ad_widget.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  final _leaderboardService = LeaderboardService();
  late TabController _tabController;

  List<AppUser> _topSharers = [];
  List<AppUser> _mostLiked = [];
  List<CommunityRecipe> _topRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _leaderboardService.getTopSharers(),
        _leaderboardService.getMostLikedUsers(),
        _leaderboardService.getMostLikedRecipes(),
      ]);
      _topSharers = results[0] as List<AppUser>;
      _mostLiked = results[1] as List<AppUser>;
      _topRecipes = results[2] as List<CommunityRecipe>;
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isTr = AppLocalizations.of(context).languageCode == 'tr';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTr ? 'Sıralama' : 'Leaderboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: isTr ? 'En Çok Paylaşan' : 'Top Sharers'),
            Tab(text: isTr ? 'En Beğenilen' : 'Most Liked'),
            Tab(text: isTr ? 'En İyi Tarifler' : 'Top Recipes'),
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
                      _UserLeaderboard(
                        users: _topSharers,
                        statGetter: (u) => '${u.totalRecipesShared} ${isTr ? "tarif" : "recipes"}',
                        icon: Icons.restaurant_menu,
                        emptyText: isTr ? 'Henüz veri yok' : 'No data yet',
                      ),
                      _UserLeaderboard(
                        users: _mostLiked,
                        statGetter: (u) => '${u.totalLikesReceived} ${isTr ? "beğeni" : "likes"}',
                        icon: Icons.favorite,
                        emptyText: isTr ? 'Henüz veri yok' : 'No data yet',
                      ),
                      _RecipeLeaderboard(
                        recipes: _topRecipes,
                        isTr: isTr,
                      ),
                    ],
                  ),
          ),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}

class _UserLeaderboard extends StatelessWidget {
  final List<AppUser> users;
  final String Function(AppUser) statGetter;
  final IconData icon;
  final String emptyText;

  const _UserLeaderboard({
    required this.users,
    required this.statGetter,
    required this.icon,
    required this.emptyText,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return Center(child: Text(emptyText));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: users.length,
      itemBuilder: (context, index) {
        final user = users[index];
        final rank = index + 1;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: SizedBox(
              width: 44,
              child: Center(
                child: rank <= 3
                    ? Text(
                        rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
                        style: const TextStyle(fontSize: 28),
                      )
                    : Text('#$rank',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            title: Text(user.displayName,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Row(
              children: [
                if (user.badges.isNotEmpty)
                  ...user.badges.take(3).map((b) {
                    final badge = _getBadgeEmoji(b);
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(badge, style: const TextStyle(fontSize: 14)),
                    );
                  }),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 4),
                Text(statGetter(user),
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getBadgeEmoji(String badgeId) {
    switch (badgeId) {
      case 'first_recipe': return '🍳';
      case 'chef_5': return '👨‍🍳';
      case 'master_chef': return '🏆';
      case 'legend_chef': return '👑';
      case 'liked_10': return '⭐';
      case 'popular_50': return '🌟';
      case 'superstar': return '💎';
      case 'critic_10': return '📊';
      case 'critic_50': return '🎯';
      default: return '🏅';
    }
  }
}

class _RecipeLeaderboard extends StatelessWidget {
  final List<CommunityRecipe> recipes;
  final bool isTr;

  const _RecipeLeaderboard({required this.recipes, required this.isTr});

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return Center(child: Text(isTr ? 'Henüz veri yok' : 'No data yet'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: recipes.length,
      itemBuilder: (context, index) {
        final recipe = recipes[index];
        final rank = index + 1;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: SizedBox(
              width: 44,
              child: Center(
                child: rank <= 3
                    ? Text(
                        rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉',
                        style: const TextStyle(fontSize: 28))
                    : Text('#$rank',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
              ),
            ),
            title: Text(recipe.getName(isTr ? 'tr' : 'en'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
                '${isTr ? "Paylaşan" : "By"}: ${recipe.userDisplayName}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Text('${recipe.totalLikes}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      },
    );
  }
}
