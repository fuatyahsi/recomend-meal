import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
  bool _isScanning = false;
  bool _isAnalyzing = false;

  Future<void> _pickReceiptImage(
    AppProvider provider,
    ImageSource source,
  ) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1800,
      imageQuality: 88,
    );
    if (picked == null) return;
    setState(() => _isScanning = true);
    try {
      await provider.analyzeReceiptImage(picked.path);
      if (mounted) {
        _receiptController.text = provider.lastReceiptScanResult?.rawText ?? '';
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _pickPlateImage(
    AppProvider provider,
    ImageSource source,
  ) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1800,
      imageQuality: 88,
    );
    if (picked == null) return;
    setState(() => _isAnalyzing = true);
    try {
      await provider.analyzePlateImage(picked.path);
      if (mounted) {
        _plateController.text =
            provider.lastPlateAnalysisResult?.analysisPrompt ?? '';
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

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
        title: Text(isTr ? 'Görsel Analiz Merkezi' : 'Visual Analysis Hub'),
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
            title: isTr ? 'Fiş Tarayıcı' : 'Receipt Scanner',
            subtitle: isTr
                ? 'Fiş metnini yapıştır ya da fotoğraf çek. Eşleşen malzemeleri dolaba otomatik ekleyelim.'
                : 'Paste receipt text and auto-add matched ingredients to your pantry.',
            child: Column(
              children: [
                _ImageActionRow(
                  isTr: isTr,
                  isBusy: _isScanning,
                  onCamera: () =>
                      _pickReceiptImage(provider, ImageSource.camera),
                  onGallery: () =>
                      _pickReceiptImage(provider, ImageSource.gallery),
                ),
                if (receiptResult?.capturedImagePath != null) ...[
                  const SizedBox(height: 12),
                  _PickedImagePreview(path: receiptResult!.capturedImagePath!),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _receiptController,
                  minLines: 4,
                  maxLines: 7,
                  decoration: InputDecoration(
                    hintText: isTr
                        ? 'Örnek:\nYumurta\nDomates\nKaşar peyniri\nZeytinyağı'
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
                              ? (isTr ? 'Taranıyor' : 'Scanning')
                              : (isTr ? 'Fişi tara' : 'Scan receipt'),
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
            title: isTr ? 'Tabak Analizi' : 'Plate Analysis',
            subtitle: isTr
                ? 'Yemeği tarif et; benzer tabakları, ruh hâli uyumunu ve paylaşım metnini hazırlayalım.'
                : 'Describe the dish and get likely matches, mood fit, and a share caption.',
            child: Column(
              children: [
                _ImageActionRow(
                  isTr: isTr,
                  isBusy: _isAnalyzing,
                  onCamera: () => _pickPlateImage(provider, ImageSource.camera),
                  onGallery: () =>
                      _pickPlateImage(provider, ImageSource.gallery),
                ),
                if (plateResult?.capturedImagePath != null) ...[
                  const SizedBox(height: 12),
                  _PickedImagePreview(path: plateResult!.capturedImagePath!),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _plateController,
                  minLines: 4,
                  maxLines: 7,
                  decoration: InputDecoration(
                    hintText: isTr
                        ? 'Örnek:\nKremalı mantarlı makarna, dereotu ve limon kabuğu ile servis'
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
                              : (isTr ? 'Tabağı analiz et' : 'Analyze plate'),
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
                  isTr ? 'Görsel Analiz Merkezi' : 'Visual Analysis Hub',
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
                ? 'Artık hem metin hem görsel akışı var: fişi çek, tabağı analiz et, dolap ve tarif önerilerini birlikte çalıştıralım.'
                : 'Vision now supports both text and image flows: scan a receipt, analyze a plate, and let pantry, mood, and recipe engines work together.',
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

class _ImageActionRow extends StatelessWidget {
  final bool isTr;
  final bool isBusy;
  final VoidCallback onCamera;
  final VoidCallback onGallery;

  const _ImageActionRow({
    required this.isTr,
    required this.isBusy,
    required this.onCamera,
    required this.onGallery,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isBusy ? null : onCamera,
            icon: const Icon(Icons.photo_camera_outlined),
            label: Text(isTr ? 'Kamera' : 'Camera'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isBusy ? null : onGallery,
            icon: const Icon(Icons.photo_library_outlined),
            label: Text(isTr ? 'Galeri' : 'Gallery'),
          ),
        ),
      ],
    );
  }
}

class _PickedImagePreview extends StatelessWidget {
  final String path;

  const _PickedImagePreview({required this.path});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.file(
        File(path),
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
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
                ? 'Eşleşme güveni: %${(result.confidence * 100).round()}'
                : 'Match confidence: %${(result.confidence * 100).round()}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (result.detectedStore != null) ...[
            const SizedBox(height: 8),
            Text(
              isTr
                  ? 'Algılanan market: ${result.detectedStore}'
                  : 'Detected store: ${result.detectedStore}',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (result.matchedIngredients.isEmpty)
            Text(
              isTr
                  ? 'Eşleşen malzeme bulunamadı.'
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
          if (result.detectedLabels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              isTr ? 'Görsel ipuçları' : 'Visual hints',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.detectedLabels
                  .map((label) => Chip(label: Text(label)))
                  .toList(),
            ),
          ],
          if (result.rawText.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              isTr ? 'OCR metni' : 'OCR text',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(result.rawText),
          ],
          if (result.unmatchedLines.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              isTr ? 'Eşleşmeyen satırlar' : 'Unmatched lines',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar:
                    const Icon(Icons.local_fire_department_outlined, size: 16),
                label: Text(
                  isTr
                      ? '~${result.estimatedCalories} kcal'
                      : '~${result.estimatedCalories} kcal',
                ),
              ),
              Chip(
                avatar: const Icon(Icons.speed_outlined, size: 16),
                label: Text(
                  isTr
                      ? '%${(result.confidence * 100).round()} güven'
                      : '%${(result.confidence * 100).round()} confidence',
                ),
              ),
            ],
          ),
          if (result.detectedLabels.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.detectedLabels
                  .map((label) => Chip(label: Text(label)))
                  .toList(),
            ),
          ],
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
          if (result.analysisPrompt.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              isTr ? 'Analiz notu' : 'Analysis prompt',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(result.analysisPrompt),
          ],
          if (result.matchedRecipes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              isTr ? 'Benzer tarifler' : 'Closest recipe matches',
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
