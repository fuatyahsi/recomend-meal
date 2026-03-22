import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/smart_actueller.dart';
import '../providers/app_provider.dart';
import '../services/smart_actueller_source_service.dart';

class SmartActuellerScreen extends StatefulWidget {
  const SmartActuellerScreen({super.key});

  @override
  State<SmartActuellerScreen> createState() => _SmartActuellerScreenState();
}

class _SmartActuellerScreenState extends State<SmartActuellerScreen> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isScanning = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _scanText(AppProvider provider) async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      return;
    }

    setState(() => _isScanning = true);
    try {
      await provider.analyzeActuellerText(text);
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _pickImage(AppProvider provider, ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      maxWidth: 1800,
      imageQuality: 88,
    );
    if (picked == null) {
      return;
    }

    setState(() => _isScanning = true);
    try {
      await provider.analyzeActuellerImage(picked.path);
      if (mounted) {
        _controller.text = provider.lastActuellerScanResult?.rawText ?? '';
      }
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  Future<void> _syncCatalog(AppProvider provider) async {
    setState(() => _isScanning = true);
    try {
      await provider.syncAkakceActuellerCatalog(force: true);
      if (mounted) {
        _controller.text = provider.lastActuellerScanResult?.rawText ?? '';
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isScanning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isTr = provider.languageCode == 'tr';
    final scanResult = provider.lastActuellerScanResult;
    final suggestions = provider.smartActuellerSuggestions;
    final isCatalogSyncing = provider.isActuellerCatalogSyncing;
    final catalogSyncAt = provider.lastActuellerCatalogSyncAt;
    final catalogBrochureCount = provider.lastActuellerCatalogBrochureCount;
    final catalogReports = provider.lastActuellerCatalogReports;
    final catalogMessage = provider.actuellerCatalogSyncMessage;
    final syncHour = provider.actuellerDailySyncHour;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isTr ? 'Smart Aktüel Asistanı' : 'Smart Flyer Assistant',
        ),
        actions: [
          IconButton(
            onPressed: isCatalogSyncing ? null : () => _syncCatalog(provider),
            icon: Icon(
              isCatalogSyncing
                  ? Icons.hourglass_top_rounded
                  : Icons.refresh_rounded,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ActuellerHeroCard(isTr: isTr),
          const SizedBox(height: 16),

          // ── Market Selector ──
          _MarketSelectorCard(isTr: isTr, provider: provider),
          const SizedBox(height: 16),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTr
                        ? 'Günlük broşürleri otomatik tara'
                        : 'Scan daily flyers automatically',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTr
                        ? 'Seçili marketlerin Akakçe üzerindeki broşürlerini her gün kontrol eder, ürün ve fiyat bilgilerini çıkarır, mutfağına uygun fırsatlara çevirir.'
                        : 'Checks your selected markets\' brochures on Akakçe daily, extracts product and price info, and turns them into useful kitchen deals.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTr
                        ? 'Planlı kontrol saati: her gün ${syncHour.toString().padLeft(2, '0')}:00'
                        : 'Scheduled check time: every day at ${syncHour.toString().padLeft(2, '0')}:00',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.tonalIcon(
                    onPressed: _isScanning || isCatalogSyncing
                        ? null
                        : () => _syncCatalog(provider),
                    icon: Icon(
                      isCatalogSyncing
                          ? Icons.hourglass_top_rounded
                          : Icons.cloud_download_outlined,
                    ),
                    label: Text(
                      isCatalogSyncing
                          ? (isTr
                              ? 'Bugünün broşürleri alınıyor'
                              : 'Fetching today\'s flyers')
                          : (isTr
                              ? 'Bugünün broşürlerini tara'
                              : 'Scan today\'s flyers'),
                    ),
                  ),
                  if (catalogSyncAt != null || catalogMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (catalogSyncAt != null)
                            Text(
                              isTr
                                  ? 'Son otomatik tarama: ${_formatDateTimeTr(catalogSyncAt)}'
                                  : 'Last automatic scan: ${_formatDateTimeEn(catalogSyncAt)}',
                            ),
                          if (catalogBrochureCount > 0) ...[
                            const SizedBox(height: 4),
                            Text(
                              isTr
                                  ? '$catalogBrochureCount broşür işlendi'
                                  : '$catalogBrochureCount flyers processed',
                            ),
                          ],
                          if (catalogMessage != null &&
                              catalogMessage.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(catalogMessage),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (catalogReports.isNotEmpty) ...[
            const SizedBox(height: 12),
            Card(
              child: ExpansionTile(
                title: Text(
                  isTr ? 'Bugünkü tarama ayrıntıları' : 'Today\'s scan details',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                subtitle: Text(
                  isTr
                      ? '${catalogReports.length} broşür kaydı'
                      : '${catalogReports.length} brochure records',
                ),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                children: catalogReports.map((report) {
                  final headline =
                      report.marketName?.isNotEmpty == true
                          ? report.marketName!
                          : report.sourceLabel;
                  final summary = isTr
                      ? '${report.itemCount} ürün, ${report.dealCount} mutfak eşleşmesi, ${report.imageCount} görsel, ${report.blockCount} blok'
                      : '${report.itemCount} items, ${report.dealCount} kitchen matches, ${report.imageCount} images, ${report.blockCount} blocks';
                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          headline,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(summary),
                        if (report.productNames.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            isTr
                                ? 'Bulunanlar: ${report.productNames.join(', ')}'
                                : 'Found: ${report.productNames.join(', ')}',
                          ),
                        ],
                        if (report.note != null && report.note!.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(report.note!),
                        ],
                        const SizedBox(height: 6),
                        SelectableText(
                          report.brochureUrl,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isTr ? 'Yedek tarama araçları' : 'Manual backup tools',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTr
                        ? 'İstersen kendi broşür fotoğrafını çekebilir veya OCR metnini elle yapıştırabilirsin.'
                        : 'You can still capture your own flyer image or paste OCR text manually.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isScanning
                              ? null
                              : () => _pickImage(provider, ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: Text(isTr ? 'Kamera' : 'Camera'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isScanning
                              ? null
                              : () => _pickImage(provider, ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(isTr ? 'Galeri' : 'Gallery'),
                        ),
                      ),
                    ],
                  ),
                  if (scanResult?.capturedImagePath != null) ...[
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(scanResult!.capturedImagePath!),
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    minLines: 5,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: isTr
                          ? 'Örnek:\nBİM 21.03.2026\nSiyah Zeytin 46,09 TL\nYumurta 62,50 TL\nKaşar Peyniri 129,90 TL'
                          : 'Example:\nBIM 03/21/2026\nBlack Olive 46.09 TL\nEggs 62.50 TL\nKashar Cheese 129.90 TL',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isScanning ? null : () => _scanText(provider),
                    icon: Icon(
                      _isScanning
                          ? Icons.hourglass_top_rounded
                          : Icons.document_scanner_outlined,
                    ),
                    label: Text(
                      _isScanning
                          ? (isTr ? 'Taranıyor' : 'Scanning')
                          : (isTr ? 'Broşürü işle' : 'Process flyer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (scanResult != null) ...[
            const SizedBox(height: 16),
            _ActuellerSummaryCard(
              isTr: isTr,
              scanResult: scanResult,
              monthlySavings: provider.smartActuellerMonthlySavings,
            ),
          ],
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              isTr ? 'Sana özel fırsatlar' : 'Opportunities picked for you',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            ...suggestions.map((suggestion) {
              final isTracked =
                  provider.isActuellerDealTracked(suggestion.deal.id);
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            suggestion.deal.ingredient.icon,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              suggestion.title(isTr ? 'tr' : 'en'),
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(suggestion.body(isTr ? 'tr' : 'en')),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              isTr
                                  ? '${suggestion.estimatedSavings.round()} TL avantaj'
                                  : '${suggestion.estimatedSavings.round()} TRY saved',
                            ),
                          ),
                          Chip(
                            label: Text(
                              isTr
                                  ? '${suggestion.pantryCount} adet dolapta'
                                  : '${suggestion.pantryCount} in pantry',
                            ),
                          ),
                          if (suggestion.neededCount > 0)
                            Chip(
                              label: Text(
                                isTr
                                    ? '${suggestion.neededCount} adet eksik'
                                    : '${suggestion.neededCount} missing',
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: FilledButton.tonalIcon(
                          onPressed: isTracked
                              ? null
                              : () async {
                                  final messenger =
                                      ScaffoldMessenger.of(context);
                                  await provider.trackActuellerSavings(
                                    suggestion,
                                  );
                                  if (!mounted) {
                                    return;
                                  }
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isTr
                                            ? 'Tasarruf sayacına eklendi.'
                                            : 'Added to the savings tracker.',
                                      ),
                                    ),
                                  );
                                },
                          icon: Icon(
                            isTracked
                                ? Icons.check_circle_rounded
                                : Icons.bookmark_add_outlined,
                          ),
                          label: Text(
                            isTracked
                                ? (isTr ? 'Takibe alındı' : 'Tracked')
                                : (isTr
                                    ? 'Tasarrufu işaretle'
                                    : 'Track savings'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          if (scanResult != null) ...[
            const SizedBox(height: 8),
            Text(
              isTr ? 'Broşürden okunan ürünler' : 'Products read from flyers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 10),
            if (scanResult.catalogItems.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    isTr
                        ? 'Broşürde ürün çıkarılamadı. Daha net bir görsel veya daha temiz OCR metni dene.'
                        : 'No products could be extracted. Try a clearer image or cleaner OCR text.',
                  ),
                ),
              )
            else
              ...scanResult.catalogItems.map((item) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.7),
                      child: const Icon(Icons.local_offer_outlined, size: 18),
                    ),
                    title: Text(item.productTitle),
                    subtitle: Text(
                      [
                        item.marketName,
                        item.sourceLabel,
                      ].join(' • '),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item.price.toStringAsFixed(2)} TL',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          isTr
                              ? '%${(item.confidence * 100).round()} güven'
                              : '%${(item.confidence * 100).round()} confidence',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ],
      ),
    );
  }
}

class _MarketSelectorCard extends StatelessWidget {
  final bool isTr;
  final AppProvider provider;

  const _MarketSelectorCard({required this.isTr, required this.provider});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIds = provider.smartKitchenPreferences.preferredMarkets;
    const markets = SmartActuellerSourceService.availableMarkets;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.storefront_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isTr ? 'Takip ettiğin marketler' : 'Markets you follow',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              isTr
                  ? 'Aktüel broşürlerini görmek istediğin marketleri seç.'
                  : 'Pick the markets whose weekly flyers you want to track.',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: markets.map((market) {
                final isSelected = selectedIds.contains(market.id);
                return FilterChip(
                  selected: isSelected,
                  showCheckmark: false,
                  avatar: Text(market.emoji, style: const TextStyle(fontSize: 16)),
                  label: Text(market.name),
                  selectedColor:
                      theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                  onSelected: (_) => provider.togglePreferredMarket(market.id),
                );
              }).toList(),
            ),
            if (selectedIds.isEmpty) ...[
              const SizedBox(height: 10),
              Text(
                isTr
                    ? 'En az bir market seçmelisin.'
                    : 'Please select at least one market.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActuellerHeroCard extends StatelessWidget {
  final bool isTr;

  const _ActuellerHeroCard({required this.isTr});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0E2A47),
            Color(0xFF0F6B8F),
            Color(0xFF42A96B),
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
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.local_offer_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isTr ? 'Smart Aktüel Asistanı' : 'Smart Flyer Assistant',
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
                ? 'Sadece indirim göstermez. Dolabın, menülerin ve eksiklerinle konuşur; gerçekten işine yarayan ürünleri öne çıkarır.'
                : 'It does more than list discounts. It connects flyers to your pantry, menus, and missing items.',
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

class _ActuellerSummaryCard extends StatelessWidget {
  final bool isTr;
  final ActuellerScanResult scanResult;
  final double monthlySavings;

  const _ActuellerSummaryCard({
    required this.isTr,
    required this.scanResult,
    required this.monthlySavings,
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
                Icon(Icons.query_stats_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    isTr ? 'Aktüel özeti' : 'Flyer summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    scanResult.detectedStore == null
                        ? scanResult.sourceLabel
                        : scanResult.detectedStore!,
                  ),
                ),
                Chip(
                  label: Text(
                    isTr
                        ? '${scanResult.catalogItems.length} ürün'
                        : '${scanResult.catalogItems.length} items',
                  ),
                ),
                Chip(
                  label: Text(
                    isTr
                        ? '${scanResult.deals.length} mutfak eşleşmesi'
                        : '${scanResult.deals.length} kitchen matches',
                  ),
                ),
                Chip(
                  label: Text(
                    isTr
                        ? '%${(scanResult.confidence * 100).round()} güven'
                        : '%${(scanResult.confidence * 100).round()} confidence',
                  ),
                ),
                Chip(
                  label: Text(
                    isTr
                        ? 'Bu ay ${monthlySavings.round()} TL'
                        : '${monthlySavings.round()} TRY this month',
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

String _formatDateTr(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day.$month.${date.year}';
}

String _formatDateEn(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$month/$day/${date.year}';
}

String _formatDateTimeTr(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${_formatDateTr(date)} $hour:$minute';
}

String _formatDateTimeEn(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '${_formatDateEn(date)} $hour:$minute';
}
