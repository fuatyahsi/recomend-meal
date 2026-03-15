import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/recipe.dart';
import '../utils/app_theme.dart';

/// Lezzet DNA'sı Profili
/// Kullanıcının pişirme geçmişini ve tercihlerini radar chart ile analiz eder
class FlavorDNAScreen extends StatefulWidget {
  const FlavorDNAScreen({super.key});

  @override
  State<FlavorDNAScreen> createState() => _FlavorDNAScreenState();
}

class _FlavorDNAScreenState extends State<FlavorDNAScreen>
    with TickerProviderStateMixin {
  late AnimationController _chartController;
  late Animation<double> _chartAnimation;
  late AnimationController _profileController;

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _chartAnimation = CurvedAnimation(
      parent: _chartController,
      curve: Curves.easeOutBack,
    );
    _profileController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _chartController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _profileController.forward();
    });
  }

  @override
  void dispose() {
    _chartController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  _FlavorProfile _analyzeProfile(List<Recipe> recipes) {
    if (recipes.isEmpty) return _FlavorProfile.empty();

    // Analyze category distribution
    final catCount = <String, int>{};
    final diffCount = <String, int>{};
    int totalTime = 0;

    for (final r in recipes) {
      catCount[r.category] = (catCount[r.category] ?? 0) + 1;
      diffCount[r.difficulty] = (diffCount[r.difficulty] ?? 0) + 1;
      totalTime += r.totalTimeMinutes;
    }

    final total = recipes.length.toDouble();
    final avgTime = totalTime / total;

    // Calculate dimension scores (0.0 - 1.0)
    final traditional = ((catCount['soup'] ?? 0) + (catCount['main'] ?? 0) + (catCount['side'] ?? 0)) / total;
    final adventurous = ((catCount['appetizer'] ?? 0) + (diffCount['hard'] ?? 0)) / total;
    final healthy = ((catCount['salad'] ?? 0) + (catCount['soup'] ?? 0)) / total;
    final sweetTooth = ((catCount['dessert'] ?? 0) + (catCount['beverage'] ?? 0)) / total;
    final quickChef = recipes.where((r) => r.totalTimeMinutes <= 20).length / total;
    final masterChef = (diffCount['hard'] ?? 0) / total + (diffCount['medium'] ?? 0) / (total * 2);

    // Normalize to 0.1 - 1.0 range
    double norm(double v) => (v * 2.0).clamp(0.1, 1.0);

    return _FlavorProfile(
      traditional: norm(traditional),
      adventurous: norm(adventurous),
      healthy: norm(healthy),
      sweetTooth: norm(sweetTooth),
      quickChef: norm(quickChef),
      masterChef: norm(masterChef),
      totalRecipes: recipes.length,
      avgTime: avgTime,
      favoriteCategory: _findMax(catCount),
      favoriteDifficulty: _findMax(diffCount),
      catDistribution: catCount,
    );
  }

  String _findMax(Map<String, int> map) {
    if (map.isEmpty) return '';
    return map.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final locale = provider.languageCode;
    final isTr = locale == 'tr';
    final allRecipes = provider.recipeService.recipes;
    final profile = _analyzeProfile(allRecipes);

    final dimensions = [
      _DimensionData('traditional', isTr ? 'Geleneksel' : 'Traditional', '👵', profile.traditional),
      _DimensionData('adventurous', isTr ? 'Maceracı' : 'Adventurous', '🧭', profile.adventurous),
      _DimensionData('healthy', isTr ? 'Sağlıklı' : 'Healthy', '🥦', profile.healthy),
      _DimensionData('sweetTooth', isTr ? 'Tatlıcı' : 'Sweet Tooth', '🍰', profile.sweetTooth),
      _DimensionData('quickChef', isTr ? 'Hızlı Şef' : 'Quick Chef', '⚡', profile.quickChef),
      _DimensionData('masterChef', isTr ? 'Usta Şef' : 'Master Chef', '👨‍🍳', profile.masterChef),
    ];

    // Find dominant personality
    final dominant = dimensions.reduce((a, b) => a.value >= b.value ? a : b);
    final personality = _getPersonality(dominant.id, isTr);

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                isTr ? 'Lezzet DNA\'sı' : 'Flavor DNA',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black38)],
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF6C63FF), Color(0xFFFF6584)],
                  ),
                ),
                child: Center(
                  child: Text(
                    '🧬',
                    style: TextStyle(
                      fontSize: 50,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Personality Title
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _profileController,
              builder: (context, child) => Opacity(
                opacity: _profileController.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _profileController.value)),
                  child: child,
                ),
              ),
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF6C63FF).withOpacity(0.08),
                      const Color(0xFFFF6584).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.15),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      personality['emoji'] as String,
                      style: const TextStyle(fontSize: 40),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      personality['title'] as String,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF6C63FF),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      personality['desc'] as String,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Radar Chart
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: AnimatedBuilder(
                animation: _chartAnimation,
                builder: (context, _) {
                  return SizedBox(
                    height: 300,
                    child: CustomPaint(
                      painter: _RadarChartPainter(
                        dimensions: dimensions,
                        progress: _chartAnimation.value,
                        primaryColor: const Color(0xFF6C63FF),
                        fillColor: const Color(0xFF6C63FF).withOpacity(0.15),
                      ),
                      size: const Size(300, 300),
                    ),
                  );
                },
              ),
            ),
          ),

          // Dimension Breakdown
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                isTr ? 'Profil Detayları' : 'Profile Details',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final dim = dimensions[index];
                return _DimensionBar(
                  dimension: dim,
                  progress: _chartAnimation.value,
                );
              },
              childCount: dimensions.length,
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          // Stats Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                isTr ? 'İstatistikler' : 'Statistics',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      emoji: '📊',
                      value: '${profile.totalRecipes}',
                      label: isTr ? 'Toplam Tarif' : 'Total Recipes',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      emoji: '⏱',
                      value: '${profile.avgTime.round()} ${isTr ? "dk" : "min"}',
                      label: isTr ? 'Ort. Süre' : 'Avg. Time',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      emoji: _getCategoryEmoji(profile.favoriteCategory),
                      value: _getCategoryName(profile.favoriteCategory, isTr),
                      label: isTr ? 'En Sevilen' : 'Favorite',
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Category Distribution
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
              child: Text(
                isTr ? 'Kategori Dağılımı' : 'Category Distribution',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: profile.catDistribution.entries.map((entry) {
                  final pct = (entry.value / profile.totalRecipes * 100).round();
                  final gc = AppTheme.categoryGradients[entry.key];
                  final color = gc?.first ?? Colors.grey;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_getCategoryEmoji(entry.key), style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          '${_getCategoryName(entry.key, isTr)} $pct%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 20)),
        ],
      ),
    );
  }

  Map<String, String> _getPersonality(String dominantId, bool isTr) {
    final personalities = {
      'traditional': {
        'emoji': '👵',
        'title': isTr ? 'Geleneksel Ruh' : 'Traditional Soul',
        'desc': isTr
            ? 'Anneannenin tarifleri senin pusulan. Ev yemekleri senin dünyan!'
            : "Grandma's recipes are your compass. Home cooking is your world!",
      },
      'adventurous': {
        'emoji': '🧭',
        'title': isTr ? 'Mutfak Kaşifi' : 'Kitchen Explorer',
        'desc': isTr
            ? 'Yeni tatlar keşfetmeyi seviyorsun. Cesur ve yaratıcı bir şefsin!'
            : "You love discovering new flavors. You're a bold and creative chef!",
      },
      'healthy': {
        'emoji': '🥗',
        'title': isTr ? 'Sağlık Tutkunu' : 'Health Enthusiast',
        'desc': isTr
            ? 'Dengeli beslenme senin motton. Vücuduna ne girdiği önemli!'
            : "Balanced nutrition is your motto. You care about what fuels your body!",
      },
      'sweetTooth': {
        'emoji': '🍰',
        'title': isTr ? 'Tatlı Ustası' : 'Sweet Artisan',
        'desc': isTr
            ? 'Hayat tatlısız olmaz! Tatlı ve içecek tarifleri senin uzman alanın.'
            : "Life is sweeter with desserts! Sweet recipes are your specialty.",
      },
      'quickChef': {
        'emoji': '⚡',
        'title': isTr ? 'Hız Şeytanı' : 'Speed Demon Chef',
        'desc': isTr
            ? 'Hızlı ve pratik tarifler senin tarzın. Az zamanda çok iş!'
            : "Quick and practical recipes are your style. Maximum output, minimum time!",
      },
      'masterChef': {
        'emoji': '👨‍🍳',
        'title': isTr ? 'Usta Şef' : 'Master Chef',
        'desc': isTr
            ? 'Zor tariflerden korkmuyorsun. Mutfakta meydan okumayı seviyorsun!'
            : "You don't shy away from challenges. You love pushing your culinary limits!",
      },
    };
    return personalities[dominantId] ?? personalities['traditional']!;
  }

  String _getCategoryEmoji(String cat) {
    const map = {
      'breakfast': '🍳', 'soup': '🥣', 'main': '🍖', 'appetizer': '🥟',
      'salad': '🥗', 'dessert': '🍰', 'beverage': '🥤', 'side': '🍚',
    };
    return map[cat] ?? '🍽️';
  }

  String _getCategoryName(String cat, bool isTr) {
    const trMap = {
      'breakfast': 'Kahvaltı', 'soup': 'Çorba', 'main': 'Ana Yemek',
      'appetizer': 'Meze', 'salad': 'Salata', 'dessert': 'Tatlı',
      'beverage': 'İçecek', 'side': 'Garnitür',
    };
    const enMap = {
      'breakfast': 'Breakfast', 'soup': 'Soup', 'main': 'Main',
      'appetizer': 'Appetizer', 'salad': 'Salad', 'dessert': 'Dessert',
      'beverage': 'Beverage', 'side': 'Side',
    };
    return isTr ? (trMap[cat] ?? cat) : (enMap[cat] ?? cat);
  }
}

// ── Data Models ──
class _FlavorProfile {
  final double traditional;
  final double adventurous;
  final double healthy;
  final double sweetTooth;
  final double quickChef;
  final double masterChef;
  final int totalRecipes;
  final double avgTime;
  final String favoriteCategory;
  final String favoriteDifficulty;
  final Map<String, int> catDistribution;

  _FlavorProfile({
    required this.traditional,
    required this.adventurous,
    required this.healthy,
    required this.sweetTooth,
    required this.quickChef,
    required this.masterChef,
    required this.totalRecipes,
    required this.avgTime,
    required this.favoriteCategory,
    required this.favoriteDifficulty,
    required this.catDistribution,
  });

  factory _FlavorProfile.empty() => _FlavorProfile(
    traditional: 0.1, adventurous: 0.1, healthy: 0.1,
    sweetTooth: 0.1, quickChef: 0.1, masterChef: 0.1,
    totalRecipes: 0, avgTime: 0, favoriteCategory: '',
    favoriteDifficulty: '', catDistribution: {},
  );
}

class _DimensionData {
  final String id;
  final String label;
  final String emoji;
  final double value;

  _DimensionData(this.id, this.label, this.emoji, this.value);
}

// ── Radar Chart Painter ──
class _RadarChartPainter extends CustomPainter {
  final List<_DimensionData> dimensions;
  final double progress;
  final Color primaryColor;
  final Color fillColor;

  _RadarChartPainter({
    required this.dimensions,
    required this.progress,
    required this.primaryColor,
    required this.fillColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 30;
    final count = dimensions.length;
    final angleStep = 2 * pi / count;

    // Draw grid lines (3 levels)
    for (var level = 1; level <= 3; level++) {
      final levelRadius = radius * level / 3;
      final gridPaint = Paint()
        ..color = Colors.grey.withOpacity(0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      final path = Path();
      for (var i = 0; i <= count; i++) {
        final angle = i * angleStep - pi / 2;
        final point = Offset(
          center.dx + levelRadius * cos(angle),
          center.dy + levelRadius * sin(angle),
        );
        if (i == 0) {
          path.moveTo(point.dx, point.dy);
        } else {
          path.lineTo(point.dx, point.dy);
        }
      }
      canvas.drawPath(path, gridPaint);
    }

    // Draw axis lines
    for (var i = 0; i < count; i++) {
      final angle = i * angleStep - pi / 2;
      final endPoint = Offset(
        center.dx + radius * cos(angle),
        center.dy + radius * sin(angle),
      );
      final axisPaint = Paint()
        ..color = Colors.grey.withOpacity(0.1)
        ..strokeWidth = 1;
      canvas.drawLine(center, endPoint, axisPaint);
    }

    // Draw data polygon (animated)
    final dataPath = Path();
    final dataPoints = <Offset>[];
    for (var i = 0; i <= count; i++) {
      final idx = i % count;
      final angle = idx * angleStep - pi / 2;
      final value = dimensions[idx].value * progress;
      final point = Offset(
        center.dx + radius * value * cos(angle),
        center.dy + radius * value * sin(angle),
      );
      dataPoints.add(point);
      if (i == 0) {
        dataPath.moveTo(point.dx, point.dy);
      } else {
        dataPath.lineTo(point.dx, point.dy);
      }
    }

    // Fill
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;
    canvas.drawPath(dataPath, fillPaint);

    // Stroke
    final strokePaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawPath(dataPath, strokePaint);

    // Data points (dots)
    for (var i = 0; i < count; i++) {
      final dotPaint = Paint()
        ..color = primaryColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dataPoints[i], 5, dotPaint);

      final dotBorderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(dataPoints[i], 3, dotBorderPaint);
    }

    // Labels
    for (var i = 0; i < count; i++) {
      final angle = i * angleStep - pi / 2;
      final labelRadius = radius + 22;
      final labelPoint = Offset(
        center.dx + labelRadius * cos(angle),
        center.dy + labelRadius * sin(angle),
      );

      // Emoji
      final emojiPainter = TextPainter(
        text: TextSpan(
          text: '${dimensions[i].emoji} ${dimensions[i].label}',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      emojiPainter.layout();
      emojiPainter.paint(
        canvas,
        Offset(
          labelPoint.dx - emojiPainter.width / 2,
          labelPoint.dy - emojiPainter.height / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter old) =>
      old.progress != progress;
}

// ── Dimension Bar ──
class _DimensionBar extends StatelessWidget {
  final _DimensionData dimension;
  final double progress;

  const _DimensionBar({required this.dimension, required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = (dimension.value * 100 * progress).round();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Row(
        children: [
          Text(dimension.emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          SizedBox(
            width: 80,
            child: Text(
              dimension.label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: dimension.value * progress,
                minHeight: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getBarColor(dimension.value),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 36,
            child: Text(
              '$pct%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
                color: _getBarColor(dimension.value),
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBarColor(double value) {
    if (value >= 0.7) return const Color(0xFF6C63FF);
    if (value >= 0.4) return const Color(0xFFFF8C42);
    return Colors.grey;
  }
}

// ── Stat Card ──
class _StatCard extends StatelessWidget {
  final String emoji;
  final String value;
  final String label;

  const _StatCard({
    required this.emoji,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
