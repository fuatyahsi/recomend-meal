import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/ingredient.dart';
import '../providers/app_provider.dart';
import 'recipe_list_screen.dart';

class IngredientSelectionScreen extends StatefulWidget {
  const IngredientSelectionScreen({super.key});

  @override
  State<IngredientSelectionScreen> createState() =>
      _IngredientSelectionScreenState();
}

class _IngredientSelectionScreenState extends State<IngredientSelectionScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = provider.languageCode;

    final allIngredients = provider.recipeService.ingredients;
    final grouped = provider.recipeService.getIngredientsByCategory();
    final categories = grouped.keys.toList();

    // Filter ingredients
    List<Ingredient> filteredIngredients;
    if (_searchQuery.isNotEmpty) {
      filteredIngredients = provider.recipeService
          .searchIngredients(_searchQuery, locale);
    } else if (_selectedCategory != null) {
      filteredIngredients = grouped[_selectedCategory] ?? [];
    } else {
      filteredIngredients = allIngredients;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectIngredients),
        actions: [
          if (provider.selectedCount > 0)
            TextButton.icon(
              onPressed: () => provider.clearSelectedIngredients(),
              icon: const Icon(Icons.clear_all),
              label: Text(l10n.clearAll),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: l10n.searchIngredients,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
          ),

          // Category Filter Chips
          if (_searchQuery.isEmpty)
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(l10n.all),
                      selected: _selectedCategory == null,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = null),
                    ),
                  ),
                  ...categories.map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                              IngredientCategory.getName(cat, locale)),
                          selected: _selectedCategory == cat,
                          onSelected: (_) => setState(
                              () => _selectedCategory = cat),
                        ),
                      )),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Selected count banner
          if (provider.selectedCount > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.ingredientsSelected(provider.selectedCount),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 8),

          // Ingredient Grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.9,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: filteredIngredients.length,
              itemBuilder: (context, index) {
                final ingredient = filteredIngredients[index];
                final isSelected =
                    provider.isIngredientSelected(ingredient.id);
                return _IngredientCard(
                  ingredient: ingredient,
                  locale: locale,
                  isSelected: isSelected,
                  onTap: () => provider.toggleIngredient(ingredient.id),
                );
              },
            ),
          ),
        ],
      ),

      // Find Recipes FAB
      floatingActionButton: provider.selectedCount > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                provider.findRecipes();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const RecipeListScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.restaurant_menu),
              label: Text(
                '${l10n.findRecipes} (${provider.selectedCount})',
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            )
          : null,
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final Ingredient ingredient;
  final String locale;
  final bool isSelected;
  final VoidCallback onTap;

  const _IngredientCard({
    required this.ingredient,
    required this.locale,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              ingredient.icon,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 6),
            Text(
              ingredient.getName(locale),
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
