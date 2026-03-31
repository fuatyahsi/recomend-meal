import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/kitchen_intelligence.dart';
import '../providers/app_provider.dart';
import '../providers/auth_provider.dart';
import '../services/smart_actueller_source_service.dart';
import '../utils/app_theme.dart';
import '../utils/market_registry.dart';
import '../utils/text_repair.dart';
import 'chef_scorecard_screen.dart';
import 'community/community_hub_screen.dart';
import 'flavor_studio_hub_screen.dart';
import 'ingredient_selection_screen.dart';
import 'premium/premium_screen.dart';
import 'settings_screen.dart';
import 'smart_actueller_screen.dart';
import 'smart_kitchen_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<void> _openActuellerFlow() async {
    final shouldOpen = await showModalBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Consumer<AppProvider>(
          builder: (context, provider, _) {
            final theme = Theme.of(context);
            final isTr = provider.languageCode == 'tr';
            final selectedIds =
                provider.smartKitchenPreferences.preferredMarkets.toSet();

            return Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    isTr ? 'Önce marketini seç' : 'Pick your markets first',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isTr
                        ? 'Marketleri işaretle, sonra kampanyalı ürünleri getirelim.'
                        : 'Select stores first, then load the deal products.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SmartActuellerSourceService.availableMarkets
                        .map((market) {
                      final isSelected = selectedIds.contains(market.id);
                      return FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        avatar: Text(market.emoji),
                        label: Text(market.name),
                        selectedColor: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.7),
                        onSelected: (_) =>
                            provider.togglePreferredMarket(market.id),
                      );
                    }).toList(),
                  ),
                  if (selectedIds.isEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      isTr
                          ? 'Devam etmek için en az bir market seç.'
                          : 'Select at least one market to continue.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: selectedIds.isEmpty
                          ? null
                          : () => Navigator.pop(sheetContext, true),
                      icon: const Icon(Icons.storefront_rounded),
                      label:
                          Text(isTr ? 'Ürünleri getir' : 'Load the products'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (!mounted || shouldOpen != true) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SmartActuellerScreen(autoSyncOnOpen: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isTr = provider.languageCode == 'tr';
    final tickerEntries = provider.officialPriceTickerEntries;
    final marketFiyatiLocationLabel = provider.marketFiyatiLocationLabel;
    final marketNames = provider.smartKitchenPreferences.preferredMarkets
        .map(displayNameForMarket)
        .where((name) => name.isNotEmpty)
        .take(2)
        .toList();
    final dealsBody = marketFiyatiLocationLabel == null ||
            marketFiyatiLocationLabel.trim().isEmpty
        ? (isTr
            ? 'Konumunu seç, yakındaki marketlerde gerçekten ucuz olan ürünleri görelim.'
            : 'Pick your location first and we will show the truly cheap nearby items.')
        : marketNames.isEmpty
            ? repairTurkishText(marketFiyatiLocationLabel)
            : '${repairTurkishText(marketFiyatiLocationLabel)} • ${marketNames.join(' • ')}';

    final cards = [
      _HomeCardData(
        keyId: 'deals',
        gradientColors: const [
          Color(0xFF4A1734),
          Color(0xFF982B4E),
          Color(0xFFE06C3C),
        ],
        eyebrow: isTr ? 'Bugünün fırsatları' : 'Today’s deals',
        title: isTr ? 'Bugün Markette Ne Ucuz?' : 'Best market deals today',
        body: dealsBody,
        swipeHint:
            isTr ? 'Sağa kaydır, indirimleri aç' : 'Swipe right to open deals',
        icon: Icons.style_rounded,
        onOpen: _openActuellerFlow,
      ),
      _HomeCardData(
        keyId: 'assistant',
        gradientColors: const [
          Color(0xFF10324A),
          Color(0xFF1D6F8C),
          Color(0xFF48A49F),
        ],
        eyebrow: isTr ? 'Akıllı plan' : 'Smart planning',
        title: isTr ? 'Akıllı Mutfak Asistanı' : 'Smart Kitchen Assistant',
        body: isTr
            ? 'Ne pişeceğini seç, eksikleri ve tasarrufu aynı yerde gör.'
            : 'Plan meals, missing items, and savings in one place.',
        swipeHint: isTr ? 'Sağa kaydır, asistanı aç' : 'Swipe right to open',
        icon: Icons.psychology_alt_rounded,
        onOpen: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SmartKitchenScreen()),
          );
        },
      ),
      _HomeCardData(
        keyId: 'fridge',
        gradientColors: const [
          Color(0xFF6C3F2C),
          Color(0xFFB76A3E),
          Color(0xFFF0B36A),
        ],
        eyebrow: isTr ? 'Eldekini kullan' : 'Use what you have',
        title: isTr ? 'Buzdolabında Ne Var?' : 'What’s in your fridge?',
        body: isTr
            ? 'Dolaptakilerle tarif bul, israfı azalt.'
            : 'Find recipes with what you already have and reduce waste.',
        swipeHint: isTr ? 'Sağa kaydır, dolabı aç' : 'Swipe right to open',
        icon: Icons.inventory_2_rounded,
        onOpen: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const IngredientSelectionScreen(),
            ),
          );
        },
      ),
      _HomeCardData(
        keyId: 'studio',
        gradientColors: const [
          Color(0xFF1B2430),
          Color(0xFF3A4F7A),
          Color(0xFF7A9CC6),
        ],
        eyebrow: isTr ? 'Pratik araçlar' : 'Useful tools',
        title: isTr ? 'Lezzet Atölyesi' : 'Flavor Studio',
        body: isTr
            ? 'Görsel analiz, hızlı karar ve mutfak kısayolları burada.'
            : 'Visual analysis, fast decisions, and kitchen shortcuts.',
        swipeHint: isTr ? 'Sağa kaydır, atölyeyi aç' : 'Swipe right to open',
        icon: Icons.auto_awesome_mosaic_rounded,
        onOpen: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FlavorStudioHubScreen()),
          );
        },
      ),
      _HomeCardData(
        keyId: 'score',
        gradientColors: const [
          Color(0xFF40225E),
          Color(0xFF7242A8),
          Color(0xFFB98BEA),
        ],
        eyebrow: isTr ? 'İlerlemeni gör' : 'See your progress',
        title: isTr ? 'Şef Karnem' : 'Chef Scorecard',
        body: isTr
            ? 'Serin, seviyen ve tasarruf gücün tek yerde.'
            : 'Track your streak, level, and savings power in one view.',
        swipeHint: isTr ? 'Sağa kaydır, karneyi aç' : 'Swipe right to open',
        icon: Icons.workspace_premium_rounded,
        onOpen: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ChefScorecardScreen()),
          );
        },
      ),
      _HomeCardData(
        keyId: 'recipes',
        gradientColors: const [
          Color(0xFF4B1F0F),
          Color(0xFFD1663E),
          Color(0xFFF0B25F),
        ],
        eyebrow: isTr ? 'Topluluktan ilham al' : 'Get inspired',
        title: isTr ? 'Leziz Tarifler' : 'Tasty Recipes',
        body: isTr
            ? 'Topluluktan gelen tariflerle yeni fikirler keşfet.'
            : 'Explore new ideas from community recipes.',
        swipeHint: isTr ? 'Sağa kaydır, tariflere gir' : 'Swipe right to open',
        icon: Icons.bakery_dining_rounded,
        onOpen: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CommunityHubScreen()),
          );
        },
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFFFF2EC),
                  theme.colorScheme.surface,
                  const Color(0xFFFFF7F3),
                ],
              ),
            ),
            child: const SizedBox.expand(),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF5C56B), Color(0xFFE48B52)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: AppTheme.softShadow,
                        ),
                        child: const Icon(Icons.kitchen_rounded),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.appName,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              l10n.appTagline,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _AnimatedIconButton(
                        label: isTr ? 'EN' : 'TR',
                        onTap: provider.toggleLanguage,
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const PremiumScreen(),
                            ),
                          );
                        },
                        icon: Icon(
                          auth.isPremium
                              ? Icons.workspace_premium
                              : Icons.workspace_premium_outlined,
                          color: Colors.amber.shade700,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SettingsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.settings_outlined),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MarketTickerBar(entries: tickerEntries, isTr: isTr),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      itemCount: cards.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final card = cards[index];
                        return _SwipeOpenCard(
                          key: ValueKey(card.keyId),
                          openHint: card.swipeHint,
                          onOpen: card.onOpen,
                          child: _HomeFeatureCard(card: card),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedIconButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AnimatedIconButton({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

class _HomeCardData {
  final String keyId;
  final List<Color> gradientColors;
  final String eyebrow;
  final String title;
  final String body;
  final String swipeHint;
  final IconData icon;
  final VoidCallback onOpen;

  const _HomeCardData({
    required this.keyId,
    required this.gradientColors,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.swipeHint,
    required this.icon,
    required this.onOpen,
  });
}

class _SwipeOpenCard extends StatefulWidget {
  final String openHint;
  final VoidCallback onOpen;
  final Widget child;

  const _SwipeOpenCard({
    super.key,
    required this.openHint,
    required this.onOpen,
    required this.child,
  });

  @override
  State<_SwipeOpenCard> createState() => _SwipeOpenCardState();
}

class _SwipeOpenCardState extends State<_SwipeOpenCard> {
  double _dragOffset = 0;

  void _reset() {
    if (!mounted) return;
    setState(() => _dragOffset = 0);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final nextOffset = (_dragOffset + details.delta.dx).clamp(0.0, 116.0);
    if (nextOffset == _dragOffset) return;
    setState(() => _dragOffset = nextOffset);
  }

  void _handleDragEnd(DragEndDetails details) {
    final shouldOpen = _dragOffset > 78 ||
        (details.primaryVelocity != null && details.primaryVelocity! > 700);
    _reset();
    if (shouldOpen) {
      widget.onOpen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _handleDragUpdate,
      onHorizontalDragEnd: _handleDragEnd,
      onHorizontalDragCancel: _reset,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.openHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOut,
            transform: Matrix4.translationValues(_dragOffset, 0, 0),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

class _HomeFeatureCard extends StatelessWidget {
  final _HomeCardData card;

  const _HomeFeatureCard({required this.card});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 180,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: card.gradientColors),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: card.gradientColors[1].withValues(alpha: 0.22),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    card.eyebrow,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(card.icon, color: Colors.white, size: 20),
                ),
              ],
            ),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      card.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      card.body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.swipe_rounded,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Açmak için sağa kaydır',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MarketTickerBar extends StatelessWidget {
  final List<ProductPriceTickerEntry> entries;
  final bool isTr;

  const _MarketTickerBar({
    required this.entries,
    required this.isTr,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pills = entries.take(6).toList();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: pills.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isTr
                          ? 'Konumunu seçip fiyatları getirince güvenilir ürün karşılaştırmaları burada akacak.'
                          : 'Once you save a location and load prices, trusted product comparisons will appear here.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: pills.map((entry) {
                  final isDrop = entry.isDrop;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isDrop
                          ? const Color(0xFFE8FFF0)
                          : const Color(0xFFFFF3E8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          isDrop ? '↓' : '↑',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: isDrop
                                ? const Color(0xFF14804A)
                                : const Color(0xFFB45410),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isTr
                              ? '${repairTurkishText(entry.productTitle)} • ${entry.market} • ${entry.price.toStringAsFixed(2)} TL'
                              : '${repairTurkishText(entry.productTitle)} • ${entry.market} • ${entry.price.toStringAsFixed(2)} TRY',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '%${entry.deltaPercent.round().abs()}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
    );
  }
}

