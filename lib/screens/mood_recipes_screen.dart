import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../providers/app_provider.dart';
import '../models/recipe.dart';
import '../utils/mood_recipes.dart';
import '../utils/app_theme.dart';
import 'recipe_detail_screen.dart';

class MoodRecipesScreen extends StatefulWidget {
  const MoodRecipesScreen({super.key});

  @override
  State<MoodRecipesScreen> createState() => _MoodRecipesScreenState();
}

class _MoodRecipesScreenState extends State<MoodRecipesScreen>
    with TickerProviderStateMixin {
  MoodOption? _selectedMood;
  late AnimationController _selectionController;

  @override
  void initState() {
    super.initState();
    _selectionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _selectionController.dispose();
    super.dispose();
  }

  List<Recipe> _filterRecipes(List<Recipe> allRecipes, MoodFilter filter) {
    return allRecipes.where((recipe) {
      // Time filter
      if (filter.maxTime > 0 && recipe.totalTimeMinutes > filter.maxTime) {
        return false;
      }
      // Difficulty filter
      if (filter.difficulties.isNotEmpty &&
          !filter.difficulties.contains(recipe.difficulty)) {
        return false;
      }
      // Category filter
      if (filter.categories.isNotEmpty &&
          !filter.categories.contains(recipe.category)) {
        return false;
      }
      return true;
    }).toList();
  }

  void _selectMood(MoodOption mood) {
    setState(() {
      _selectedMood = mood;
    });
    _selectionController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final theme = Theme.of(context);
    final locale = provider.languageCode;
    final isTr = locale == 'tr';

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                isTr ? 'Bugün Nasıl Hissediyorsun?' : 'How Are You Feeling Today?',
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
                      theme.colorScheme.primary.withOpacity(0.8),
                      theme.colorScheme.tertiary.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    _selectedMood?.emoji ?? '🤔',
                    style: TextStyle(
                      fontSize: 50,
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Mood selection grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: AnimationLimiter(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.6,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: MoodRecipeEngine.moods.length,
                  itemBuilder: (context, index) {
                    final mood = MoodRecipeEngine.moods[index];
                    final isSelected = _selectedMood?.id == mood.id;
                    return AnimationConfiguration.staggeredGrid(
                      position: index,
                      columnCount: 2,
                      duration: const Duration(milliseconds: 375),
                      child: ScaleAnimation(
                        child: FadeInAnimation(
                          child: _MoodCard(
                            mood: mood,
                            locale: locale,
                            isSelected: isSelected,
                            onTap: () => _selectMood(mood),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Results
          if (_selectedMood != null) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Row(
                  children: [
                    Text(_selectedMood!.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedMood!.getName(locale),
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            _selectedMood!.getDesc(locale),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Builder(
                builder: (context) {
                  final filteredRecipes = _filterRecipes(
                    provider.recipeService.recipes,
                    _selectedMood!.filter,
                  );

                  if (filteredRecipes.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Column(
                          children: [
                            const Text('🍽️', style: TextStyle(fontSize: 48)),
                            const SizedBox(height: 12),
                            Text(
                              isTr
                                  ? 'Bu ruh haline uygun tarif bulunamadı'
                                  : 'No recipes found for this mood',
                              style: theme.textTheme.bodyLarge,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return AnimationLimiter(
                    child: Column(
                      children: List.generate(filteredRecipes.length, (index) {
                        final recipe = filteredRecipes[index];
                        return AnimationConfiguration.staggeredList(
                          position: index,
                          duration: const Duration(milliseconds: 375),
                          child: SlideAnimation(
                            verticalOffset: 40,
                            child: FadeInAnimation(
                              child: _MoodRecipeCard(
                                recipe: recipe,
                                locale: locale,
                                moodColor: Color(_selectedMood!.color),
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
                      }),
                    ),
                  );
                },
              ),
            ),
          ],

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

class _MoodCard extends StatelessWidget {
  final MoodOption mood;
  final String locale;
  final bool isSelected;
  final VoidCallback onTap;

  const _MoodCard({
    required this.mood,
    required this.locale,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(mood.color);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isSelected
                ? [color, color.withOpacity(0.7)]
                : [color.withOpacity(0.15), color.withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color : color.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Text(mood.emoji, style: const TextStyle(fontSize: 24)),
                  const Spacer(),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.check, size: 14, color: color),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                mood.getName(locale),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? Colors.white : color.withOpacity(0.9),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                mood.getDesc(locale),
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? Colors.white70 : color.withOpacity(0.6),
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

class _MoodRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final String locale;
  final Color moodColor;
  final VoidCallback onTap;

  const _MoodRecipeCard({
    required this.recipe,
    required this.locale,
    required this.moodColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = locale == 'tr';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
              boxShadow: AppTheme.softShadow,
              border: Border.all(color: moodColor.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [moodColor.withOpacity(0.15), moodColor.withOpacity(0.05)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(recipe.imageEmoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe.getName(locale),
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.schedule, size: 13, color: theme.colorScheme.outline),
                          const SizedBox(width: 3),
                          Text('${recipe.totalTimeMinutes} ${isTr ? "dk" : "min"}',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: moodColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              recipe.getDifficultyText(locale),
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: moodColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: theme.colorScheme.outline, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
