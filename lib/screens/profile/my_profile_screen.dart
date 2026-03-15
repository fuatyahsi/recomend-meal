import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/community_recipe_model.dart';
import '../../models/badge_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_recipe_service.dart';
import '../../services/badge_service.dart';
import '../badges/badges_screen.dart';
import '../premium/premium_screen.dart';
import '../auth/login_screen.dart';
import '../../providers/app_provider.dart';
import '../cookbook/cookbooks_screen.dart';
import '../settings_screen.dart';

class MyProfileScreen extends StatefulWidget {
  const MyProfileScreen({super.key});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _recipeService = CommunityRecipeService();
  final _badgeService = BadgeService();

  List<CommunityRecipe> _myRecipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    try {
      _myRecipes = await _recipeService.getUserRecipes(auth.currentUser!.uid);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final isTr = AppLocalizations.of(context).languageCode == 'tr';

    if (!auth.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🔐', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(isTr ? 'Giriş yapmalısın' : 'Please sign in'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen())),
                child: Text(isTr ? 'Giriş Yap' : 'Sign In'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PremiumScreen()),
                ),
                icon: const Icon(Icons.workspace_premium, color: Colors.amber),
                label: Text(isTr ? 'Premium\'u Kesfet' : 'Explore Premium'),
              ),
            ],
          ),
        ),
      );
    }

    final user = auth.currentUser!;
    final badgeProgress = _badgeService.getBadgeProgress(user);
    final earnedBadges = AppBadge.allBadges
        .where((b) => user.badges.contains(b.id))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(isTr ? 'Profilim' : 'My Profile'),
        actions: [
          if (!(user.isPremium))
            IconButton(
              icon: const Icon(Icons.workspace_premium, color: Colors.amber),
              tooltip: isTr ? 'Premium' : 'Premium',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const PremiumScreen())),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar & Name
            CircleAvatar(
              radius: 44,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 36,
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(user.displayName,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold)),
            Text(user.email, style: theme.textTheme.bodyMedium),

            if (user.isPremium) ...[
              const SizedBox(height: 8),
              Chip(
                label: Text('Premium',
                    style: TextStyle(color: Colors.amber.shade800)),
                backgroundColor: Colors.amber.shade100,
                avatar: const Icon(Icons.star, color: Colors.amber, size: 18),
              ),
            ],

            const SizedBox(height: 24),

            // Stats Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _StatCard(
                  icon: Icons.restaurant_menu,
                  value: '${user.totalRecipesShared}',
                  label: isTr ? 'Tarif' : 'Recipes',
                  color: Colors.blue,
                ),
                _StatCard(
                  icon: Icons.favorite,
                  value: '${user.totalLikesReceived}',
                  label: isTr ? 'Beğeni' : 'Likes',
                  color: Colors.red,
                ),
                _StatCard(
                  icon: Icons.star,
                  value: '${user.totalRatingsGiven}',
                  label: isTr ? 'Puan' : 'Ratings',
                  color: Colors.amber,
                ),
                _StatCard(
                  icon: Icons.military_tech,
                  value: '${user.badges.length}',
                  label: isTr ? 'Rozet' : 'Badges',
                  color: Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tarif Defterlerim butonu
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const CookbooksScreen())),
                icon: const Icon(Icons.menu_book),
                label: Text(isTr ? 'Tarif Defterlerim' : 'My Cookbooks'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Badges section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isTr ? 'Rozetlerim' : 'My Badges',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                TextButton(
                  onPressed: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const BadgesScreen())),
                  child: Text(isTr ? 'Tümünü Gör' : 'See All'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (earnedBadges.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isTr
                      ? 'Henüz rozetin yok. Tarif paylaşarak rozet kazan!'
                      : 'No badges yet. Share recipes to earn badges!',
                  textAlign: TextAlign.center,
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: earnedBadges
                    .map((b) => Chip(
                          avatar: Text(b.icon, style: const TextStyle(fontSize: 18)),
                          label: Text(b.getName(isTr ? 'tr' : 'en')),
                        ))
                    .toList(),
              ),

            const SizedBox(height: 24),

            // My Recipes
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(isTr ? 'Tariflerim' : 'My Recipes',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                Text('${_myRecipes.length}',
                    style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 8),

            if (_isLoading)
              const CircularProgressIndicator()
            else if (_myRecipes.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isTr
                      ? 'Henüz tarif paylaşmadın'
                      : 'You haven\'t shared any recipes yet',
                  textAlign: TextAlign.center,
                ),
              )
            else
              ...(_myRecipes.map((r) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Text(r.imageEmoji,
                          style: const TextStyle(fontSize: 28)),
                      title: Text(r.getName(isTr ? 'tr' : 'en')),
                      subtitle: Row(
                        children: [
                          const Icon(Icons.favorite, size: 14, color: Colors.red),
                          const SizedBox(width: 4),
                          Text('${r.totalLikes}'),
                          const SizedBox(width: 12),
                          const Icon(Icons.star, size: 14, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(r.averageRating.toStringAsFixed(1)),
                        ],
                      ),
                    ),
                  ))),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(height: 6),
        Text(value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
