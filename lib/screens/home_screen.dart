import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../models/recipe.dart';
import '../utils/app_theme.dart';
import '../widgets/glass_container.dart';
import 'ingredient_selection_screen.dart';
import 'category_recipes_screen.dart';
import 'recipe_detail_screen.dart';
import 'mood_recipes_screen.dart';
import 'kitchen_orchestra_screen.dart';
import 'recipe_roulette_screen.dart';
import 'flavor_dna_screen.dart';
import 'settings_screen.dart';
import 'premium/premium_screen.dart';
import 'smart_kitchen_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _heroController;
  late Animation<double> _heroScale;
  late Animation<double> _heroOpacity;

  static const _categories = [
    {'id': 'breakfast', 'emoji': '🍳', 'tr': 'Kahvaltı', 'en': 'Breakfast', 'color': 0xFFFFF3E0},
    {'id': 'soup', 'emoji': '🥣', 'tr': 'Çorba', 'en': 'Soup', 'color': 0xFFE8F5E9},
    {'id': 'main', 'emoji': '🍖', 'tr': 'Ana Yemek', 'en': 'Main', 'color': 0xFFFFEBEE},
    {'id': 'appetizer', 'emoji': '🥟', 'tr': 'Meze', 'en': 'Appetizer', 'color': 0xFFE3F2FD},
    {'id': 'salad', 'emoji': '🥗', 'tr': 'Salata', 'en': 'Salad', 'color': 0xFFE8F5E9},
    {'id': 'dessert', 'emoji': '🍰', 'tr': 'Tatlı', 'en': 'Dessert', 'color': 0xFFFCE4EC},
    {'id': 'beverage', 'emoji': '🥤', 'tr': 'İçecek', 'en': 'Beverage', 'color': 0xFFE0F7FA},
    {'id': 'side', 'emoji': '🍚', 'tr': 'Garnitür', 'en': 'Side', 'color': 0xFFFFF8E1},
  ];

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _heroScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: Curves.elasticOut),
    );
    _heroOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _heroController, curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _heroController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  void _openCategory(BuildContext context, Map<String, dynamic> cat, String locale) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryRecipesScreen(
          categoryId: cat['id'] as String,
          categoryName: (locale == 'tr' ? cat['tr'] : cat['en']) as String,
          categoryEmoji: cat['emoji'] as String,
        ),
      ),
    );
  }

  void _openAllRecipes(BuildContext context, String locale) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategoryRecipesScreen(
          categoryId: 'all',
          categoryName: locale == 'tr' ? 'Tüm Tarifler' : 'All Recipes',
          categoryEmoji: '📋',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = provider.languageCode;
    final isTr = locale == 'tr';
    final isPremium = context.watch<AuthProvider>().isPremium;
    final nextMealId = provider.getNextPlannedMealId();
    final nextMealRecipes = provider.getPlannedRecipes(nextMealId);
    final plannedMissingCount = provider.getPlannedShoppingSummary().length;
    final plannedMenuCount = provider.getPlannedMenuCount();
    final plannedMealCount = provider.getPlannedMealCount();
    final nextReminder = provider.nextReminderPreview;

    final allRecipes = provider.recipeService.recipes;
    final popularRecipes = allRecipes.length > 8 ? allRecipes.sublist(0, 8) : allRecipes;

    return Scaffold(
      body: Stack(
        children: [
          // Subtle background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  theme.colorScheme.primary.withOpacity(0.03),
                  theme.colorScheme.surface,
                  theme.colorScheme.secondaryContainer.withOpacity(0.05),
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),

          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // ── Top Bar ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                    child: Row(
                      children: [
                        // Animated logo
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                theme.colorScheme.primary,
                                theme.colorScheme.primary.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppTheme.accentShadow,
                          ),
                          child: const Center(
                            child: Text('🧑‍🍳', style: TextStyle(fontSize: 22)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.appName,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: theme.colorScheme.primary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                l10n.appTagline,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _AnimatedIconButton(
                          icon: locale == 'tr' ? '🇬🇧' : '🇹🇷',
                          label: locale == 'tr' ? 'EN' : 'TR',
                          onTap: () => provider.toggleLanguage(),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: Icon(
                            isPremium
                                ? Icons.workspace_premium
                                : Icons.workspace_premium_outlined,
                            size: 22,
                            color: Colors.amber.shade700,
                          ),
                          tooltip: isTr ? 'Premium' : 'Premium',
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PremiumScreen()),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.settings_outlined,
                              size: 22, color: theme.colorScheme.onSurfaceVariant),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SettingsScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _SmartKitchenLauncherCard(
                      isTr: isTr,
                      nextMealLabel: provider.getPlannerMealLabel(nextMealId),
                      nextRecipeName: nextMealRecipes.isEmpty
                          ? null
                          : nextMealRecipes.first.getName(locale),
                      plannedMenuCount: plannedMenuCount,
                      plannedMealCount: plannedMealCount,
                      missingCount:
                          plannedMenuCount == 0 ? 0 : plannedMissingCount,
                      pantryCount: provider.selectedCount,
                      reminderText: nextReminder == null
                          ? null
                          : MaterialLocalizations.of(context).formatTimeOfDay(
                              TimeOfDay(
                                hour: nextReminder.remindAt.hour,
                                minute: nextReminder.remindAt.minute,
                              ),
                              alwaysUse24HourFormat: true,
                            ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SmartKitchenScreen(),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // ── Hero CTA - "Buzdolabında Ne Var?" ──
                SliverToBoxAdapter(
                  child: AnimatedBuilder(
                    animation: _heroController,
                    builder: (context, child) => Opacity(
                      opacity: _heroOpacity.value,
                      child: Transform.scale(
                        scale: _heroScale.value,
                        child: child,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _HeroCTACard(
                        isTr: isTr,
                        selectedCount: provider.selectedCount,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const IngredientSelectionScreen()),
                        ),
                      ),
                    ),
                  ),
                ),

                // Selected ingredients badge
                if (provider.selectedCount > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        borderRadius: 14,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primaryContainer.withOpacity(0.5),
                            theme.colorScheme.primaryContainer.withOpacity(0.2),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.check_circle,
                                  size: 18, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.ingredientsSelected(provider.selectedCount),
                                style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const IngredientSelectionScreen()),
                              ),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(l10n.findRecipes,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── Feature Buttons (Mood + Orchestra) ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _FeatureButton(
                            emoji: '🎭',
                            title: isTr ? 'Ruh Haline Göre' : 'By Mood',
                            subtitle: isTr ? 'Nasıl hissediyorsun?' : 'How do you feel?',
                            gradientColors: const [Color(0xFFE8D5F5), Color(0xFFF3E5F5)],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const MoodRecipesScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FeatureButton(
                            emoji: '🎼',
                            title: isTr ? 'Mutfak Orkestra' : 'Kitchen Orchestra',
                            subtitle: isTr ? 'Çoklu zamanlayıcı' : 'Multi-timer',
                            gradientColors: const [Color(0xFFFFE0B2), Color(0xFFFFF3E0)],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const KitchenOrchestraScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // ── Feature Buttons Row 2 (Roulette + DNA) ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: _FeatureButton(
                            emoji: '🎰',
                            title: isTr ? 'Ne Pişirsem?' : 'What to Cook?',
                            subtitle: isTr ? 'Rulet + Tarif Duellosu' : 'Roulette + Recipe Duel',
                            gradientColors: const [Color(0xFFFFCDD2), Color(0xFFFFEBEE)],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RecipeRouletteScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _FeatureButton(
                            emoji: '🧬',
                            title: isTr ? 'Lezzet DNA\'sı' : 'Flavor DNA',
                            subtitle: isTr ? 'Profil analizi' : 'Profile analysis',
                            gradientColors: const [Color(0xFFD1C4E9), Color(0xFFEDE7F6)],
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const FlavorDNAScreen()),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),

                // ── Kategoriler ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isTr ? 'Kategoriler' : 'Categories',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _openAllRecipes(context, locale),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isTr ? 'Tümünü Gör' : 'See All',
                                style: TextStyle(
                                    fontSize: 13,
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 2),
                              Icon(Icons.arrow_forward_ios,
                                  size: 12, color: theme.colorScheme.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 12)),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 108,
                    child: AnimationLimiter(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final cat = _categories[index];
                          final count = provider.recipeService
                              .getRecipesByCategory(cat['id'] as String)
                              .length;
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 400),
                            child: SlideAnimation(
                              horizontalOffset: 50.0,
                              child: FadeInAnimation(
                                child: _CategoryChip(
                                  cat: cat,
                                  count: count,
                                  locale: locale,
                                  onTap: () => _openCategory(context, cat, locale),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),

                // ── Öne Çıkan Tarifler ──
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 4,
                              height: 20,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isTr ? 'Öne Çıkanlar' : 'Popular Recipes',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => _openAllRecipes(context, locale),
                          child: Text(
                            isTr ? 'Tümünü Gör' : 'See All',
                            style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 10)),

                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 210,
                    child: AnimationLimiter(
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: popularRecipes.length,
                        itemBuilder: (context, index) {
                          final recipe = popularRecipes[index];
                          return AnimationConfiguration.staggeredList(
                            position: index,
                            duration: const Duration(milliseconds: 450),
                            child: SlideAnimation(
                              horizontalOffset: 60.0,
                              child: FadeInAnimation(
                                child: _PopularRecipeCard(
                                  recipe: recipe,
                                  locale: locale,
                                  index: index,
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
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 28)),

                // ── Hızlı Tarifler ──
                SliverToBoxAdapter(
                  child: Builder(
                    builder: (context) {
                      final quickRecipes = allRecipes
                          .where((r) => r.totalTimeMinutes <= 20)
                          .take(6)
                          .toList();
                      if (quickRecipes.isEmpty) return const SizedBox.shrink();
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text('⚡', style: TextStyle(fontSize: 16)),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isTr ? 'Hızlı Tarifler' : 'Quick Recipes',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '≤ 20 ${isTr ? "dk" : "min"}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.green.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimationLimiter(
                            child: Column(
                              children: List.generate(quickRecipes.length, (index) {
                                final recipe = quickRecipes[index];
                                return AnimationConfiguration.staggeredList(
                                  position: index,
                                  duration: const Duration(milliseconds: 375),
                                  child: SlideAnimation(
                                    verticalOffset: 30.0,
                                    child: FadeInAnimation(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20, vertical: 4),
                                        child: _QuickRecipeTile(
                                          recipe: recipe,
                                          locale: locale,
                                          onTap: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  RecipeDetailScreen(recipe: recipe),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 32)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Animated Language Toggle ──
class _AnimatedIconButton extends StatelessWidget {
  final String icon;
  final String label;
  final VoidCallback onTap;

  const _AnimatedIconButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Hero CTA Card with glassmorphism ──
class _HeroCTACard extends StatelessWidget {
  final bool isTr;
  final int selectedCount;
  final VoidCallback onTap;

  const _HeroCTACard({
    required this.isTr,
    required this.selectedCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
                const Color(0xFFFF8C42),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            children: [
              // Glass icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Text('🧊', style: TextStyle(fontSize: 30)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTr ? 'Buzdolabında Ne Var?' : "What's in Your Fridge?",
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTr
                          ? 'Malzemelerini seç, sana tarif bulalım'
                          : 'Select ingredients, we\'ll find recipes',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 18,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Category Chip - Glass Style ──
class _SmartKitchenLauncherCard extends StatelessWidget {
  final bool isTr;
  final String nextMealLabel;
  final String? nextRecipeName;
  final int plannedMenuCount;
  final int plannedMealCount;
  final int missingCount;
  final int pantryCount;
  final String? reminderText;
  final VoidCallback onTap;

  const _SmartKitchenLauncherCard({
    required this.isTr,
    required this.nextMealLabel,
    required this.nextRecipeName,
    required this.plannedMenuCount,
    required this.plannedMealCount,
    required this.missingCount,
    required this.pantryCount,
    required this.reminderText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF153B50),
                theme.colorScheme.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTr
                              ? 'Akıllı Mutfak Asistanı'
                              : 'Smart Kitchen Assistant',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reminderText == null
                              ? (isTr
                                  ? '$nextMealLabel için menünü oluştur'
                                  : 'Build your menu for $nextMealLabel')
                              : (isTr
                                  ? '$nextMealLabel için $reminderText hatırlatması hazır'
                                  : '$reminderText reminder ready for $nextMealLabel'),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withOpacity(0.86),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Colors.white),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                plannedMenuCount == 0
                    ? (isTr
                        ? 'Önce kahvaltı, öğle ve akşam için menünü oluştur. Sonra süreleri ve hatırlatmaları birlikte hazırlayalım.'
                        : 'Create menus for breakfast, lunch, and dinner first. Then let us prepare timings and reminders.')
                    : (isTr
                        ? '$plannedMealCount öğünde $plannedMenuCount tarif planlandı${nextRecipeName == null ? '' : '. Sıradaki tarif: $nextRecipeName'}'
                        : '$plannedMenuCount recipes are planned across $plannedMealCount meals${nextRecipeName == null ? '' : '. Next up: $nextRecipeName'}'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _HomeBadge(
                    icon: Icons.restaurant_outlined,
                    label: nextMealLabel,
                  ),
                  _HomeBadge(
                    icon: Icons.shopping_bag_outlined,
                    label: isTr
                        ? plannedMenuCount == 0
                            ? 'Önce menü seç'
                            : '$missingCount eksik ürün'
                        : plannedMenuCount == 0
                            ? 'Choose menus first'
                            : '$missingCount missing items',
                  ),
                  _HomeBadge(
                    icon: Icons.kitchen_outlined,
                    label: isTr
                        ? 'Dolap: $pantryCount malzeme'
                        : 'Pantry: $pantryCount items',
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

class _HomeBadge extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HomeBadge({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
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

class _CategoryChip extends StatelessWidget {
  final Map<String, dynamic> cat;
  final int count;
  final String locale;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.cat,
    required this.count,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = locale == 'tr';
    final catId = cat['id'] as String;
    final gradientColors = AppTheme.categoryGradients[catId] ??
        [const Color(0xFFEEEEEE), const Color(0xFFE0E0E0)];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: onTap,
        child: SizedBox(
          width: 80,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: gradientColors[1].withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    cat['emoji'] as String,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${isTr ? cat['tr'] : cat['en']}',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '($count)',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Popular Recipe Card - Enhanced ──
class _PopularRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final String locale;
  final int index;
  final VoidCallback onTap;

  const _PopularRecipeCard({
    required this.recipe,
    required this.locale,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gradientColors = AppTheme.categoryGradients[recipe.category] ??
        [const Color(0xFFF5F5F5), const Color(0xFFE0E0E0)];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 155,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top section with emoji & gradient
              Container(
                height: 110,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      gradientColors[0],
                      gradientColors[1].withOpacity(0.6),
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Stack(
                  children: [
                    // Background pattern emoji (subtle)
                    Positioned(
                      right: -8,
                      bottom: -8,
                      child: Text(
                        recipe.imageEmoji,
                        style: TextStyle(
                          fontSize: 48,
                          color: Colors.black.withOpacity(0.05),
                        ),
                      ),
                    ),
                    // Main emoji
                    Center(
                      child: Text(
                        recipe.imageEmoji,
                        style: const TextStyle(fontSize: 44),
                      ),
                    ),
                    // Time badge
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.schedule,
                                size: 10, color: theme.colorScheme.primary),
                            const SizedBox(width: 3),
                            Text(
                              '${recipe.totalTimeMinutes}\'',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Difficulty badge
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor(recipe.difficulty).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          recipe.getDifficultyText(locale),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Bottom section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.getName(locale),
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Icon(Icons.restaurant_outlined,
                              size: 12, color: theme.colorScheme.outline),
                          const SizedBox(width: 3),
                          Text(
                            '${recipe.servings} ${locale == 'tr' ? 'kişilik' : 'serv.'}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.outline,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
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


// ── Feature Button (Mood / Orchestra) ──
class _FeatureButton extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const _FeatureButton({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: gradientColors[0].withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Quick Recipe Tile - Enhanced ──
class _QuickRecipeTile extends StatelessWidget {
  final Recipe recipe;
  final String locale;
  final VoidCallback onTap;

  const _QuickRecipeTile({
    required this.recipe,
    required this.locale,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              // Emoji container with gradient
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: AppTheme.categoryGradients[recipe.category] ??
                        [const Color(0xFFF5F5F5), const Color(0xFFE0E0E0)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(recipe.imageEmoji, style: const TextStyle(fontSize: 22)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recipe.getName(locale),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${recipe.servings} ${locale == 'tr' ? 'kişilik' : 'servings'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, size: 13, color: Colors.green.shade700),
                    const SizedBox(width: 2),
                    Text(
                      '${recipe.totalTimeMinutes}\'',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right,
                  size: 18, color: theme.colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
