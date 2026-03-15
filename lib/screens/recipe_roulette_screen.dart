import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/recipe.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import 'recipe_detail_screen.dart';

enum _RecipeGameMode { roulette, duel }

class RecipeRouletteScreen extends StatefulWidget {
  const RecipeRouletteScreen({super.key});

  @override
  State<RecipeRouletteScreen> createState() => _RecipeRouletteScreenState();
}

class _RecipeRouletteScreenState extends State<RecipeRouletteScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinController;
  late final Animation<double> _spinAnimation;

  final Random _random = Random();

  _RecipeGameMode _mode = _RecipeGameMode.roulette;
  Recipe? _selectedRecipe;
  List<Recipe> _duelPair = const [];
  Recipe? _duelWinner;
  bool _isSpinning = false;
  double _spinTurns = 6;

  String _selectedCategory = 'all';
  String _selectedDifficulty = 'all';
  int _maxTime = 0;

  static const _difficulties = ['all', 'easy', 'medium', 'hard'];
  static const _categories = [
    'all',
    'breakfast',
    'soup',
    'main',
    'appetizer',
    'salad',
    'dessert',
    'beverage',
    'side',
  ];

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    );
    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _isSpinning = false);
      }
    });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  List<Recipe> get _filteredRecipes {
    final recipes = context.read<AppProvider>().recipeService.recipes;
    return recipes.where((recipe) {
      final matchesCategory =
          _selectedCategory == 'all' || recipe.category == _selectedCategory;
      final matchesDifficulty =
          _selectedDifficulty == 'all' || recipe.difficulty == _selectedDifficulty;
      final matchesTime = _maxTime == 0 || recipe.totalTimeMinutes <= _maxTime;
      return matchesCategory && matchesDifficulty && matchesTime;
    }).toList();
  }

  void _spin() {
    final recipes = _filteredRecipes;
    if (recipes.isEmpty) return;

    setState(() {
      _isSpinning = true;
      _selectedRecipe = recipes[_random.nextInt(recipes.length)];
      _spinTurns = 6 + _random.nextDouble() * 2;
    });

    _spinController
      ..reset()
      ..forward();
  }

  void _buildDuel() {
    final recipes = _filteredRecipes;
    if (recipes.length < 2) return;

    final firstIndex = _random.nextInt(recipes.length);
    var secondIndex = _random.nextInt(recipes.length);
    while (secondIndex == firstIndex) {
      secondIndex = _random.nextInt(recipes.length);
    }

    setState(() {
      _duelPair = [recipes[firstIndex], recipes[secondIndex]];
      _duelWinner = null;
    });
  }

  void _pickWinner(Recipe recipe) {
    setState(() => _duelWinner = recipe);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.watch<AppProvider>().languageCode;
    final isTr = locale == 'tr';
    final recipes = _filteredRecipes;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTr ? 'Tarif Oyunlari' : 'Recipe Games'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFFF6B6B),
                  theme.colorScheme.primary,
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isTr ? 'Ne pişirsem? Karar motoru' : 'What should I cook? Decision engine',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isTr
                      ? 'Rulet ile sansina birak ya da Tarif Duellosu ile iki favori kapistir.'
                      : 'Spin the roulette or pit two recipes against each other in Duel mode.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ModeButton(
                  label: isTr ? 'Rulet' : 'Roulette',
                  icon: Icons.casino,
                  isSelected: _mode == _RecipeGameMode.roulette,
                  onTap: () => setState(() => _mode = _RecipeGameMode.roulette),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ModeButton(
                  label: isTr ? 'Tarif Duellosu' : 'Recipe Duel',
                  icon: Icons.compare_arrows,
                  isSelected: _mode == _RecipeGameMode.duel,
                  onTap: () => setState(() => _mode = _RecipeGameMode.duel),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            isTr ? 'Filtreler' : 'Filters',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(_categoryLabel(category, isTr)),
                    selected: _selectedCategory == category,
                    onSelected: (_) => setState(() => _selectedCategory = category),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _difficulties.map((difficulty) {
                    return ChoiceChip(
                      label: Text(_difficultyLabel(difficulty, isTr)),
                      selected: _selectedDifficulty == difficulty,
                      onSelected: (_) => setState(() => _selectedDifficulty = difficulty),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(width: 12),
              DropdownButton<int>(
                value: _maxTime,
                items: [
                  DropdownMenuItem(value: 0, child: Text(isTr ? 'Sure: Hepsi' : 'Time: All')),
                  const DropdownMenuItem(value: 15, child: Text('<= 15')),
                  const DropdownMenuItem(value: 30, child: Text('<= 30')),
                  const DropdownMenuItem(value: 45, child: Text('<= 45')),
                  const DropdownMenuItem(value: 60, child: Text('<= 60')),
                ],
                onChanged: (value) => setState(() => _maxTime = value ?? 0),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isTr
                ? '${recipes.length} tarif uygun'
                : '${recipes.length} recipes available',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          if (_mode == _RecipeGameMode.roulette) ...[
            Center(
              child: SizedBox(
                width: 250,
                height: 250,
                child: AnimatedBuilder(
                  animation: _spinAnimation,
                  builder: (context, child) {
                    final angle = _spinAnimation.value * _spinTurns * pi;
                    return Transform.rotate(
                      angle: _isSpinning ? angle : 0,
                      child: child,
                    );
                  },
                  child: _RouletteWheel(
                    recipes: recipes.take(8).toList(),
                    locale: locale,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isSpinning || recipes.isEmpty ? null : _spin,
              icon: Icon(_isSpinning ? Icons.hourglass_top : Icons.casino),
              label: Text(
                _isSpinning
                    ? (isTr ? 'Donuyor...' : 'Spinning...')
                    : (isTr ? 'Ruleti Cevir' : 'Spin Roulette'),
              ),
            ),
            if (_selectedRecipe != null && !_isSpinning) ...[
              const SizedBox(height: 20),
              _RecipeResultCard(
                recipe: _selectedRecipe!,
                locale: locale,
                title: isTr ? 'Bugun bunu pisir' : 'Cook this today',
                secondaryActionLabel: isTr ? 'Tekrar cevir' : 'Spin again',
                secondaryAction: _spin,
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTr ? 'Tarif Duellosu' : 'Recipe Duel',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isTr
                        ? 'Iki adayi kapistir, galibi sen sec.'
                        : 'Pit two candidates against each other and pick the winner.',
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: recipes.length >= 2 ? _buildDuel : null,
                    icon: const Icon(Icons.shuffle),
                    label: Text(
                      isTr ? 'Yeni Duello Olustur' : 'Create New Duel',
                    ),
                  ),
                ],
              ),
            ),
            if (_duelPair.isNotEmpty) ...[
              const SizedBox(height: 20),
              ..._duelPair.map((recipe) {
                final isWinner = _duelWinner?.id == recipe.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DuelRecipeCard(
                    recipe: recipe,
                    locale: locale,
                    isWinner: isWinner,
                    onPickWinner: () => _pickWinner(recipe),
                  ),
                );
              }),
            ],
            if (_duelWinner != null) ...[
              const SizedBox(height: 8),
              _RecipeResultCard(
                recipe: _duelWinner!,
                locale: locale,
                title: isTr ? 'Duellonun galibi' : 'Duel winner',
                secondaryActionLabel: isTr ? 'Yeni duello' : 'New duel',
                secondaryAction: _buildDuel,
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _categoryLabel(String category, bool isTr) {
    const tr = {
      'all': 'Tumu',
      'breakfast': 'Kahvalti',
      'soup': 'Corba',
      'main': 'Ana yemek',
      'appetizer': 'Meze',
      'salad': 'Salata',
      'dessert': 'Tatli',
      'beverage': 'Icecek',
      'side': 'Garnitur',
    };
    const en = {
      'all': 'All',
      'breakfast': 'Breakfast',
      'soup': 'Soup',
      'main': 'Main',
      'appetizer': 'Appetizer',
      'salad': 'Salad',
      'dessert': 'Dessert',
      'beverage': 'Drink',
      'side': 'Side',
    };
    return isTr ? (tr[category] ?? category) : (en[category] ?? category);
  }

  String _difficultyLabel(String difficulty, bool isTr) {
    const tr = {'all': 'Hepsi', 'easy': 'Kolay', 'medium': 'Orta', 'hard': 'Zor'};
    const en = {'all': 'All', 'easy': 'Easy', 'medium': 'Medium', 'hard': 'Hard'};
    return isTr ? (tr[difficulty] ?? difficulty) : (en[difficulty] ?? difficulty);
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: isSelected
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      icon: Icon(icon),
      label: Text(label, textAlign: TextAlign.center),
    );
  }
}

class _RouletteWheel extends StatelessWidget {
  final List<Recipe> recipes;
  final String locale;

  const _RouletteWheel({
    required this.recipes,
    required this.locale,
  });

  @override
  Widget build(BuildContext context) {
    if (recipes.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        alignment: Alignment.center,
        child: const Text('🍽️', style: TextStyle(fontSize: 54)),
      );
    }

    return CustomPaint(
      painter: _WheelPainter(recipes: recipes),
      child: const SizedBox.expand(),
    );
  }
}

class _WheelPainter extends CustomPainter {
  final List<Recipe> recipes;

  _WheelPainter({required this.recipes});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final segmentAngle = 2 * pi / recipes.length;

    for (var i = 0; i < recipes.length; i++) {
      final gradient = AppTheme.categoryGradients[recipes[i].category] ??
          [Colors.orange.shade200, Colors.orange.shade100];
      final startAngle = i * segmentAngle - pi / 2;
      final paint = Paint()..color = gradient.first.withValues(alpha: 0.78);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        segmentAngle,
        true,
        paint,
      );

      final emojiPainter = TextPainter(
        text: TextSpan(
          text: recipes[i].imageEmoji,
          style: const TextStyle(fontSize: 24),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final emojiAngle = startAngle + segmentAngle / 2;
      final emojiOffset = Offset(
        center.dx + cos(emojiAngle) * radius * 0.62 - emojiPainter.width / 2,
        center.dy + sin(emojiAngle) * radius * 0.62 - emojiPainter.height / 2,
      );
      emojiPainter.paint(canvas, emojiOffset);
    }

    final centerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 24, centerPaint);
    final dotPainter = TextPainter(
      text: const TextSpan(text: '🎯', style: TextStyle(fontSize: 20)),
      textDirection: TextDirection.ltr,
    )..layout();
    dotPainter.paint(canvas, Offset(center.dx - 10, center.dy - 12));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _RecipeResultCard extends StatelessWidget {
  final Recipe recipe;
  final String locale;
  final String title;
  final String secondaryActionLabel;
  final VoidCallback secondaryAction;

  const _RecipeResultCard({
    required this.recipe,
    required this.locale,
    required this.title,
    required this.secondaryActionLabel,
    required this.secondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = locale == 'tr';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          Text(recipe.imageEmoji, style: const TextStyle(fontSize: 46)),
          const SizedBox(height: 10),
          Text(
            recipe.getName(locale),
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '${recipe.totalTimeMinutes} ${isTr ? 'dk' : 'min'} • ${recipe.getDifficultyText(locale)}',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: secondaryAction,
                  child: Text(secondaryActionLabel),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
                  ),
                  child: Text(isTr ? 'Tarife Git' : 'Open Recipe'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DuelRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final String locale;
  final bool isWinner;
  final VoidCallback onPickWinner;

  const _DuelRecipeCard({
    required this.recipe,
    required this.locale,
    required this.isWinner,
    required this.onPickWinner,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = locale == 'tr';
    final gradient = AppTheme.categoryGradients[recipe.category] ??
        [theme.colorScheme.primaryContainer, theme.colorScheme.surfaceContainerHighest];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: gradient),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWinner ? Colors.green : Colors.transparent,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(recipe.imageEmoji, style: const TextStyle(fontSize: 34)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  recipe.getName(locale),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (isWinner)
                const Icon(Icons.emoji_events, color: Colors.green),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            recipe.getDescription(locale),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => RecipeDetailScreen(recipe: recipe)),
                  ),
                  child: Text(isTr ? 'Detay' : 'Details'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: onPickWinner,
                  child: Text(isTr ? 'Bunu Sec' : 'Pick Winner'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
