import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../models/community_recipe_model.dart';
import '../../models/badge_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../services/auth_service.dart';
import '../../services/community_recipe_service.dart';
import '../../services/follow_service.dart';
import '../community/community_recipe_detail_screen.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final _authService = AuthService();
  final _recipeService = CommunityRecipeService();
  final _followService = FollowService();

  AppUser? _user;
  List<CommunityRecipe> _recipes = [];
  bool _isFollowing = false;
  int _followerCount = 0;
  int _followingCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    try {
      final user = await _authService.getUserProfile(widget.userId);
      final recipes = await _recipeService.getUserRecipes(widget.userId);
      final followerCount = await _followService.getFollowerCount(widget.userId);
      final followingCount = await _followService.getFollowingCount(widget.userId);

      bool isFollowing = false;
      if (auth.isAuthenticated) {
        isFollowing = await _followService.isFollowing(
            auth.currentUser!.uid, widget.userId);
      }

      if (mounted) {
        setState(() {
          _user = user;
          _recipes = recipes;
          _isFollowing = isFollowing;
          _followerCount = followerCount;
          _followingCount = followingCount;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    final result = await _followService.toggleFollow(
        auth.currentUser!.uid, widget.userId);
    setState(() {
      _isFollowing = result;
      _followerCount += result ? 1 : -1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = context.read<AppProvider>().locale.languageCode == 'tr';
    final locale = isTr ? 'tr' : 'en';
    final auth = context.watch<AuthProvider>();
    final isOwnProfile = auth.currentUser?.uid == widget.userId;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(isTr ? 'Kullanıcı bulunamadı' : 'User not found'),
        ),
      );
    }

    final earnedBadges = AppBadge.allBadges
        .where((b) => _user!.badges.contains(b.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_user!.displayName),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            CircleAvatar(
              radius: 44,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                _user!.displayName.isNotEmpty
                    ? _user!.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 36,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(_user!.displayName,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),

            if (_user!.isPremium) ...[
              const SizedBox(height: 6),
              Chip(
                label: Text('Premium',
                    style: TextStyle(color: Colors.amber.shade800)),
                backgroundColor: Colors.amber.shade100,
                avatar: const Icon(Icons.star, color: Colors.amber, size: 18),
              ),
            ],

            const SizedBox(height: 16),

            // Takipçi / Takip / Tarif istatistikleri
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatColumn(
                  value: '$_followerCount',
                  label: isTr ? 'Takipçi' : 'Followers',
                ),
                _StatColumn(
                  value: '$_followingCount',
                  label: isTr ? 'Takip' : 'Following',
                ),
                _StatColumn(
                  value: '${_user!.totalRecipesShared}',
                  label: isTr ? 'Tarif' : 'Recipes',
                ),
                _StatColumn(
                  value: '${_user!.totalLikesReceived}',
                  label: isTr ? 'Beğeni' : 'Likes',
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Takip Et butonu
            if (!isOwnProfile)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _toggleFollow,
                  icon: Icon(
                    _isFollowing ? Icons.person_remove : Icons.person_add,
                    size: 20,
                  ),
                  label: Text(
                    _isFollowing
                        ? (isTr ? 'Takipten Çık' : 'Unfollow')
                        : (isTr ? 'Takip Et' : 'Follow'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isFollowing
                        ? theme.colorScheme.surfaceContainerHighest
                        : theme.colorScheme.primary,
                    foregroundColor: _isFollowing
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

            // Rozetler
            if (earnedBadges.isNotEmpty) ...[
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isTr ? 'Rozetler' : 'Badges',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: earnedBadges
                    .map((b) => Chip(
                          avatar: Text(b.icon,
                              style: const TextStyle(fontSize: 18)),
                          label: Text(b.getName(locale)),
                        ))
                    .toList(),
              ),
            ],

            // Tarifleri
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${isTr ? 'Tarifleri' : 'Recipes'} (${_recipes.length})',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),

            if (_recipes.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  isTr ? 'Henüz tarif paylaşmamış' : 'No recipes shared yet',
                  style: TextStyle(color: theme.colorScheme.outline),
                ),
              )
            else
              ..._recipes.map((recipe) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CommunityRecipeDetailScreen(recipe: recipe),
                        ),
                      ),
                      leading: Text(recipe.imageEmoji,
                          style: const TextStyle(fontSize: 28)),
                      title: Text(recipe.getName(locale)),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.favorite, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Text('${recipe.totalLikes}'),
                          const SizedBox(width: 12),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(recipe.averageRating.toStringAsFixed(1)),
                        ],
                      ),
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String value;
  final String label;

  const _StatColumn({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
