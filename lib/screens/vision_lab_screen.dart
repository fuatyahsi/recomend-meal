import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/kitchen_intelligence.dart';
import '../models/recipe.dart';
import '../providers/app_provider.dart';
import 'recipe_detail_screen.dart';

class VisionLabScreen extends StatefulWidget {
  const VisionLabScreen({super.key});

  @override
  State<VisionLabScreen> createState() => _VisionLabScreenState();
}

class _VisionLabScreenState extends State<VisionLabScreen> {
  final TextEditingController _receiptController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  bool _isScanning = false;
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _receiptController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  Future<void> _scanReceipt(AppProvider provider) async {
    if (_receiptController.text.trim().isEmpty) return;
    setState(() => _isScanning = true);
    await provider.analyzeReceiptText(_receiptController.text.trim());
    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  Future<void> _analyzePlate(AppProvider provider) async {
    if (_plateController.text.trim().isEmpty) return;
    setState(() => _isAnalyzing = true);
    await provider.analyzePlateDescription(_plateController.text.trim());
    if (mounted) {
      setState(() => _isAnalyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isTr = provider.languageCode == 'tr';
    final receiptResult = provider.lastReceiptScanResult;
    final plateResult = provider.lastPlateAnalysisResult;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTr ? 'Food AI Vision Lab' : 'Food AI Vision Lab'),
        actions: [
          IconButton(
            onPressed: provider.clearVisionResults,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _VisionHeroCard(isTr: isTr),
          const SizedBox(height: 16),
          _LabCard(
            icon: Icons.receipt_long_rounded,
            title: isTr ? 'Shopping Scanner' : 'Shopping Scanner',
            subtitle: isTr
                ? 'Fis metnini yapistir. Eslesen malzemeler dolabina otomatik eklensin.'
                : 'Paste receipt text and auto-add matched ingredients to your pantry.',
            child: Column(
              children: [
                TextField(
                  controller: _receiptController,
                  minLines: 4,
                  maxLines: 7,
                  decoration: InputDecoration(
                    hintText: isTr
                        ? 'Ornek:\nYumurta\nDomates\nKasar peyniri\nZeytinyagi'
                        : 'Example:\nEggs\nTomato\nCheddar\nOlive oil',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed:
                            _isScanning ? null : () => _scanReceipt(provider),
                        icon: Icon(
                          _isScanning
                              ? Icons.hourglass_top_rounded
                              : Icons.document_scanner_outlined,
                        ),
                        label: Text(
                          _isScanning
                              ? (isTr ? 'Taraniyor' : 'Scanning')
                              : (isTr ? 'Fisi tara' : 'Scan receipt'),
                        ),
                      ),
                    ),
                  ],
                ),
                if (receiptResult != null) ...[
                  const SizedBox(height: 14),
                  _ReceiptResultCard(
                    isTr: isTr,
                    result: receiptResult,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _LabCard(
            icon: Icons.auto_awesome_rounded,
            title: isTr ? 'AI Tabak Analizi' : 'AI Plate Analysis',
            subtitle: isTr
                ? 'Yemegi tarif et, uygulama benzer tabaklari, mood uyumunu ve paylasim caption\'ini hazirlasin.'
                : 'Describe the dish and get likely matches, mood fit, and a share caption.',
            child: Column(
              children: [
                TextField(
                  controller: _plateController,
                  minLines: 4,
                  maxLines: 7,
                  decoration: InputDecoration(
                    hintText: isTr
                        ? 'Ornek:\nKremali mantarli makarna, dereotu ve limon kabugu ile servis'
                        : 'Example:\nCreamy mushroom pasta finished with dill and lemon zest',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed:
                            _isAnalyzing ? null : () => _analyzePlate(provider),
                        icon: Icon(
                          _isAnalyzing
                              ? Icons.hourglass_top_rounded
                              : Icons.photo_camera_back_outlined,
                        ),
                        label: Text(
                          _isAnalyzing
                              ? (isTr ? 'Analiz ediliyor' : 'Analyzing')
                              : (isTr ? 'Tabagi analiz et' : 'Analyze plate'),
                        ),
                      ),
                    ),
                  ],
                ),
                if (plateResult != null) ...[
                  const SizedBox(height: 14),
                  _PlateResultCard(
                    isTr: isTr,
                    result: plateResult,
                    onOpenRecipe: (recipe) => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailScreen(recipe: recipe),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VisionHeroCard extends StatelessWidget {
  final bool isTr;

  const _VisionHeroCard({required this.isTr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF071D33),
            Color(0xFF127DA1),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child:
                    const Icon(Icons.visibility_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isTr ? 'Food AI Vision MVP' : 'Food AI Vision MVP',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isTr
                ? 'Bugun metin tabanli akiyor: fis veya tabak aciklamasi ver, dolap, mood ve tarif motoru birlikte calissin. Sonraki fazda bunu kamera/OCR hattina tasiyabiliriz.'
                : 'This MVP runs on text today: provide receipt or plate notes and let pantry, mood, and recipe engines work together.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _LabCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _LabCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _ReceiptResultCard extends StatelessWidget {
  final bool isTr;
  final ReceiptScanResult result;

  const _ReceiptResultCard({
    required this.isTr,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isTr
                ? 'Eslesme guveni: %${(result.confidence * 100).round()}'
                : 'Match confidence: %${(result.confidence * 100).round()}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (result.matchedIngredients.isEmpty)
            Text(
              isTr
                  ? 'Eslesen malzeme bulunamadi.'
                  : 'No ingredients were matched.',
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.matchedIngredients.map<Widget>((ingredient) {
                return Chip(
                  avatar: Text(ingredient.icon),
                  label: Text(ingredient.getName(isTr ? 'tr' : 'en')),
                );
              }).toList(),
            ),
          if (result.unmatchedLines.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              isTr ? 'Eslesmeyen satirlar' : 'Unmatched lines',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ...result.unmatchedLines.map<Widget>((line) => Text('• $line')),
          ],
        ],
      ),
    );
  }
}

class _PlateResultCard extends StatelessWidget {
  final bool isTr;
  final PlateAnalysisResult result;
  final ValueChanged<Recipe> onOpenRecipe;

  const _PlateResultCard({
    required this.isTr,
    required this.result,
    required this.onOpenRecipe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            result.headline(isTr ? 'tr' : 'en'),
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(result.summary(isTr ? 'tr' : 'en')),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              result.shareCaption(isTr ? 'tr' : 'en'),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (result.matchedRecipes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              isTr ? 'En yakin tarifler' : 'Closest recipe matches',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            ...result.matchedRecipes.map<Widget>((recipe) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Text(recipe.imageEmoji,
                    style: const TextStyle(fontSize: 24)),
                title: Text(recipe.getName(isTr ? 'tr' : 'en')),
                subtitle: Text(
                  '${recipe.totalTimeMinutes} ${isTr ? 'dk' : 'min'}',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => onOpenRecipe(recipe),
              );
            }),
          ],
        ],
      ),
    );
  }
}
