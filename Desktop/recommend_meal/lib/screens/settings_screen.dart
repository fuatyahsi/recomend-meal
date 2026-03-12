import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settings),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language),
                  subtitle: Text(
                    provider.languageCode == 'tr'
                        ? l10n.turkish
                        : l10n.english,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: _LanguageOption(
                          flag: '🇹🇷',
                          label: l10n.turkish,
                          isSelected: provider.languageCode == 'tr',
                          onTap: () =>
                              provider.setLocale(const Locale('tr')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _LanguageOption(
                          flag: '🇬🇧',
                          label: l10n.english,
                          isSelected: provider.languageCode == 'en',
                          onTap: () =>
                              provider.setLocale(const Locale('en')),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Dark Mode
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: SwitchListTile(
              secondary: Icon(
                provider.isDarkMode
                    ? Icons.dark_mode
                    : Icons.light_mode,
              ),
              title: Text(l10n.darkMode),
              value: provider.isDarkMode,
              onChanged: (_) => provider.toggleDarkMode(),
            ),
          ),

          const SizedBox(height: 12),

          // About
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: Text(l10n.about),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Column(
                    children: [
                      const Text(
                        '🧑‍🍳',
                        style: TextStyle(fontSize: 48),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'FridgeChef',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${l10n.version} 1.0.0',
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        provider.languageCode == 'tr'
                            ? 'Buzdolabındaki malzemelere göre yemek tarifi öneren uygulama.'
                            : 'Recipe suggestion app based on your fridge ingredients.',
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.flag,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
