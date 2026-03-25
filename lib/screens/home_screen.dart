import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../models/recipe.dart';
import '../models/smart_actueller.dart';
import '../utils/app_theme.dart';
import '../utils/market_registry.dart';
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
import 'smart_actueller_screen.dart';
import 'smart_kitchen_screen.dart';
import 'vision_lab_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _heroController;
  late Animation<double> _heroScale;
  late Animation<double> _heroOpacity;
  bool _showAssistantSteps = false;
  bool _showHelperTools = false;
  bool _showKitchenJourney = false;
  final bool _showLegacyFeatureRows = false;
  String? _activeHomePanel;

  static const _categories = [
    {
      'id': 'breakfast',
      'emoji': '🍳',
      'tr': 'Kahvaltı',
      'en': 'Breakfast',
      'color': 0xFFFFF3E0
    },
    {
      'id': 'soup',
      'emoji': '🥣',
      'tr': 'Çorba',
      'en': 'Soup',
      'color': 0xFFE8F5E9
    },
    {
      'id': 'main',
      'emoji': '🍖',
      'tr': 'Ana Yemek',
      'en': 'Main',
      'color': 0xFFFFEBEE
    },
    {
      'id': 'appetizer',
      'emoji': '🥟',
      'tr': 'Meze',
      'en': 'Appetizer',
      'color': 0xFFE3F2FD
    },
    {
      'id': 'salad',
      'emoji': '🥗',
      'tr': 'Salata',
      'en': 'Salad',
      'color': 0xFFE8F5E9
    },
    {
      'id': 'dessert',
      'emoji': '🍰',
      'tr': 'Tatlı',
      'en': 'Dessert',
      'color': 0xFFFCE4EC
    },
    {
      'id': 'beverage',
      'emoji': '🥤',
      'tr': 'İçecek',
      'en': 'Beverage',
      'color': 0xFFE0F7FA
    },
    {
      'id': 'side',
      'emoji': '🍚',
      'tr': 'Garnitür',
      'en': 'Side',
      'color': 0xFFFFF8E1
    },
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
      CurvedAnimation(
          parent: _heroController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut)),
    );
    _heroController.forward();
  }

  @override
  void dispose() {
    _heroController.dispose();
    super.dispose();
  }

  void _toggleHomePanel(String panelId) {
    setState(() {
      _activeHomePanel = _activeHomePanel == panelId ? null : panelId;
    });
  }

  void _openCategory(
      BuildContext context, Map<String, dynamic> cat, String locale) {
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
    final featuredActuellerSuggestion =
        provider.smartActuellerSuggestions.isEmpty
            ? null
            : provider.smartActuellerSuggestions.first;
    final featuredMarketNames = provider
        .smartKitchenPreferences.preferredMarkets
        .map(displayNameForMarket)
        .where((name) => name.isNotEmpty)
        .take(4)
        .toList();
    final featuredBrochureCount = provider.lastActuellerCatalogBrochureCount;
    final featuredItemCount =
        provider.lastActuellerScanResult?.catalogItems.length ?? 0;

    final allRecipes = provider.recipeService.recipes;
    final popularRecipes =
        allRecipes.length > 8 ? allRecipes.sublist(0, 8) : allRecipes;

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
                  theme.colorScheme.primary.withValues(alpha: 0.03),
                  theme.colorScheme.surface,
                  theme.colorScheme.secondaryContainer.withValues(alpha: 0.05),
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
                                theme.colorScheme.primary
                                    .withValues(alpha: 0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: AppTheme.accentShadow,
                          ),
                          child: const Center(
                            child:
                                Text('🧑‍🍳', style: TextStyle(fontSize: 22)),
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
                            MaterialPageRoute(
                                builder: (_) => const PremiumScreen()),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.settings_outlined,
                              size: 22,
                              color: theme.colorScheme.onSurfaceVariant),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsScreen()),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 18)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _HomeFeaturedActuellerCard(
                      isTr: isTr,
                      suggestion: featuredActuellerSuggestion,
                      marketNames: featuredMarketNames,
                      brochureCount: featuredBrochureCount,
                      itemCount: featuredItemCount,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SmartActuellerScreen(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 14)),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _HomeQuickCard(
                                icon: Icons.auto_awesome_rounded,
                                title: isTr
                                    ? 'Akıllı Mutfak Asistanı'
                                    : 'Smart Kitchen Assistant',
                                subtitle: isTr
                                    ? 'Menünü kur, eksikleri gör'
                                    : 'Build your menu and review missing items',
                                gradientColors: [
                                  const Color(0xFF153B50),
                                  theme.colorScheme.primary,
                                ],
                                isSelected: _activeHomePanel == 'planner',
                                onTap: () => _toggleHomePanel('planner'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _HomeQuickCard(
                                icon: Icons.kitchen_outlined,
                                title: isTr
                                    ? 'Buzdolabında Ne Var?'
                                    : 'What is in your fridge?',
                                subtitle: isTr
                                    ? 'Dolabını güncel tut'
                                    : 'Keep your pantry updated',
                                gradientColors: const [
                                  Color(0xFF9A5B43),
                                  Color(0xFFE28B52),
                                ],
                                isSelected: _activeHomePanel == 'fridge',
                                onTap: () => _toggleHomePanel('fridge'),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _HomeQuickCard(
                                icon: Icons.widgets_outlined,
                                title:
                                    isTr ? 'Lezzet Atölyesi' : 'Flavor studio',
                                subtitle: isTr
                                    ? 'Pratik bölümler burada'
                                    : 'Useful sections in one place',
                                gradientColors: const [
                                  Color(0xFF101820),
                                  Color(0xFF274C77),
                                ],
                                isSelected: _activeHomePanel == 'tools',
                                onTap: () => _toggleHomePanel('tools'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _HomeQuickCard(
                                icon: Icons.emoji_events_outlined,
                                title: isTr ? 'Şef Karnem' : 'Chef scorecard',
                                subtitle: isTr
                                    ? 'Seviye ve haftalık durum'
                                    : 'Level and weekly progress',
                                gradientColors: const [
                                  Color(0xFF5F3B76),
                                  Color(0xFF9D6BCE),
                                ],
                                isSelected: _activeHomePanel == 'journey',
                                onTap: () => _toggleHomePanel('journey'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                if (_activeHomePanel != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: _HomeDetailShell(
                        child: switch (_activeHomePanel) {
                          'planner' => _PlannerDetailPanel(
                              isTr: isTr,
                              onOpen: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const SmartKitchenScreen(),
                                ),
                              ),
                            ),
                          'fridge' => _FridgeDetailPanel(
                              isTr: isTr,
                              selectedCount: provider.selectedCount,
                              selectedLabel: l10n
                                  .ingredientsSelected(provider.selectedCount),
                              findRecipesLabel: l10n.findRecipes,
                              onOpen: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const IngredientSelectionScreen(),
                                ),
                              ),
                            ),
                          'tools' => _ToolsDetailPanel(
                              isTr: isTr,
                              onOpenVision: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VisionLabScreen(),
                                ),
                              ),
                              onOpenMood: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MoodRecipesScreen(),
                                ),
                              ),
                              onOpenOrchestra: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const KitchenOrchestraScreen(),
                                ),
                              ),
                              onOpenRoulette: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RecipeRouletteScreen(),
                                ),
                              ),
                              onOpenFlavor: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FlavorDNAScreen(),
                                ),
                              ),
                            ),
                          _ => _JourneyDetailPanel(
                              isTr: isTr,
                              level: provider.kitchenRpgProfile.level,
                              levelTitle: provider.kitchenLevelTitle,
                              streakDays: provider.kitchenRpgProfile.streakDays,
                              monthlySavings: provider.monthlySavingsEstimate,
                              completedChallenges: provider
                                  .weeklyChallengeProgress
                                  .where((item) => item.completed)
                                  .length,
                            ),
                        },
                      ),
                    ),
                  ),
                if (_showLegacyFeatureRows)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _HomeExpandableCard(
                        icon: Icons.widgets_rounded,
                        title: isTr ? 'Yardımcı araçlar' : 'Helpful tools',
                        subtitle: isTr
                            ? 'İhtiyacın olduğunda aç. Her araç tek bir konuda yardım eder.'
                            : 'Open when needed. Each tool helps with one job.',
                        isExpanded: _showHelperTools,
                        onToggle: () => setState(
                          () => _showHelperTools = !_showHelperTools,
                        ),
                        child: Column(
                          children: [
                            _HomeToolLink(
                              icon: Icons.receipt_long_rounded,
                              title: isTr ? 'Fiş okut' : 'Scan receipt',
                              subtitle: isTr
                                  ? 'Fişteki ürünleri dolaba eklemeye yardımcı olur.'
                                  : 'Helps add receipt items to your pantry.',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VisionLabScreen(),
                                ),
                              ),
                            ),
                            _HomeToolLink(
                              icon: Icons.restaurant_rounded,
                              title: isTr
                                  ? 'Yemek fotoğrafını yorumla'
                                  : 'Analyze meal photo',
                              subtitle: isTr
                                  ? 'Yemeğin için hızlı yorum ve tahmin verir.'
                                  : 'Gives quick insight for your dish photo.',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const VisionLabScreen(),
                                ),
                              ),
                            ),
                            _HomeToolLink(
                              icon: Icons.favorite_border_rounded,
                              title: isTr
                                  ? 'Ruh haline göre tarif'
                                  : 'Recipes by mood',
                              subtitle: isTr
                                  ? 'Yorgun, hafif ya da pratik öneriler gör.'
                                  : 'Browse light or practical ideas.',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const MoodRecipesScreen(),
                                ),
                              ),
                            ),
                            _HomeToolLink(
                              icon: Icons.timer_outlined,
                              title: isTr
                                  ? 'Mutfak zamanlayıcısı'
                                  : 'Kitchen timers',
                              subtitle: isTr
                                  ? 'Birden fazla yemeği aynı anda takip et.'
                                  : 'Track multiple dishes at the same time.',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const KitchenOrchestraScreen(),
                                ),
                              ),
                            ),
                            _HomeToolLink(
                              icon: Icons.casino_outlined,
                              title: isTr
                                  ? 'Bugün ne pişirsem?'
                                  : 'What should I cook?',
                              subtitle: isTr
                                  ? 'Kararsız kalınca sana fikir verir.'
                                  : 'Helps when you cannot decide.',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RecipeRouletteScreen(),
                                ),
                              ),
                            ),
                            _HomeToolLink(
                              icon: Icons.auto_awesome_outlined,
                              title:
                                  isTr ? 'Damak zevkim' : 'My flavor profile',
                              subtitle: isTr
                                  ? 'Sana uygun tatları ve tarifleri gösterir.'
                                  : 'Shows flavors that match you.',
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const FlavorDNAScreen(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_showLegacyFeatureRows)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _SmartKitchenLauncherCard(
                        isTr: isTr,
                        isExpanded: _showAssistantSteps,
                        onToggleExpanded: () => setState(
                          () => _showAssistantSteps = !_showAssistantSteps,
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

                if (_showLegacyFeatureRows)
                  const SliverToBoxAdapter(child: SizedBox(height: 14)),

                if (_showLegacyFeatureRows)
                  const SliverToBoxAdapter(child: SizedBox(height: 2)),

                // ── Hero CTA - "Buzdolabında Ne Var?" ──
                if (_showLegacyFeatureRows)
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
                            MaterialPageRoute(
                                builder: (_) =>
                                    const IngredientSelectionScreen()),
                          ),
                        ),
                      ),
                    ),
                  ),

                // Selected ingredients badge
                if (_showLegacyFeatureRows && provider.selectedCount > 0)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: GlassCard(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        borderRadius: 14,
                        gradient: LinearGradient(
                          colors: [
                            theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.5,
                            ),
                            theme.colorScheme.primaryContainer.withValues(
                              alpha: 0.2,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.check_circle,
                                  size: 18, color: theme.colorScheme.primary),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                l10n.ingredientsSelected(
                                    provider.selectedCount),
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const IngredientSelectionScreen()),
                              ),
                              style: TextButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(l10n.findRecipes,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                if (_showLegacyFeatureRows)
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // ── Feature Buttons (Mood + Orchestra) ──
                if (_showHelperTools && _showLegacyFeatureRows)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _FeatureButton(
                              emoji: '💛',
                              title: isTr
                                  ? 'Ruh haline göre tarif'
                                  : 'Recipes by mood',
                              subtitle: isTr
                                  ? 'Nasıl hissediyorsun?'
                                  : 'How do you feel?',
                              gradientColors: const [
                                Color(0xFFE8D5F5),
                                Color(0xFFF3E5F5)
                              ],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const MoodRecipesScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FeatureButton(
                              emoji: '⏱️',
                              title: isTr
                                  ? 'Mutfak zamanlayıcısı'
                                  : 'Kitchen timers',
                              subtitle: isTr
                                  ? 'Birden fazla yemeği takip et'
                                  : 'Track multiple dishes',
                              gradientColors: const [
                                Color(0xFFFFE0B2),
                                Color(0xFFFFF3E0)
                              ],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const KitchenOrchestraScreen()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_showHelperTools && _showLegacyFeatureRows)
                  const SliverToBoxAdapter(child: SizedBox(height: 10)),

                // ── Feature Buttons Row 2 (Roulette + DNA) ──
                if (_showHelperTools && _showLegacyFeatureRows)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _FeatureButton(
                              emoji: '🍲',
                              title: isTr
                                  ? 'Bugün ne pişirsem?'
                                  : 'What should I cook?',
                              subtitle: isTr
                                  ? 'Kararsızsan sana fikir versin'
                                  : 'Helps when you cannot decide',
                              gradientColors: const [
                                Color(0xFFFFCDD2),
                                Color(0xFFFFEBEE)
                              ],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const RecipeRouletteScreen()),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _FeatureButton(
                              emoji: '✨',
                              title:
                                  isTr ? 'Damak zevkim' : 'My flavor profile',
                              subtitle: isTr
                                  ? 'Sana uyan tatları gösterir'
                                  : 'Shows your taste matches',
                              gradientColors: const [
                                Color(0xFFD1C4E9),
                                Color(0xFFEDE7F6)
                              ],
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const FlavorDNAScreen()),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                if (_showLegacyFeatureRows)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: _HomeExpandableCard(
                        icon: Icons.emoji_events_outlined,
                        title: isTr
                            ? 'Mutfaktaki ilerlemen'
                            : 'Your kitchen progress',
                        subtitle: isTr
                            ? '${provider.kitchenRpgProfile.streakDays} gündür devam ediyorsun. Ayrıntıları görmek için aç.'
                            : 'Open to see your streak and weekly progress.',
                        isExpanded: _showKitchenJourney,
                        onToggle: () => setState(
                          () => _showKitchenJourney = !_showKitchenJourney,
                        ),
                        child: _HomeJourneySummary(
                          isTr: isTr,
                          level: provider.kitchenRpgProfile.level,
                          levelTitle: provider.kitchenLevelTitle,
                          streakDays: provider.kitchenRpgProfile.streakDays,
                          monthlySavings: provider.monthlySavingsEstimate,
                          completedChallenges: provider.weeklyChallengeProgress
                              .where((item) => item.completed)
                              .length,
                        ),
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
                                  onTap: () =>
                                      _openCategory(context, cat, locale),
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
                                      builder: (_) =>
                                          RecipeDetailScreen(recipe: recipe),
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
                                  child: const Text('⚡',
                                      style: TextStyle(fontSize: 16)),
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
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
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
                              children:
                                  List.generate(quickRecipes.length, (index) {
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
                                                  RecipeDetailScreen(
                                                      recipe: recipe),
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
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(icon, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
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
                theme.colorScheme.primary.withValues(alpha: 0.8),
                const Color(0xFFFF8C42),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
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
                        color: Colors.white.withValues(alpha: 0.9),
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
                  color: Colors.white.withValues(alpha: 0.2),
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
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onTap;

  const _SmartKitchenLauncherCard({
    required this.isTr,
    required this.isExpanded,
    required this.onToggleExpanded,
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
                color: theme.colorScheme.primary.withValues(alpha: 0.18),
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
                      color: Colors.white.withValues(alpha: 0.14),
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
                          isTr
                              ? 'Menünü planla, eksikleri gör, sonra saatini ayarla'
                              : 'Build your menu first, then set times and reminders',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.86),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onToggleExpanded,
                    style: IconButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                    ),
                    icon: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(isTr ? 'Asistanı aç' : 'Open assistant'),
                ),
              ),
              if (isExpanded) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.14),
                    ),
                  ),
                  child: Column(
                    children: [
                      _HowItWorksStep(
                        number: 1,
                        text: isTr
                            ? 'Önce kahvaltı, öğle ve akşam için menünü oluştur.'
                            : 'Build your breakfast, lunch, and dinner menu.',
                      ),
                      const SizedBox(height: 10),
                      _HowItWorksStep(
                        number: 2,
                        text: isTr
                            ? 'Dolabındaki malzemeleri güncel tut.'
                            : 'Keep your pantry updated.',
                      ),
                      const SizedBox(height: 10),
                      _HowItWorksStep(
                        number: 3,
                        text: isTr
                            ? 'Eksikleri gör, alışveriş listesini çıkar ve hatırlatma kur.'
                            : 'Review missing items, create the shopping list, and set reminders.',
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
class _KitchenIntelHomeCard extends StatelessWidget {
  final bool isTr;
  final int level;
  final String levelTitle;
  final int streakDays;
  final double monthlySavings;
  final int completedChallenges;
  final VoidCallback onOpenVision;
  final VoidCallback onOpenSmartKitchen;

  const _KitchenIntelHomeCard({
    required this.isTr,
    required this.level,
    required this.levelTitle,
    required this.streakDays,
    required this.monthlySavings,
    required this.completedChallenges,
    required this.onOpenVision,
    required this.onOpenSmartKitchen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF101820),
            Color(0xFF274C77),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  isTr ? 'Kitchen RPG + AI katmani' : 'Kitchen RPG + AI layer',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Lv.$level',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            levelTitle,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HomeStatChip(
                label:
                    isTr ? '$streakDays gun streak' : '$streakDays day streak',
              ),
              _HomeStatChip(
                label: isTr
                    ? '$completedChallenges haftalik gorev'
                    : '$completedChallenges weekly challenges',
              ),
              _HomeStatChip(
                label: isTr
                    ? '${monthlySavings.round()} TL korundu'
                    : '${monthlySavings.round()} TRY saved',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isTr
                ? 'Fiş tarama, tabak analizi, zero-waste alarmi ve market karsilastirma ayni zeka katmanina baglandi.'
                : 'Receipt scan, plate analysis, zero-waste alerts, and market comparison now share the same intelligence layer.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenVision,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.28)),
                  ),
                  icon: const Icon(Icons.visibility_rounded),
                  label: Text(isTr ? 'Vision Lab' : 'Vision Lab'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onOpenSmartKitchen,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: theme.colorScheme.primary,
                  ),
                  icon: const Icon(Icons.auto_awesome),
                  label: Text(isTr ? 'Asistani ac' : 'Open assistant'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeFeaturedActuellerCard extends StatelessWidget {
  final bool isTr;
  final ActuellerSuggestion? suggestion;
  final List<String> marketNames;
  final int brochureCount;
  final int itemCount;
  final VoidCallback onTap;

  const _HomeFeaturedActuellerCard({
    required this.isTr,
    required this.suggestion,
    required this.marketNames,
    required this.brochureCount,
    required this.itemCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = isTr ? 'Markette Bugün Ne Ucuz?' : 'Today\'s Market Deals';
    final eyebrow = isTr ? 'Bu haftanın vitrini' : 'Featured this week';
    final description = suggestion == null
        ? (isTr
            ? 'Seçtiğin marketlerdeki indirimleri tek yerde topla. En uygun ürünleri açılır açılmaz gör.'
            : 'See the best offers across your selected markets as soon as the app opens.')
        : _trimText(
            suggestion!.body(isTr ? 'tr' : 'en'),
            maxLength: 132,
          );
    final heroLine = suggestion == null
        ? (isTr ? 'İndirimi kaçırma.' : 'Catch the best deals.')
        : suggestion!.title(isTr ? 'tr' : 'en');
    final chipLabels = <String>[
      if (brochureCount > 0)
        isTr ? '$brochureCount broşür' : '$brochureCount flyers',
      if (itemCount > 0) isTr ? '$itemCount ürün' : '$itemCount items',
      ...marketNames.take(3),
    ];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF4A1734),
                Color(0xFF982B4E),
                Color(0xFFE06C3C),
              ],
              stops: [0.0, 0.56, 1.0],
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF982B4E).withValues(alpha: 0.28),
                blurRadius: 36,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -18,
                top: -28,
                child: Container(
                  width: 128,
                  height: 128,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                left: -24,
                bottom: -36,
                child: Container(
                  width: 156,
                  height: 156,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFD28D).withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                right: 22,
                bottom: 22,
                child: Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.16),
                    ),
                    borderRadius: BorderRadius.circular(26),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.local_offer_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                eyebrow,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.16),
                            ),
                          ),
                          child: const Icon(
                            Icons.north_east_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.7,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      isTr
                          ? 'Seçtiğin marketlerde hangi ürün gerçekten uygun, ilk burada gör.'
                          : 'See which products are actually worth buying across your markets.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            heroLine,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.88),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: chipLabels
                          .map((label) => _HomeStatChip(label: label))
                          .toList(),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        FilledButton.icon(
                          onPressed: onTap,
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF7A1F3D),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 13,
                            ),
                          ),
                          icon: const Icon(Icons.storefront_rounded),
                          label: Text(
                            isTr ? 'İndirimleri Aç' : 'Open deals',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            isTr
                                ? 'Marketlerini seç, uygun ürünü hemen yakala.'
                                : 'Pick your stores and catch the best price fast.',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.84),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
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

  String _trimText(
    String input, {
    required int maxLength,
  }) {
    final compact = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (compact.length <= maxLength) {
      return compact;
    }
    return '${compact.substring(0, maxLength - 1).trimRight()}…';
  }
}

class _HomeQuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradientColors;
  final bool isSelected;
  final VoidCallback onTap;

  const _HomeQuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradientColors,
    required this.isSelected,
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
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(13),
          height: 136,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isSelected
                  ? gradientColors
                  : [
                      gradientColors[0].withValues(alpha: 0.92),
                      gradientColors[1].withValues(alpha: 0.82),
                    ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withValues(alpha: isSelected ? 0.18 : 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors.first.withValues(
                  alpha: isSelected ? 0.3 : 0.2,
                ),
                blurRadius: isSelected ? 18 : 14,
                offset: const Offset(0, 10),
                spreadRadius: -4,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                    ),
                    child: Icon(icon, color: Colors.white),
                  ),
                  const Spacer(),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.88),
                  height: 1.3,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeDetailShell extends StatelessWidget {
  final Widget child;

  const _HomeDetailShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _PlannerDetailPanel extends StatelessWidget {
  final bool isTr;
  final VoidCallback onOpen;

  const _PlannerDetailPanel({
    required this.isTr,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTr ? 'Akıllı Mutfak Asistanı' : 'Smart Kitchen Assistant',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isTr
              ? 'Önce kahvaltı, öğle ve akşam menünü kur. Sonra eksikleri görüp alışveriş listesini ve saatlerini ayarla.'
              : 'Build your meals first, then review missing items, shopping lists, and reminders.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        Column(
          children: [
            _StepRow(
              number: 1,
              text: isTr
                  ? 'Kahvaltı, öğle ve akşam için menü oluştur.'
                  : 'Build menus for breakfast, lunch, and dinner.',
            ),
            const SizedBox(height: 10),
            _StepRow(
              number: 2,
              text: isTr
                  ? 'Dolabındaki malzemelere göre eksikleri gör.'
                  : 'Review missing items based on your pantry.',
            ),
            const SizedBox(height: 10),
            _StepRow(
              number: 3,
              text: isTr
                  ? 'Alışveriş listeni ve hatırlatmalarını ayarla.'
                  : 'Set your shopping list and reminders.',
            ),
          ],
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.auto_awesome),
          label: Text(isTr ? 'Menüyü kur' : 'Open planning'),
        ),
      ],
    );
  }
}

class _FridgeDetailPanel extends StatelessWidget {
  final bool isTr;
  final int selectedCount;
  final String selectedLabel;
  final String findRecipesLabel;
  final VoidCallback onOpen;

  const _FridgeDetailPanel({
    required this.isTr,
    required this.selectedCount,
    required this.selectedLabel,
    required this.findRecipesLabel,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTr ? 'Buzdolabında Ne Var?' : 'What is in your fridge?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isTr
              ? 'Evde olanları seç. Uygulama sana uygun tarifleri ve eksiklerini göstersin.'
              : 'Select what you have at home and the app will show matching recipes.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(Icons.check_circle, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedCount > 0
                      ? selectedLabel
                      : (isTr
                          ? 'Henüz malzeme seçmedin'
                          : 'No ingredients selected yet'),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: onOpen,
          icon: const Icon(Icons.search_rounded),
          label: Text(
            selectedCount > 0
                ? findRecipesLabel
                : (isTr ? 'Dolabı güncelle' : 'Update pantry'),
          ),
        ),
      ],
    );
  }
}

class _ToolsDetailPanel extends StatelessWidget {
  final bool isTr;
  final VoidCallback onOpenVision;
  final VoidCallback onOpenMood;
  final VoidCallback onOpenOrchestra;
  final VoidCallback onOpenRoulette;
  final VoidCallback onOpenFlavor;

  const _ToolsDetailPanel({
    required this.isTr,
    required this.onOpenVision,
    required this.onOpenMood,
    required this.onOpenOrchestra,
    required this.onOpenRoulette,
    required this.onOpenFlavor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTr ? 'Lezzet Atölyesi' : 'Flavor studio',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isTr
              ? 'İhtiyacın olduğunda açabileceğin pratik bölümler burada.'
              : 'Practical sections you can open when needed.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        _HomeToolLink(
          icon: Icons.receipt_long_rounded,
          title: isTr ? 'Fiş okut' : 'Scan receipt',
          subtitle: isTr
              ? 'Fişteki ürünleri dolaba eklemeye yardımcı olur.'
              : 'Helps add receipt items to your pantry.',
          onTap: onOpenVision,
        ),
        _HomeToolLink(
          icon: Icons.favorite_border_rounded,
          title: isTr ? 'Ruh haline göre tarif' : 'Recipes by mood',
          subtitle: isTr
              ? 'Yorgun ya da pratik günler için öneriler gör.'
              : 'See ideas for tired or practical days.',
          onTap: onOpenMood,
        ),
        _HomeToolLink(
          icon: Icons.timer_outlined,
          title: isTr ? 'Mutfak zamanlayıcısı' : 'Kitchen timers',
          subtitle: isTr
              ? 'Birden fazla yemeği aynı anda takip et.'
              : 'Track multiple dishes at the same time.',
          onTap: onOpenOrchestra,
        ),
        _HomeToolLink(
          icon: Icons.casino_outlined,
          title: isTr ? 'Bugün ne pişirsem?' : 'What should I cook?',
          subtitle: isTr
              ? 'Kararsız kaldığında sana fikir verir.'
              : 'Helps when you cannot decide.',
          onTap: onOpenRoulette,
        ),
        _HomeToolLink(
          icon: Icons.auto_awesome_outlined,
          title: isTr ? 'Damak zevkim' : 'My flavor profile',
          subtitle: isTr
              ? 'Sana uygun tatları ve tarifleri gösterir.'
              : 'Shows flavors and meals that fit you.',
          onTap: onOpenFlavor,
        ),
      ],
    );
  }
}

class _JourneyDetailPanel extends StatelessWidget {
  final bool isTr;
  final int level;
  final String levelTitle;
  final int streakDays;
  final double monthlySavings;
  final int completedChallenges;

  const _JourneyDetailPanel({
    required this.isTr,
    required this.level,
    required this.levelTitle,
    required this.streakDays,
    required this.monthlySavings,
    required this.completedChallenges,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isTr ? 'Şef Karnem' : 'Chef scorecard',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isTr
              ? 'Yaptığın planlar, devam günlerin ve biriken kazanımlar burada görünür.'
              : 'Your streak, planning progress, and wins appear here.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 14),
        _HomeJourneySummary(
          isTr: isTr,
          level: level,
          levelTitle: levelTitle,
          streakDays: streakDays,
          monthlySavings: monthlySavings,
          completedChallenges: completedChallenges,
        ),
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final String text;

  const _StepRow({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.35,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _HowItWorksStep extends StatelessWidget {
  final int number;
  final String text;

  const _HowItWorksStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(999),
          ),
          alignment: Alignment.center,
          child: Text(
            '$number',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _HomeExpandableCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isExpanded;
  final VoidCallback onToggle;
  final Widget? child;

  const _HomeExpandableCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isExpanded,
    required this.onToggle,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(
                      alpha: 0.65,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (isExpanded && child != null) ...[
            const SizedBox(height: 14),
            child!,
          ],
        ],
      ),
    );
  }
}

class _HomeToolLink extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _HomeToolLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: theme.colorScheme.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeJourneySummary extends StatelessWidget {
  final bool isTr;
  final int level;
  final String levelTitle;
  final int streakDays;
  final double monthlySavings;
  final int completedChallenges;

  const _HomeJourneySummary({
    required this.isTr,
    required this.level,
    required this.levelTitle,
    required this.streakDays,
    required this.monthlySavings,
    required this.completedChallenges,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Lv.$level',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                levelTitle,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _SoftStatChip(
              label: isTr ? '$streakDays gün devam' : '$streakDays day streak',
            ),
            _SoftStatChip(
              label: isTr
                  ? '$completedChallenges görev tamam'
                  : '$completedChallenges done',
            ),
            _SoftStatChip(
              label: isTr
                  ? '${monthlySavings.round()} TL korundu'
                  : '${monthlySavings.round()} TRY saved',
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          isTr
              ? 'Yaptığın planlar ve dolap güncellemeleri burada birikir. İstersen bunu sadece ara sıra kontrol etmen yeterli.'
              : 'Your planning and pantry updates build up here. You only need to check this once in a while.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}

class _SoftStatChip extends StatelessWidget {
  final String label;

  const _SoftStatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HomeStatChip extends StatelessWidget {
  final String label;

  const _HomeStatChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
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
                      color: gradientColors[1].withValues(alpha: 0.4),
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
                      gradientColors[1].withValues(alpha: 0.6),
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
                          color: Colors.black.withValues(alpha: 0.05),
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
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
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
                          color: _getDifficultyColor(recipe.difficulty)
                              .withValues(alpha: 0.9),
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
                color: gradientColors[0].withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: gradientColors[0].withValues(alpha: 0.5),
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
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
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
                  child: Text(recipe.imageEmoji,
                      style: const TextStyle(fontSize: 22)),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
