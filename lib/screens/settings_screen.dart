import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/app_provider.dart';
import '../utils/app_theme.dart';
import 'smart_kitchen_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isTr = provider.languageCode == 'tr';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(isTr ? 'Ayarlar' : 'Settings'),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.16),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.16, 1.0],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFFE0D3), Color(0xFFFFF1EB)],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: AppTheme.softShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      Icons.tune_rounded,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isTr
                              ? 'Az ayar, çok akıl'
                              : 'Less settings, more intelligence',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isTr
                              ? 'Kritik kontroller burada. Geri kalanını uygulama seni tanıdıkça arkada öğrenir.'
                              : 'The critical controls stay here. The rest adapts quietly as the app learns from you.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language_rounded),
                    title: Text(isTr ? 'Dil' : 'Language'),
                    subtitle: Text(
                      provider.languageCode == 'tr' ? 'Türkçe' : 'English',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _LanguageOption(
                            flag: 'TR',
                            label: 'Türkçe',
                            isSelected: provider.languageCode == 'tr',
                            onTap: () => provider.setLocale(const Locale('tr')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LanguageOption(
                            flag: 'EN',
                            label: 'English',
                            isSelected: provider.languageCode == 'en',
                            onTap: () => provider.setLocale(const Locale('en')),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.softShadow,
              ),
              child: SwitchListTile(
                secondary: Icon(
                  provider.isDarkMode
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                ),
                title: Text(l10n.darkMode),
                subtitle: Text(
                  isTr
                      ? 'Görünümü tek dokunuşla değiştir.'
                      : 'Switch the overall mood with one tap.',
                ),
                value: provider.isDarkMode,
                onChanged: (_) => provider.toggleDarkMode(),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.softShadow,
              ),
              child: ListTile(
                leading: const Icon(Icons.auto_awesome_rounded),
                title: Text(
                  isTr
                      ? 'Akıllı mutfak tercihleri'
                      : 'Smart kitchen preferences',
                ),
                subtitle: Text(
                  isTr
                      ? 'Marketlerin, rutinlerin ve tasarruf akışın burada.'
                      : 'Your markets, routines, and savings flow live here.',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SmartKitchenScreen()),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTr ? 'Nasıl sadeleşiyor?' : 'How it stays simple',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SettingsBullet(
                    text: isTr
                        ? 'Market seçimlerin ve mutfak davranışların önerileri arkada şekillendirir.'
                        : 'Your market choices and kitchen behavior shape suggestions in the background.',
                  ),
                  _SettingsBullet(
                    text: isTr
                        ? 'Manuel giriş yerine fotoğraf, OCR ve senkron akışlarını büyütüyoruz.'
                        : 'We prioritize photo, OCR, and sync flows over manual entry.',
                  ),
                  _SettingsBullet(
                    text: isTr
                        ? 'Topluluk tarifleri keşif akışının ana parçası oluyor.'
                        : 'Community recipes are becoming a core part of discovery.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.kitchen_rounded,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'BuzdolabıŞef',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${l10n.version} 1.0.0',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    isTr
                        ? 'Mutfağını yöneten, tasarruf ettiren ve ne pişireceğini hızla söyleyen yardımcın.'
                        : 'The assistant that manages your kitchen, saves money, and helps decide what to cook.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              flag,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsBullet extends StatelessWidget {
  final String text;

  const _SettingsBullet({required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            margin: const EdgeInsets.only(top: 1),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(
              Icons.check_rounded,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
