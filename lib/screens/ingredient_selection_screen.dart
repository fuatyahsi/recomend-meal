import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/ingredient.dart';
import '../models/smart_kitchen.dart';
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
  String? _selectedCollectionId;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String value) {
    setState(() {
      _searchQuery = value;
      if (value.isNotEmpty) {
        _selectedCategory = null;
        _selectedCollectionId = null;
      }
    });
  }

  void _selectCategory(String? category) {
    setState(() {
      _selectedCategory = category;
      _selectedCollectionId = null;
    });
  }

  void _toggleCollection(String collectionId) {
    setState(() {
      _selectedCollectionId =
          _selectedCollectionId == collectionId ? null : collectionId;
      if (_selectedCollectionId != null) {
        _selectedCategory = null;
      }
    });
  }

  List<Ingredient> _sortIngredients(
    Iterable<Ingredient> ingredients,
    String locale,
  ) {
    final sorted = ingredients.toList()
      ..sort((a, b) => a.getName(locale).compareTo(b.getName(locale)));
    return sorted;
  }

  List<Ingredient> _ingredientsFromIds(
    AppProvider provider,
    Iterable<String> ingredientIds,
    String locale,
  ) {
    final items = ingredientIds
        .map(provider.recipeService.getIngredientById)
        .whereType<Ingredient>();
    return _sortIngredients(items, locale);
  }

  List<String> _stapleIds() {
    return const [
      'tomato',
      'onion',
      'garlic',
      'egg',
      'bread',
      'olive_oil',
      'salt',
      'black_pepper',
      'rice',
      'pasta',
      'milk',
      'butter',
      'yogurt',
      'lemon',
      'tomato_paste',
    ];
  }

  List<_IngredientCollection> _buildCollections(bool isTr) {
    return [
      _IngredientCollection(
        id: 'breakfast',
        title: isTr ? 'Kahvaltılık hızlı seçim' : 'Breakfast quick picks',
        subtitle: isTr
            ? 'Yumurta, peynir, ekmek ve sabah temel malzemeleri.'
            : 'Eggs, cheese, bread, and breakfast staples.',
        icon: Icons.free_breakfast_rounded,
        ingredientIds: const [
          'egg',
          'bread',
          'cheese_white',
          'cheese_kashar',
          'olive',
          'tomato',
          'cucumber',
          'butter',
          'tea',
          'milk',
          'honey',
          'jam',
        ],
      ),
      _IngredientCollection(
        id: 'turkish_pantry',
        title: isTr ? 'Türk mutfağı temeli' : 'Turkish pantry base',
        subtitle: isTr
            ? 'Tencere yemekleri ve klasik tarifler için çekirdek set.'
            : 'Core items for Turkish home cooking.',
        icon: Icons.soup_kitchen_rounded,
        ingredientIds: const [
          'onion',
          'garlic',
          'tomato',
          'tomato_paste',
          'olive_oil',
          'rice',
          'bulgur',
          'lentil_red',
          'chickpea',
          'white_bean',
          'salt',
          'black_pepper',
          'cumin',
          'parsley',
        ],
      ),
      _IngredientCollection(
        id: 'salad_meze',
        title: isTr ? 'Salata ve meze' : 'Salad and meze',
        subtitle: isTr
            ? 'Ferah tabaklar, zeytinyağlılar ve mezeler için.'
            : 'Fresh plates, olive oil dishes, and mezes.',
        icon: Icons.eco_rounded,
        ingredientIds: const [
          'tomato',
          'cucumber',
          'lettuce',
          'parsley',
          'dill',
          'olive_oil',
          'lemon',
          'olive',
          'yogurt',
          'pomegranate_syrup',
          'mint_dried',
          'cheese_white',
        ],
      ),
      _IngredientCollection(
        id: 'proteins',
        title: isTr ? 'Akşam ve protein' : 'Dinner and protein',
        subtitle: isTr
            ? 'Ana yemekler için protein ağırlıklı set.'
            : 'Protein-forward picks for main dishes.',
        icon: Icons.set_meal_rounded,
        ingredientIds: const [
          'chicken',
          'chicken_breast',
          'ground_beef',
          'beef_cubes',
          'fish',
          'salmon',
          'egg',
          'rice',
          'pasta',
          'onion',
          'garlic',
          'black_pepper',
        ],
      ),
      _IngredientCollection(
        id: 'dessert_baking',
        title: isTr ? 'Tatlı ve fırın' : 'Dessert and baking',
        subtitle: isTr
            ? 'Tatlı, krep, kek ve fırın tarifleri için.'
            : 'For desserts, crepes, cakes, and baked treats.',
        icon: Icons.cake_rounded,
        ingredientIds: const [
          'flour',
          'sugar',
          'butter',
          'milk',
          'egg',
          'cocoa',
          'vanilla',
          'cinnamon',
          'baking_powder',
          'baking_soda',
          'chocolate',
          'honey',
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = provider.languageCode;
    final isTr = locale == 'tr';

    final allIngredients = _sortIngredients(
      provider.recipeService.ingredients,
      locale,
    );
    final grouped = provider.recipeService.getIngredientsByCategory();
    final categories = [
      ...IngredientCategory.orderedValues.where(grouped.containsKey),
      ...grouped.keys.where(
        (category) => !IngredientCategory.orderedValues.contains(category),
      ),
    ];
    final pantryItems = provider.pantryItems;
    final stapleIngredients = _ingredientsFromIds(
      provider,
      _stapleIds(),
      locale,
    );
    final collections = _buildCollections(isTr);
    _IngredientCollection? activeCollection;
    for (final collection in collections) {
      if (collection.id == _selectedCollectionId) {
        activeCollection = collection;
        break;
      }
    }

    List<Ingredient> filteredIngredients;
    if (_searchQuery.isNotEmpty) {
      filteredIngredients = _sortIngredients(
        provider.recipeService.searchIngredients(_searchQuery, locale),
        locale,
      );
    } else if (activeCollection != null) {
      filteredIngredients = _ingredientsFromIds(
        provider,
        activeCollection.ingredientIds,
        locale,
      );
    } else if (_selectedCategory != null) {
      filteredIngredients = _sortIngredients(
        grouped[_selectedCategory] ?? const [],
        locale,
      );
    } else {
      filteredIngredients = allIngredients;
    }

    final defaultBrowseMode = _searchQuery.isEmpty &&
        _selectedCategory == null &&
        _selectedCollectionId == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectIngredients),
        actions: [
          if (provider.selectedCount > 0)
            TextButton.icon(
              onPressed: provider.clearSelectedIngredients,
              icon: const Icon(Icons.clear_all),
              label: Text(l10n.clearAll),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _IngredientHeroCard(isTr: isTr),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _updateSearch,
              decoration: InputDecoration(
                hintText: l10n.searchIngredients,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _updateSearch('');
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
                      selected: _selectedCategory == null &&
                          _selectedCollectionId == null,
                      onSelected: (_) => _selectCategory(null),
                    ),
                  ),
                  ...categories.map(
                    (category) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(
                          IngredientCategory.getName(category, locale),
                        ),
                        selected: _selectedCategory == category,
                        onSelected: (_) => _selectCategory(category),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (activeCollection != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _ActiveCollectionBanner(
                collection: activeCollection,
                isTr: isTr,
                onClear: () => _toggleCollection(activeCollection!.id),
              ),
            ),
          const SizedBox(height: 8),
          if (provider.selectedCount > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
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
          if (pantryItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _PantryListCard(
                locale: locale,
                pantryItems: pantryItems,
                onIncrement: provider.incrementIngredient,
                onDecrement: provider.decrementIngredient,
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: defaultBrowseMode
                ? ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    children: [
                      _BrowseSummaryCard(
                        locale: locale,
                        ingredientCount: allIngredients.length,
                        categoryCount: categories.length,
                      ),
                      const SizedBox(height: 16),
                      _StapleFavoritesCard(
                        locale: locale,
                        ingredients: stapleIngredients,
                        provider: provider,
                        onAddMissing: () {
                          provider.addMissingIngredients(
                            stapleIngredients.map((item) => item.id),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        isTr
                            ? 'Türk mutfağı için hızlı gruplar'
                            : 'Quick groups for your kitchen',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...collections.map(
                        (collection) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _QuickCollectionCard(
                            collection: collection,
                            locale: locale,
                            selectedCount: collection.ingredientIds
                                .where(provider.isIngredientSelected)
                                .length,
                            onShow: () => _toggleCollection(collection.id),
                            onAddMissing: () =>
                                provider.addMissingIngredients(
                              collection.ingredientIds,
                            ),
                            isActive:
                                _selectedCollectionId == collection.id,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...categories.map(
                        (category) => Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _IngredientCategorySection(
                            title: IngredientCategory.getName(category, locale),
                            locale: locale,
                            ingredients: _sortIngredients(
                              grouped[category] ?? const [],
                              locale,
                            ),
                            provider: provider,
                          ),
                        ),
                      ),
                    ],
                  )
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
                      final count = provider.getIngredientCount(ingredient.id);
                      return _IngredientCard(
                        ingredient: ingredient,
                        locale: locale,
                        isSelected: isSelected,
                        count: count,
                        onTap: () => provider.toggleIngredient(ingredient.id),
                      );
                    },
                  ),
          ),
        ],
      ),
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
              label: Text('${l10n.findRecipes} (${provider.selectedCount})'),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _IngredientCollection {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<String> ingredientIds;

  const _IngredientCollection({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.ingredientIds,
  });
}

class _IngredientHeroCard extends StatelessWidget {
  final bool isTr;

  const _IngredientHeroCard({required this.isTr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6C3F2C),
            Color(0xFFB76A3E),
            Color(0xFFF0B36A),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB76A3E).withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: const Icon(
              Icons.inventory_2_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            isTr ? 'Buzdolabında Ne Var?' : 'What is in your fridge?',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            isTr
                ? 'Evde olanları işaretle, tarif önerileri netleşsin ve eksikler doğru çıksın.'
                : 'Mark what you already have so recipe suggestions and shopping gaps become more accurate.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrowseSummaryCard extends StatelessWidget {
  final String locale;
  final int ingredientCount;
  final int categoryCount;

  const _BrowseSummaryCard({
    required this.locale,
    required this.ingredientCount,
    required this.categoryCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = locale == 'tr';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.inventory_2_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isTr
                      ? 'Dolabini guncel tut, oneriler netlessin'
                      : 'Keep your pantry current to improve suggestions',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isTr
                ? 'Toplam $ingredientCount malzeme ve $categoryCount kategori icinden hizli secim yapabilirsin.'
                : 'Browse $ingredientCount ingredients across $categoryCount categories.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatPill(
                label: isTr ? 'Toplam malzeme' : 'Ingredients',
                value: '$ingredientCount',
              ),
              _StatPill(
                label: isTr ? 'Kategori' : 'Categories',
                value: '$categoryCount',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.62),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StapleFavoritesCard extends StatelessWidget {
  final String locale;
  final List<Ingredient> ingredients;
  final AppProvider provider;
  final VoidCallback onAddMissing;

  const _StapleFavoritesCard({
    required this.locale,
    required this.ingredients,
    required this.provider,
    required this.onAddMissing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = locale == 'tr';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star_rounded,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isTr
                      ? 'Temel mutfak malzemeleri'
                      : 'Kitchen staples',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onAddMissing,
                icon: const Icon(Icons.add_shopping_cart_rounded),
                label: Text(isTr ? 'Eksikleri ekle' : 'Add missing'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            isTr
                ? 'En cok kullanilan temel malzemeleri tek dokunusla dolabina ekle.'
                : 'Add common staples to your pantry in one tap.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ingredients.map((ingredient) {
              final isSelected = provider.isIngredientSelected(ingredient.id);
              final count = provider.getIngredientCount(ingredient.id);
              return FilterChip(
                avatar: Text(ingredient.icon),
                label: Text(
                  isSelected && count > 1
                      ? '${ingredient.getName(locale)} ($count)'
                      : ingredient.getName(locale),
                ),
                selected: isSelected,
                onSelected: (_) => provider.toggleIngredient(ingredient.id),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _QuickCollectionCard extends StatelessWidget {
  final _IngredientCollection collection;
  final String locale;
  final int selectedCount;
  final VoidCallback onShow;
  final VoidCallback onAddMissing;
  final bool isActive;

  const _QuickCollectionCard({
    required this.collection,
    required this.locale,
    required this.selectedCount,
    required this.onShow,
    required this.onAddMissing,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = locale == 'tr';

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onShow,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isActive
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    collection.icon,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        collection.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        collection.subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _MiniLabel(
                  label: isTr
                      ? '${collection.ingredientIds.length} malzeme'
                      : '${collection.ingredientIds.length} items',
                ),
                _MiniLabel(
                  label: isTr
                      ? '$selectedCount secili'
                      : '$selectedCount selected',
                ),
                if (isActive)
                  _MiniLabel(
                    label: isTr ? 'Su an gorunuyor' : 'Now browsing',
                    highlighted: true,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onShow,
                    icon: Icon(
                      isActive
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    label: Text(
                      isActive
                          ? (isTr ? 'Kapat' : 'Hide')
                          : (isTr ? 'Grubu ac' : 'Open group'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: onAddMissing,
                    icon: const Icon(Icons.add_home_work_rounded),
                    label: Text(isTr ? 'Eksikleri ekle' : 'Add missing'),
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

class _MiniLabel extends StatelessWidget {
  final String label;
  final bool highlighted;

  const _MiniLabel({
    required this.label,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlighted
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: highlighted
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActiveCollectionBanner extends StatelessWidget {
  final _IngredientCollection collection;
  final bool isTr;
  final VoidCallback onClear;

  const _ActiveCollectionBanner({
    required this.collection,
    required this.isTr,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(collection.icon, color: theme.colorScheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  collection.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isTr
                      ? 'Bu hizli grup acik. Kapatirsan tum malzemelere donersin.'
                      : 'This quick group is open. Close it to return to all ingredients.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }
}

class _IngredientCategorySection extends StatelessWidget {
  final String title;
  final String locale;
  final List<Ingredient> ingredients;
  final AppProvider provider;

  const _IngredientCategorySection({
    required this.title,
    required this.locale,
    required this.ingredients,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${ingredients.length}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 0.9,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: ingredients.length,
          itemBuilder: (context, index) {
            final ingredient = ingredients[index];
            final isSelected = provider.isIngredientSelected(ingredient.id);
            final count = provider.getIngredientCount(ingredient.id);
            return _IngredientCard(
              ingredient: ingredient,
              locale: locale,
              isSelected: isSelected,
              count: count,
              onTap: () => provider.toggleIngredient(ingredient.id),
            );
          },
        ),
      ],
    );
  }
}

class _IngredientCard extends StatelessWidget {
  final Ingredient ingredient;
  final String locale;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  const _IngredientCard({
    required this.ingredient,
    required this.locale,
    required this.isSelected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 1.6,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                ingredient.icon,
                style: const TextStyle(fontSize: 30),
              ),
              const SizedBox(height: 6),
              Text(
                ingredient.getName(locale),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              AnimatedOpacity(
                opacity: isSelected ? 1 : 0,
                duration: const Duration(milliseconds: 180),
                child: isSelected
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '${count}x',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    : const SizedBox(height: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PantryListCard extends StatelessWidget {
  final String locale;
  final List<PantryStockItem> pantryItems;
  final ValueChanged<String> onIncrement;
  final ValueChanged<String> onDecrement;

  const _PantryListCard({
    required this.locale,
    required this.pantryItems,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = locale == 'tr';
    final calculatedHeight =
        (pantryItems.length * 56.0).clamp(56.0, 280.0).toDouble();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.kitchen_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isTr ? 'Dolaptaki malzemeler' : 'Pantry items',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isTr
                ? 'Kullandikca azalt, aldikca artir. Menu ve alisveris listesi buna gore guncellensin.'
                : 'Decrease items as you use them and increase them as you restock.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: calculatedHeight),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: pantryItems.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = pantryItems[index];
                return _PantryListTile(
                  item: item,
                  locale: locale,
                  onIncrement: () => onIncrement(item.ingredient.id),
                  onDecrement: () => onDecrement(item.ingredient.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PantryListTile extends StatelessWidget {
  final PantryStockItem item;
  final String locale;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _PantryListTile({
    required this.item,
    required this.locale,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Text(item.ingredient.icon, style: const TextStyle(fontSize: 24)),
      title: Text(item.ingredient.getName(locale)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onDecrement,
            icon: const Icon(Icons.remove_circle_outline),
            color: theme.colorScheme.primary,
          ),
          Container(
            constraints: const BoxConstraints(minWidth: 34),
            alignment: Alignment.center,
            child: Text(
              '${item.count}',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            onPressed: onIncrement,
            icon: const Icon(Icons.add_circle_outline),
            color: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}
