import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/app_provider.dart';
import '../models/recipe.dart';
import '../utils/app_theme.dart';

/// Mutfak Orkestra Şefi - Çoklu tarif zamanlayıcı ve paralel timeline
/// Birden fazla tarifi aynı anda pişirirken adımları koordine eder
class KitchenOrchestraScreen extends StatefulWidget {
  const KitchenOrchestraScreen({super.key});

  @override
  State<KitchenOrchestraScreen> createState() => _KitchenOrchestraScreenState();
}

class _KitchenOrchestraScreenState extends State<KitchenOrchestraScreen>
    with TickerProviderStateMixin {
  final List<_OrchestraRecipe> _activeRecipes = [];
  Timer? _globalTimer;
  bool _isPlaying = false;
  int _totalElapsedSeconds = 0;

  @override
  void dispose() {
    _globalTimer?.cancel();
    for (final r in _activeRecipes) {
      r.animController.dispose();
    }
    super.dispose();
  }

  void _addRecipe(Recipe recipe) {
    if (_activeRecipes.any((r) => r.recipe.id == recipe.id)) return;
    if (_activeRecipes.length >= 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isTr ? 'En fazla 4 tarif ekleyebilirsiniz' : 'Maximum 4 recipes allowed',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    final controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    final locale = context.read<AppProvider>().languageCode;
    setState(() {
      _activeRecipes.add(_OrchestraRecipe(
        recipe: recipe,
        stepTimers: List.generate(
          recipe.getSteps(locale).length,
          (_) => _StepTimer(),
        ),
        animController: controller,
      ));
    });
    controller.forward();
  }

  void _removeRecipe(int index) {
    _activeRecipes[index].animController.dispose();
    setState(() {
      _activeRecipes.removeAt(index);
      if (_activeRecipes.isEmpty) {
        _stopGlobalTimer();
      }
    });
  }

  void _toggleGlobalTimer() {
    if (_isPlaying) {
      _stopGlobalTimer();
    } else {
      _startGlobalTimer();
    }
  }

  void _startGlobalTimer() {
    setState(() => _isPlaying = true);
    _globalTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _totalElapsedSeconds++;
        // Update active step timers
        for (final orchestraRecipe in _activeRecipes) {
          for (final stepTimer in orchestraRecipe.stepTimers) {
            if (stepTimer.isRunning) {
              stepTimer.elapsedSeconds++;
            }
          }
        }
      });
    });
  }

  void _stopGlobalTimer() {
    _globalTimer?.cancel();
    setState(() => _isPlaying = false);
  }

  void _resetAll() {
    _stopGlobalTimer();
    setState(() {
      _totalElapsedSeconds = 0;
      for (final r in _activeRecipes) {
        for (final st in r.stepTimers) {
          st.elapsedSeconds = 0;
          st.isRunning = false;
          st.isCompleted = false;
        }
      }
    });
  }

  void _toggleStepTimer(int recipeIndex, int stepIndex) {
    setState(() {
      final timer = _activeRecipes[recipeIndex].stepTimers[stepIndex];
      if (timer.isCompleted) return;
      timer.isRunning = !timer.isRunning;

      // Auto-start global timer if any step is running
      if (timer.isRunning && !_isPlaying) {
        _startGlobalTimer();
      }
    });
  }

  void _completeStep(int recipeIndex, int stepIndex) {
    setState(() {
      final timer = _activeRecipes[recipeIndex].stepTimers[stepIndex];
      timer.isRunning = false;
      timer.isCompleted = true;
    });
  }

  bool get _isTr {
    final provider = context.read<AppProvider>();
    return provider.languageCode == 'tr';
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  int get _totalCompletedSteps {
    int count = 0;
    for (final r in _activeRecipes) {
      for (final st in r.stepTimers) {
        if (st.isCompleted) count++;
      }
    }
    return count;
  }

  int get _totalSteps {
    int count = 0;
    for (final r in _activeRecipes) {
      count += r.stepTimers.length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final locale = provider.languageCode;
    final isTr = locale == 'tr';
    final allRecipes = provider.recipeService.recipes;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                isTr ? 'Mutfak Orkestra Şefi' : 'Kitchen Orchestra',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black38)],
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFFFF8C42),
                      theme.colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    '🎼',
                    style: TextStyle(
                      fontSize: 50,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              if (_activeRecipes.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.restart_alt, color: Colors.white),
                  onPressed: _resetAll,
                  tooltip: isTr ? 'Sıfırla' : 'Reset',
                ),
            ],
          ),

          // Global Timer & Controls
          if (_activeRecipes.isNotEmpty)
            SliverToBoxAdapter(
              child: _GlobalTimerBar(
                elapsed: _totalElapsedSeconds,
                isPlaying: _isPlaying,
                completedSteps: _totalCompletedSteps,
                totalSteps: _totalSteps,
                formatTime: _formatTime,
                onToggle: _toggleGlobalTimer,
                isTr: isTr,
              ),
            ),

          // Empty state
          if (_activeRecipes.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎻', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      Text(
                        isTr
                            ? 'Orkestranı Kur!'
                            : 'Set Up Your Orchestra!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isTr
                            ? 'Aşağıdan tarifleri seç ve aynı anda birden fazla tarifi koordine et'
                            : 'Select recipes below and coordinate multiple dishes at once',
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

          // Active Recipes with timers
          if (_activeRecipes.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  isTr ? 'Aktif Tarifler' : 'Active Recipes',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final orchestraRecipe = _activeRecipes[index];
                  return _ActiveRecipeCard(
                    orchestraRecipe: orchestraRecipe,
                    recipeIndex: index,
                    locale: locale,
                    formatTime: _formatTime,
                    onToggleStep: (stepIdx) => _toggleStepTimer(index, stepIdx),
                    onCompleteStep: (stepIdx) => _completeStep(index, stepIdx),
                    onRemove: () => _removeRecipe(index),
                  );
                },
                childCount: _activeRecipes.length,
              ),
            ),
          ],

          // Divider
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: Row(
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 20, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    isTr ? 'Tarif Ekle' : 'Add Recipe',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_activeRecipes.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_activeRecipes.length}/4',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Recipe picker list
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final recipe = allRecipes[index];
                  final isAdded = _activeRecipes.any((r) => r.recipe.id == recipe.id);
                  return AnimationConfiguration.staggeredList(
                    position: index,
                    duration: const Duration(milliseconds: 300),
                    child: SlideAnimation(
                      verticalOffset: 30,
                      child: FadeInAnimation(
                        child: _RecipePickerTile(
                          recipe: recipe,
                          locale: locale,
                          isAdded: isAdded,
                          onTap: () {
                            if (!isAdded) _addRecipe(recipe);
                          },
                        ),
                      ),
                    ),
                  );
                },
                childCount: allRecipes.length,
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ── Data Models ──
class _OrchestraRecipe {
  final Recipe recipe;
  final List<_StepTimer> stepTimers;
  final AnimationController animController;

  _OrchestraRecipe({
    required this.recipe,
    required this.stepTimers,
    required this.animController,
  });
}

class _StepTimer {
  int elapsedSeconds = 0;
  bool isRunning = false;
  bool isCompleted = false;
}

// ── Global Timer Bar ──
class _GlobalTimerBar extends StatelessWidget {
  final int elapsed;
  final bool isPlaying;
  final int completedSteps;
  final int totalSteps;
  final String Function(int) formatTime;
  final VoidCallback onToggle;
  final bool isTr;

  const _GlobalTimerBar({
    required this.elapsed,
    required this.isPlaying,
    required this.completedSteps,
    required this.totalSteps,
    required this.formatTime,
    required this.onToggle,
    required this.isTr,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = totalSteps > 0 ? completedSteps / totalSteps : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Play/Pause button
              GestureDetector(
                onTap: onToggle,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              // Timer display
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatTime(elapsed),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                    Text(
                      isTr
                          ? 'Toplam pişirme süresi'
                          : 'Total cooking time',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress
              Column(
                children: [
                  Text(
                    '$completedSteps/$totalSteps',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    isTr ? 'adım' : 'steps',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Active Recipe Card with Steps ──
class _ActiveRecipeCard extends StatelessWidget {
  final _OrchestraRecipe orchestraRecipe;
  final int recipeIndex;
  final String locale;
  final String Function(int) formatTime;
  final void Function(int) onToggleStep;
  final void Function(int) onCompleteStep;
  final VoidCallback onRemove;

  const _ActiveRecipeCard({
    required this.orchestraRecipe,
    required this.recipeIndex,
    required this.locale,
    required this.formatTime,
    required this.onToggleStep,
    required this.onCompleteStep,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recipe = orchestraRecipe.recipe;
    final isTr = locale == 'tr';
    final gradientColors = AppTheme.categoryGradients[recipe.category] ??
        [const Color(0xFFF5F5F5), const Color(0xFFE0E0E0)];
    final completedCount = orchestraRecipe.stepTimers.where((s) => s.isCompleted).length;
    final totalCount = orchestraRecipe.stepTimers.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
        border: Border.all(
          color: gradientColors[0].withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          // Recipe header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradientColors[0].withOpacity(0.3), gradientColors[1].withOpacity(0.1)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Text(recipe.imageEmoji, style: const TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.getName(locale),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 12, color: theme.colorScheme.outline),
                          const SizedBox(width: 3),
                          Text(
                            '${recipe.totalTimeMinutes} ${isTr ? "dk" : "min"}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: completedCount == totalCount
                                  ? Colors.green.withOpacity(0.1)
                                  : theme.colorScheme.primaryContainer.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '$completedCount/$totalCount',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: completedCount == totalCount
                                    ? Colors.green
                                    : theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, size: 18, color: theme.colorScheme.outline),
                  onPressed: onRemove,
                  tooltip: isTr ? 'Kaldır' : 'Remove',
                ),
              ],
            ),
          ),

          // Steps timeline
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
            child: Column(
              children: List.generate(orchestraRecipe.stepTimers.length, (stepIndex) {
                final stepTimer = orchestraRecipe.stepTimers[stepIndex];
                final steps = recipe.getSteps(locale);
                final step = steps[stepIndex];
                return _StepTimerTile(
                  stepNumber: stepIndex + 1,
                  stepText: step.instruction,
                  timer: stepTimer,
                  formatTime: formatTime,
                  isLast: stepIndex == orchestraRecipe.stepTimers.length - 1,
                  onToggle: () => onToggleStep(stepIndex),
                  onComplete: () => onCompleteStep(stepIndex),
                  isTr: isTr,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Step Timer Tile ──
class _StepTimerTile extends StatelessWidget {
  final int stepNumber;
  final String stepText;
  final _StepTimer timer;
  final String Function(int) formatTime;
  final bool isLast;
  final VoidCallback onToggle;
  final VoidCallback onComplete;
  final bool isTr;

  const _StepTimerTile({
    required this.stepNumber,
    required this.stepText,
    required this.timer,
    required this.formatTime,
    required this.isLast,
    required this.onToggle,
    required this.onComplete,
    required this.isTr,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color circleColor;
    IconData circleIcon;
    if (timer.isCompleted) {
      circleColor = Colors.green;
      circleIcon = Icons.check;
    } else if (timer.isRunning) {
      circleColor = theme.colorScheme.primary;
      circleIcon = Icons.timer;
    } else {
      circleColor = theme.colorScheme.outline.withOpacity(0.3);
      circleIcon = Icons.circle_outlined;
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline line + circle
          SizedBox(
            width: 40,
            child: Column(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: circleColor.withOpacity(timer.isCompleted ? 1.0 : 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: circleColor, width: 2),
                  ),
                  child: Center(
                    child: timer.isCompleted
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : Text(
                            '$stepNumber',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: circleColor,
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: timer.isCompleted
                          ? Colors.green.withOpacity(0.3)
                          : theme.colorScheme.outlineVariant.withOpacity(0.3),
                    ),
                  ),
              ],
            ),
          ),
          // Step content
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: timer.isRunning
                    ? theme.colorScheme.primaryContainer.withOpacity(0.2)
                    : timer.isCompleted
                        ? Colors.green.withOpacity(0.05)
                        : theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: timer.isRunning
                    ? Border.all(color: theme.colorScheme.primary.withOpacity(0.3))
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stepText,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: timer.isCompleted
                          ? theme.colorScheme.onSurfaceVariant
                          : theme.colorScheme.onSurface,
                      decoration: timer.isCompleted ? TextDecoration.lineThrough : null,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Timer display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: timer.isRunning
                              ? theme.colorScheme.primary.withOpacity(0.1)
                              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              timer.isRunning ? Icons.timer : Icons.timer_outlined,
                              size: 12,
                              color: timer.isRunning
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outline,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              formatTime(timer.elapsedSeconds),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                fontFeatures: const [FontFeature.tabularFigures()],
                                color: timer.isRunning
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      if (!timer.isCompleted) ...[
                        // Play/Pause step
                        GestureDetector(
                          onTap: onToggle,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: timer.isRunning
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surfaceContainerHighest,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              timer.isRunning ? Icons.pause : Icons.play_arrow,
                              size: 14,
                              color: timer.isRunning
                                  ? Colors.white
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Complete step
                        GestureDetector(
                          onTap: onComplete,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 14,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                      if (timer.isCompleted)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isTr ? 'Tamamlandı' : 'Done',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
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
    );
  }
}

// ── Recipe Picker Tile ──
class _RecipePickerTile extends StatelessWidget {
  final Recipe recipe;
  final String locale;
  final bool isAdded;
  final VoidCallback onTap;

  const _RecipePickerTile({
    required this.recipe,
    required this.locale,
    required this.isAdded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = locale == 'tr';
    final gradientColors = AppTheme.categoryGradients[recipe.category] ??
        [const Color(0xFFF5F5F5), const Color(0xFFE0E0E0)];

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isAdded ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isAdded
                  ? theme.colorScheme.surfaceContainerHighest.withOpacity(0.3)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isAdded
                    ? Colors.green.withOpacity(0.3)
                    : theme.colorScheme.outlineVariant.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradientColors),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(recipe.imageEmoji, style: const TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.getName(locale),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isAdded
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${recipe.getSteps(locale).length} ${isTr ? "adım" : "steps"} · ${recipe.totalTimeMinutes} ${isTr ? "dk" : "min"}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isAdded)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 16, color: Colors.green),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, size: 16, color: theme.colorScheme.primary),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
