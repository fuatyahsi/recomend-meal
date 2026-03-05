import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import 'ingredient_selection_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appName,
                          style: theme.textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.appTagline,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Language Toggle
                        TextButton(
                          onPressed: () => provider.toggleLanguage(),
                          child: Text(
                            provider.languageCode == 'tr' ? '🇬🇧 EN' : '🇹🇷 TR',
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Hero Section
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            '🧑‍🍳',
                            style: TextStyle(fontSize: 80),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        l10n.welcomeTitle,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          l10n.welcomeSubtitle,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Main Action Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const IngredientSelectionScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.kitchen, size: 24),
                    label: Text(
                      l10n.startCooking,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Quick Stats
                if (provider.selectedCount > 0)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            l10n.ingredientsSelected(provider.selectedCount),
                            style: theme.textTheme.bodyLarge,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const IngredientSelectionScreen(),
                              ),
                            );
                          },
                          child: Text(l10n.findRecipes),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 32),

                // Feature Cards
                Text(
                  provider.languageCode == 'tr'
                      ? 'Nasıl Çalışır?'
                      : 'How It Works?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _FeatureCard(
                  icon: '🧊',
                  title: provider.languageCode == 'tr'
                      ? 'Malzemelerini Seç'
                      : 'Select Ingredients',
                  description: provider.languageCode == 'tr'
                      ? 'Buzdolabında ve stoğundaki malzemeleri işaretle'
                      : 'Mark the ingredients in your fridge and stock',
                  color: Colors.blue.shade50,
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  icon: '🔍',
                  title: provider.languageCode == 'tr'
                      ? 'Tarif Bul'
                      : 'Find Recipes',
                  description: provider.languageCode == 'tr'
                      ? 'Malzemelerine uygun tarifleri keşfet'
                      : 'Discover recipes matching your ingredients',
                  color: Colors.green.shade50,
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  icon: '👨‍🍳',
                  title: provider.languageCode == 'tr'
                      ? 'Adım Adım Pişir'
                      : 'Cook Step by Step',
                  description: provider.languageCode == 'tr'
                      ? 'Detaylı hazırlanış adımlarını takip et'
                      : 'Follow detailed preparation steps',
                  color: Colors.orange.shade50,
                ),
                const SizedBox(height: 12),
                _FeatureCard(
                  icon: '⚠️',
                  title: provider.languageCode == 'tr'
                      ? 'Eksik Malzeme Uyarısı'
                      : 'Missing Ingredient Alert',
                  description: provider.languageCode == 'tr'
                      ? 'Eksik malzemeleri göster, alışveriş listeni oluştur'
                      : 'See missing ingredients and build your shopping list',
                  color: Colors.red.shade50,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
