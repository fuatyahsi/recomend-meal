import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/market_fiyati.dart';
import '../models/smart_actueller.dart';
import '../providers/app_provider.dart';
import '../services/smart_actueller_source_service.dart';
import '../utils/app_theme.dart';
import '../utils/market_registry.dart';
import '../utils/product_category.dart';
import '../utils/text_repair.dart';

class SmartActuellerScreen extends StatefulWidget {
  final bool autoSyncOnOpen;

  const SmartActuellerScreen({
    super.key,
    this.autoSyncOnOpen = false,
  });

  @override
  State<SmartActuellerScreen> createState() => _SmartActuellerScreenState();
}

class _SmartActuellerScreenState extends State<SmartActuellerScreen> {
  static const _distanceOptionsKm = [1, 3, 5, 10];

  bool _isScanning = false;
  bool _didTriggerAutoSync = false;
  ProductCategory? _selectedCategory;
  String? _selectedOfficialCategory;
  String? _selectedMarketFilter;
  String _searchQuery = '';
  final List<ActuellerCatalogItem> _recentViewedItems = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !widget.autoSyncOnOpen || _didTriggerAutoSync) return;
      final provider = context.read<AppProvider>();
      if (provider.smartKitchenPreferences.preferredMarkets.isEmpty) return;
      _didTriggerAutoSync = true;
      await _syncCatalog(provider);
    });
  }

  Future<void> _syncCatalog(AppProvider provider) async {
    setState(() => _isScanning = true);
    try {
      await provider.syncPreferredActuellerCatalog(force: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(error.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  void _rememberViewedItem(ActuellerCatalogItem item) {
    final identity = item.sourceProductId ?? item.id;
    final updated = [
      item,
      ..._recentViewedItems.where(
        (candidate) => (candidate.sourceProductId ?? candidate.id) != identity,
      ),
    ].take(6).toList();

    setState(() {
      _recentViewedItems
        ..clear()
        ..addAll(updated);
    });
  }

  Future<void> _openComparisonForItem(
    BuildContext context, {
    required AppProvider provider,
    required ActuellerCatalogItem item,
    required bool isTr,
  }) async {
    if (provider.smartKitchenPreferences.preferredMarkets.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isTr
                ? 'Karşılaştırma için en az 2 market seç.'
                : 'Select at least 2 stores for comparison.',
          ),
        ),
      );
      return;
    }

    _rememberViewedItem(item);
    await _showMarketComparison(
      context,
      item: item,
      isTr: isTr,
    );
  }

  Future<void> _showLocationPicker(
    BuildContext context, {
    required AppProvider provider,
    required bool isTr,
  }) async {
    final controller = TextEditingController();
    final currentSession = provider.marketFiyatiSession;
    var suggestions = <MarketFiyatiLocationSuggestion>[];
    MarketFiyatiLocationSuggestion? selectedSuggestion;
    var selectedDistanceKm = currentSession?.distance ?? 5;
    var isSearching = false;
    var isSaving = false;
    String? errorMessage;

    Future<void> runSearch(StateSetter setSheetState) async {
      final query = controller.text.trim();
      if (query.length < 2) {
        setSheetState(() {
          suggestions = const [];
          errorMessage =
              isTr ? 'En az 2 harf gir.' : 'Enter at least 2 characters.';
        });
        return;
      }

      setSheetState(() {
        isSearching = true;
        errorMessage = null;
      });

      try {
        final results = await provider.searchMarketFiyatiLocations(query);
        if (!mounted) return;
        setSheetState(() {
          suggestions = results;
          selectedSuggestion = null;
          if (results.isEmpty) {
            errorMessage =
                isTr ? 'Sonuç bulunamadı.' : 'No locations were found.';
          }
        });
      } catch (error) {
        if (!mounted) return;
        setSheetState(() {
          errorMessage = error.toString().replaceFirst('Exception: ', '');
        });
      } finally {
        if (mounted) {
          setSheetState(() => isSearching = false);
        }
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final locationLabel = provider.marketFiyatiLocationLabel;
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(sheetContext).size.height * 0.86,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Container(
                            width: 42,
                            height: 5,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          isTr
                              ? 'Konum ve Mesafe Seç'
                              : 'Choose Location and Distance',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          isTr
                              ? 'Konumu arat, sonra yakın marketleri hangi yarıçapta getireceğimizi seç.'
                              : 'Search a location, then choose how far nearby stores should be fetched.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        if (locationLabel != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer
                                  .withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on_rounded,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    locationLabel,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () async {
                                    await provider.clearMarketFiyatiLocation();
                                    if (!mounted) return;
                                    setSheetState(() {
                                      selectedSuggestion = null;
                                    });
                                  },
                                  child: Text(isTr ? 'Temizle' : 'Clear'),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: controller,
                                textInputAction: TextInputAction.search,
                                onSubmitted: (_) => runSearch(setSheetState),
                                decoration: InputDecoration(
                                  hintText: isTr
                                      ? 'Öveçler, Balgat, Kabil Caddesi...'
                                      : 'Search a location...',
                                  prefixIcon: const Icon(Icons.search_rounded),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            FilledButton(
                              onPressed: isSearching || isSaving
                                  ? null
                                  : () => runSearch(setSheetState),
                              child: Text(isTr ? 'Ara' : 'Search'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.42),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<int>(
                              value: selectedDistanceKm,
                              isExpanded: true,
                              borderRadius: BorderRadius.circular(18),
                              icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                              ),
                              items: _distanceOptionsKm
                                  .map(
                                    (distance) => DropdownMenuItem<int>(
                                      value: distance,
                                      child: Text(
                                        isTr
                                            ? 'Mesafe: $distance km'
                                            : 'Distance: $distance km',
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: isSaving
                                  ? null
                                  : (value) {
                                      if (value == null) return;
                                      setSheetState(
                                        () => selectedDistanceKm = value,
                                      );
                                    },
                            ),
                          ),
                        ),
                        if (errorMessage != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            errorMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        Flexible(
                          child: isSearching
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  itemCount: suggestions.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final suggestion = suggestions[index];
                                    final subtitle = repairTurkishText(
                                      suggestion.fullLabel,
                                    ).trim();
                                    final isSelected = identical(
                                        selectedSuggestion, suggestion);
                                    return Material(
                                      color: isSelected
                                          ? theme.colorScheme.primaryContainer
                                              .withValues(alpha: 0.48)
                                          : theme.colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.38),
                                      borderRadius: BorderRadius.circular(18),
                                      child: ListTile(
                                        onTap: isSaving
                                            ? null
                                            : () {
                                                controller.text =
                                                    suggestion.displayLabel;
                                                setSheetState(() {
                                                  selectedSuggestion =
                                                      suggestion;
                                                  errorMessage = null;
                                                });
                                              },
                                        leading: Icon(
                                          suggestion.pointOfInterestName
                                                  .trim()
                                                  .isNotEmpty
                                              ? Icons.place_rounded
                                              : Icons.map_outlined,
                                        ),
                                        title: Text(
                                          repairTurkishText(
                                            suggestion.displayLabel,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodyMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        subtitle: Text(
                                          subtitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        trailing: isSelected
                                            ? Icon(
                                                Icons.check_circle_rounded,
                                                color:
                                                    theme.colorScheme.primary,
                                              )
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: isSaving
                                ? null
                                : () async {
                                    if (selectedSuggestion == null) {
                                      setSheetState(() {
                                        errorMessage = isTr
                                            ? 'Önce bir konum seç.'
                                            : 'Select a location first.';
                                      });
                                      return;
                                    }

                                    setSheetState(() {
                                      isSaving = true;
                                      errorMessage = null;
                                    });

                                    try {
                                      await provider.setMarketFiyatiLocation(
                                        selectedSuggestion!,
                                        nearestDistance: selectedDistanceKm,
                                        sessionDistance: selectedDistanceKm,
                                      );
                                      if (!sheetContext.mounted ||
                                          !context.mounted) {
                                        return;
                                      }
                                      Navigator.of(sheetContext).pop();
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            isTr
                                                ? 'Konum kaydedildi: ${selectedSuggestion!.displayLabel}'
                                                : 'Location saved: ${selectedSuggestion!.displayLabel}',
                                          ),
                                        ),
                                      );
                                    } catch (error) {
                                      if (!sheetContext.mounted) {
                                        return;
                                      }
                                      setSheetState(() {
                                        errorMessage = error
                                            .toString()
                                            .replaceFirst('Exception: ', '');
                                      });
                                    } finally {
                                      if (sheetContext.mounted) {
                                        setSheetState(
                                          () => isSaving = false,
                                        );
                                      }
                                    }
                                  },
                            icon: Icon(
                              isSaving
                                  ? Icons.hourglass_top_rounded
                                  : Icons.save_rounded,
                            ),
                            label: Text(
                              isSaving
                                  ? (isTr ? 'Kaydediliyor...' : 'Saving...')
                                  : (isTr ? 'Kaydet' : 'Save'),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isTr = provider.languageCode == 'tr';
    final theme = Theme.of(context);
    String clean(String value) => repairTurkishText(value);
    final scanResult = provider.lastActuellerScanResult;
    final isCatalogSyncing = provider.isActuellerCatalogSyncing;
    final catalogSyncAt = provider.lastActuellerCatalogSyncAt;
    final catalogBrochureCount = provider.lastActuellerCatalogBrochureCount;
    final catalogMessage = provider.actuellerCatalogSyncMessage;
    final hasSelectedMarkets =
        provider.smartKitchenPreferences.preferredMarkets.isNotEmpty;
    final marketFiyatiLocationLabel = provider.marketFiyatiLocationLabel;
    final hasOfficialSession = provider.marketFiyatiSession != null;
    final usesOfficialCatalog = provider.hasOfficialMarketCatalog;

    // ── Filter items ──
    final allItems = scanResult?.catalogItems ?? [];
    final filteredItems = allItems.where((item) {
      if (usesOfficialCatalog &&
          _selectedOfficialCategory != null &&
          !_matchesOfficialCategory(item, _selectedOfficialCategory!)) {
        return false;
      }
      if (!usesOfficialCatalog &&
          _selectedCategory != null &&
          item.category != _selectedCategory) {
        return false;
      }
      if (_selectedMarketFilter != null &&
          item.marketName != _selectedMarketFilter) {
        return false;
      }
      if (_searchQuery.trim().isNotEmpty &&
          !_matchesActuellerSearch(item, _searchQuery)) {
        return false;
      }
      return true;
    }).toList();

    // ── Available categories from current data ──
    final availableCategories = <ProductCategory>{};
    for (final item in allItems) {
      availableCategories.add(item.category);
    }
    final sortedCategories =
        ProductCategory.values.where(availableCategories.contains).toList();
    final officialCategories = usesOfficialCatalog
        ? _officialMarketCategories.where((category) {
            return allItems.any(
              (item) => _matchesOfficialCategory(item, category.labelTr),
            );
          }).toList()
        : const <_OfficialMarketCategory>[];

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(isTr ? 'Markette Bugün Ne Ucuz?' : 'Deal Radar'),
        actions: [
          if (hasSelectedMarkets)
            IconButton(
              onPressed: () => _showLocationPicker(
                context,
                provider: provider,
                isTr: isTr,
              ),
              icon: Icon(
                marketFiyatiLocationLabel == null
                    ? Icons.location_on_outlined
                    : Icons.location_on_rounded,
              ),
            ),
          if (hasSelectedMarkets)
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
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withValues(alpha: 0.18),
              theme.colorScheme.surface,
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 0.18, 1.0],
          ),
        ),
        child: allItems.isEmpty
            ? _buildEmptyState(
                context,
                provider: provider,
                isTr: isTr,
                hasSelectedMarkets: hasSelectedMarkets,
                isSyncing: isCatalogSyncing || _isScanning,
                catalogSyncAt: catalogSyncAt,
                catalogMessage:
                    catalogMessage == null ? null : clean(catalogMessage),
                marketFiyatiLocationLabel: marketFiyatiLocationLabel,
                usesOfficialSource: hasOfficialSession,
              )
            : _buildMarketHomeView(
                context,
                isTr: isTr,
                theme: theme,
                allItems: allItems,
                filteredItems: filteredItems,
                sortedCategories: sortedCategories,
                officialCategories: officialCategories,
                catalogBrochureCount: catalogBrochureCount,
                catalogSyncAt: catalogSyncAt,
                isSyncing: isCatalogSyncing || _isScanning,
                provider: provider,
                marketFiyatiLocationLabel: marketFiyatiLocationLabel,
                usesOfficialSource: usesOfficialCatalog,
              ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  EMPTY STATE — no products yet
  // ══════════════════════════════════════════════════════════════
  Widget _buildEmptyState(
    BuildContext context, {
    required AppProvider provider,
    required bool isTr,
    required bool hasSelectedMarkets,
    required bool isSyncing,
    required DateTime? catalogSyncAt,
    required String? catalogMessage,
    required String? marketFiyatiLocationLabel,
    required bool usesOfficialSource,
  }) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Hero card
        _HeroCard(
          isTr: isTr,
          usesOfficialSource: usesOfficialSource,
        ),
        const SizedBox(height: 16),

        // Market selector
        _MarketSelectorCard(isTr: isTr, provider: provider),
        const SizedBox(height: 16),
        _LocationSessionCard(
          isTr: isTr,
          locationLabel: marketFiyatiLocationLabel,
          onTap: hasSelectedMarkets
              ? () => _showLocationPicker(
                    context,
                    provider: provider,
                    isTr: isTr,
                  )
              : null,
        ),
        const SizedBox(height: 16),

        // Sync button
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.06),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(
                hasSelectedMarkets
                    ? Icons.cloud_download_outlined
                    : Icons.storefront_outlined,
                size: 48,
                color: theme.colorScheme.primary.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 14),
              Text(
                hasSelectedMarkets
                    ? (isTr
                        ? (usesOfficialSource
                            ? 'Resmî fiyatları çekip ürünleri getir'
                            : 'Broşürleri tarayıp ürünleri getir')
                        : (usesOfficialSource
                            ? 'Load official prices and products'
                            : 'Scan flyers and load products'))
                    : (isTr
                        ? 'Önce yukarıdan marketlerini seç'
                        : 'Pick your stores above first'),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (hasSelectedMarkets) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: isSyncing ? null : () => _syncCatalog(provider),
                    icon: Icon(
                      isSyncing
                          ? Icons.hourglass_top_rounded
                          : Icons.search_rounded,
                    ),
                    label: Text(
                      isSyncing
                          ? (isTr
                              ? (usesOfficialSource
                                  ? 'Fiyatlar getiriliyor...'
                                  : 'Taranıyor...')
                              : (usesOfficialSource
                                  ? 'Loading prices...'
                                  : 'Scanning...'))
                          : (isTr
                              ? (usesOfficialSource
                                  ? 'Fiyatları Getir'
                                  : 'Broşürleri Tara')
                              : (usesOfficialSource
                                  ? 'Load Prices'
                                  : 'Scan Flyers')),
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
              if (catalogSyncAt != null || catalogMessage != null) ...[
                const SizedBox(height: 12),
                if (catalogMessage != null)
                  Text(
                    catalogMessage,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  PRODUCT VIEW — categories + items
  // ══════════════════════════════════════════════════════════════
  // Kept temporarily as a fallback while the new market-first home layout settles.
  // ignore: unused_element
  Widget _buildProductView(
    BuildContext context, {
    required bool isTr,
    required ThemeData theme,
    required List<ActuellerCatalogItem> allItems,
    required List<ActuellerCatalogItem> filteredItems,
    required List<ProductCategory> sortedCategories,
    required Set<String> availableMarkets,
    required int catalogBrochureCount,
    required DateTime? catalogSyncAt,
    required bool isSyncing,
    required AppProvider provider,
    required String? marketFiyatiLocationLabel,
    required bool usesOfficialSource,
  }) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF4A1734), Color(0xFF982B4E), Color(0xFFE06C3C)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isTr
                          ? (usesOfficialSource
                              ? '$catalogBrochureCount resmî kategoriden ${allItems.length} ürün'
                              : '$catalogBrochureCount broşürden ${allItems.length} ürün')
                          : (usesOfficialSource
                              ? '$catalogBrochureCount official categories, ${allItems.length} items'
                              : '$catalogBrochureCount flyers, ${allItems.length} items'),
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTr
                          ? (usesOfficialSource
                              ? 'Yakındaki marketlerde aynı ürünü karşılaştır, en iyi fiyatı hızlıca gör.'
                              : 'Kategori seç, market filtrele, en iyi fırsatı hızlıca gör.')
                          : (usesOfficialSource
                              ? 'Compare the same product across nearby stores and spot the best price fast.'
                              : 'Pick a category, filter by market, and see the best deal fast.'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        // ── Sticky filter bar ──
        Container(
          margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppTheme.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary line
              Row(
                children: [
                  Icon(Icons.local_offer_rounded,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      isTr
                          ? (usesOfficialSource
                              ? '${allItems.length} ürün • $catalogBrochureCount resmî kategori'
                              : '${allItems.length} ürün • $catalogBrochureCount broşür')
                          : (usesOfficialSource
                              ? '${allItems.length} items • $catalogBrochureCount official categories'
                              : '${allItems.length} items • $catalogBrochureCount flyers'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (isSyncing)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              if (marketFiyatiLocationLabel != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on_rounded,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        isTr
                            ? 'Resmî fiyat konumu: $marketFiyatiLocationLabel'
                            : 'Official price location: $marketFiyatiLocationLabel',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: isTr
                      ? 'Ürün ara: süt, zeytinyağı, adidas...'
                      : 'Search products: milk, olive oil, adidas...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.45),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Category chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _FilterChipWidget(
                      label: isTr ? 'Tümü' : 'All',
                      isSelected: _selectedCategory == null,
                      onTap: () => setState(() => _selectedCategory = null),
                    ),
                    const SizedBox(width: 6),
                    ...sortedCategories.map((cat) {
                      final count =
                          allItems.where((i) => i.category == cat).length;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: _FilterChipWidget(
                          label:
                              '${cat.emoji} ${isTr ? cat.labelTr : cat.labelEn} ($count)',
                          isSelected: _selectedCategory == cat,
                          onTap: () => setState(() {
                            _selectedCategory =
                                _selectedCategory == cat ? null : cat;
                          }),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // Market filter chips
              if (availableMarkets.length > 1)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _FilterChipWidget(
                        label: isTr ? 'Tüm marketler' : 'All stores',
                        isSelected: _selectedMarketFilter == null,
                        onTap: () =>
                            setState(() => _selectedMarketFilter = null),
                      ),
                      const SizedBox(width: 6),
                      ...availableMarkets.map((market) {
                        final displayName = displayNameForMarket(market);
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: _FilterChipWidget(
                            label: displayName.isEmpty ? market : displayName,
                            isSelected: _selectedMarketFilter == market,
                            onTap: () => setState(() {
                              _selectedMarketFilter =
                                  _selectedMarketFilter == market
                                      ? null
                                      : market;
                            }),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const Divider(height: 1),

        // ── Product list ──
        Expanded(
          child: filteredItems.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      isTr
                          ? 'Bu filtreyle eşleşen ürün yok.'
                          : 'No products match this filter.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _ProductCard(
                      item: item,
                      isTr: isTr,
                      onCompare: () async {
                        if (provider.smartKitchenPreferences.preferredMarkets
                                .length <
                            2) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isTr
                                    ? 'Karşılaştırma için en az 2 market seç.'
                                    : 'Select at least 2 stores for comparison.',
                              ),
                            ),
                          );
                          return;
                        }
                        await _showMarketComparison(
                          context,
                          item: item,
                          isTr: isTr,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════════════════════════
  //  MARKET COMPARISON BOTTOM SHEET
  // ══════════════════════════════════════════════════════════════
  Widget _buildMarketHomeView(
    BuildContext context, {
    required bool isTr,
    required ThemeData theme,
    required List<ActuellerCatalogItem> allItems,
    required List<ActuellerCatalogItem> filteredItems,
    required List<ProductCategory> sortedCategories,
    required List<_OfficialMarketCategory> officialCategories,
    required int catalogBrochureCount,
    required DateTime? catalogSyncAt,
    required bool isSyncing,
    required AppProvider provider,
    required String? marketFiyatiLocationLabel,
    required bool usesOfficialSource,
  }) {
    final summaryLabel = isTr
        ? (usesOfficialSource
            ? '${filteredItems.length}/${allItems.length} ürün • $catalogBrochureCount resmî kategori'
            : '${filteredItems.length}/${allItems.length} ürün • $catalogBrochureCount broşür')
        : (usesOfficialSource
            ? '${filteredItems.length}/${allItems.length} items • $catalogBrochureCount official categories'
            : '${filteredItems.length}/${allItems.length} items • $catalogBrochureCount flyers');

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4A1734),
                  Color(0xFF982B4E),
                  Color(0xFFE06C3C),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppTheme.softShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Icon(
                    Icons.local_offer_rounded,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTr
                            ? (usesOfficialSource
                                ? '$catalogBrochureCount resmî kategoriden ${allItems.length} ürün'
                                : '$catalogBrochureCount broşürden ${allItems.length} ürün')
                            : (usesOfficialSource
                                ? '$catalogBrochureCount official categories, ${allItems.length} items'
                                : '$catalogBrochureCount flyers, ${allItems.length} items'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTr
                            ? (usesOfficialSource
                                ? 'Arama yap, kategori seç ve yakın marketlerde aynı ürünü kıyasla.'
                                : 'Arama yap, kategori seç ve broşürlerdeki fırsatları hızla süz.')
                            : (usesOfficialSource
                                ? 'Search, pick a category, and compare the same product across nearby stores.'
                                : 'Search, pick a category, and filter flyer deals fast.'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.35,
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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppTheme.softShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: isTr
                          ? 'Ürün arayın: süt, domates, Eti...'
                          : 'Search products: milk, tomato, Eti...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      filled: true,
                      fillColor: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.45),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          summaryLabel,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (isSyncing)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                    ],
                  ),
                  if (catalogSyncAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      isTr
                          ? 'Son yenileme: ${catalogSyncAt.day.toString().padLeft(2, '0')}.${catalogSyncAt.month.toString().padLeft(2, '0')} ${catalogSyncAt.hour.toString().padLeft(2, '0')}:${catalogSyncAt.minute.toString().padLeft(2, '0')}'
                          : 'Last refresh: ${catalogSyncAt.day.toString().padLeft(2, '0')}.${catalogSyncAt.month.toString().padLeft(2, '0')} ${catalogSyncAt.hour.toString().padLeft(2, '0')}:${catalogSyncAt.minute.toString().padLeft(2, '0')}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (marketFiyatiLocationLabel != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            isTr
                                ? 'Resmî fiyat konumu: $marketFiyatiLocationLabel'
                                : 'Official price location: $marketFiyatiLocationLabel',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (usesOfficialSource
            ? officialCategories.isNotEmpty
            : sortedCategories.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _SectionCard(
                title: isTr ? 'Kategori Seçimi' : 'Categories',
                subtitle: isTr
                    ? 'Önce hangi rafta gezmek istediğini seç.'
                    : 'Choose which shelf you want to browse first.',
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: usesOfficialSource
                      ? officialCategories.length
                      : sortedCategories.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    mainAxisExtent: 168,
                  ),
                  itemBuilder: (context, index) {
                    if (usesOfficialSource) {
                      final category = officialCategories[index];
                      final count = allItems
                          .where((item) =>
                              _matchesOfficialCategory(item, category.labelTr))
                          .length;
                      return _OfficialCategoryTileCard(
                        category: category,
                        count: count,
                        isSelected:
                            _selectedOfficialCategory == category.labelTr,
                        isTr: isTr,
                        onTap: () => setState(() {
                          _selectedOfficialCategory =
                              _selectedOfficialCategory == category.labelTr
                                  ? null
                                  : category.labelTr;
                        }),
                      );
                    }

                    final category = sortedCategories[index];
                    final count = allItems
                        .where((item) => item.category == category)
                        .length;
                    return _CategoryTileCard(
                      category: category,
                      count: count,
                      isSelected: _selectedCategory == category,
                      isTr: isTr,
                      onTap: () => setState(() {
                        _selectedCategory =
                            _selectedCategory == category ? null : category;
                      }),
                    );
                  },
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _MarketSelectorCard(
              isTr: isTr,
              provider: provider,
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _LocationSessionCard(
              isTr: isTr,
              locationLabel: marketFiyatiLocationLabel,
              onTap: () => _showLocationPicker(
                context,
                provider: provider,
                isTr: isTr,
              ),
            ),
          ),
        ),
        if (_recentViewedItems.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _SectionCard(
                title: isTr ? 'Son Gezdiklerin' : 'Recently Viewed',
                subtitle: isTr
                    ? 'Karşılaştırdığın ürünlere buradan hızlıca dön.'
                    : 'Jump back into products you already compared.',
                child: SizedBox(
                  height: 148,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _recentViewedItems.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = _recentViewedItems[index];
                      return _RecentViewedCard(
                        item: item,
                        isTr: isTr,
                        onTap: () => _openComparisonForItem(
                          context,
                          provider: provider,
                          item: item,
                          isTr: isTr,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
            child: Text(
              isTr ? 'Ürünler' : 'Products',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        if (filteredItems.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  isTr
                      ? 'Bu filtreyle eşleşen ürün yok.'
                      : 'No products match this filter.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = filteredItems[index];
                  return _ProductCard(
                    item: item,
                    isTr: isTr,
                    onCompare: () => _openComparisonForItem(
                      context,
                      provider: provider,
                      item: item,
                      isTr: isTr,
                    ),
                  );
                },
                childCount: filteredItems.length,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showMarketComparison(
    BuildContext context, {
    required ActuellerCatalogItem item,
    required bool isTr,
  }) async {
    final provider = context.read<AppProvider>();
    var comparisonSourceLabel = isTr
        ? 'Yalnızca güvenilir aynı ürün eşleşmeleri gösterilir'
        : 'Only reliable same-product matches are shown';
    var marketMatches = <_CompareEntry>[];
    var officialLookupCompleted = false;

    if (item.sourceProductId != null && provider.marketFiyatiSession != null) {
      try {
        final officialItems = await provider.fetchOfficialSimilarProducts(item);
        officialLookupCompleted = true;
        marketMatches = _buildOfficialCompareEntries(
          base: item,
          candidates: officialItems,
        );
        if (marketMatches.isNotEmpty) {
          comparisonSourceLabel =
              isTr ? 'Resmî market verisi' : 'Official market data';
        }
      } catch (_) {
        // Keep the sheet usable even if the official lookup fails.
      }
    }

    if (marketMatches.isEmpty && officialLookupCompleted) {
      comparisonSourceLabel = isTr
          ? 'Resmî veride güvenilir eşleşme bulunamadı'
          : 'No reliable official match was found';
    }

    if (!context.mounted) return;

    final allCompareItems = <_CompareEntry>[
      _CompareEntry(
        marketName: item.marketName,
        productTitle: item.productTitle,
        price: item.price,
        weight: item.weight,
        isCurrent: true,
      ),
      ...marketMatches,
    ];

    final cheapestPrice = allCompareItems
        .map((entry) => entry.price)
        .reduce((best, price) => price < best ? price : best);

    final theme = Theme.of(context);
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Fixed header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isTr ? 'Market Karşılaştırma' : 'Price Comparison',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.productTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      comparisonSourceLabel,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
              // Scrollable comparison list
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (marketMatches.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Text(
                            provider.marketFiyatiSession == null
                                ? (isTr
                                    ? 'Önce konum seç. Aynı ürün karşılaştırması resmî market verisiyle çalışır.'
                                    : 'Choose a location first. Same-product comparison uses official market data.')
                                : ((item.sourceProductId ?? '').trim().isEmpty
                                    ? (isTr
                                        ? 'Bu ürün yalnızca broşür kaydı olarak bulundu. Güvenilir resmî eşleşme olmadan karşılaştırma göstermiyoruz.'
                                        : 'This product was found only as a brochure entry. We do not show comparison without a reliable official match.')
                                    : (isTr
                                        ? 'Bu ürün için diğer marketlerde güvenilir aynı ürün eşleşmesi bulunamadı.'
                                        : 'No reliable same-product match was found in other stores.')),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        )
                      else
                        ...allCompareItems.map((entry) => _ComparisonRow(
                              marketName: entry.marketName,
                              productTitle: entry.productTitle,
                              price: entry.price,
                              weight: entry.weight,
                              isCurrent: entry.isCurrent,
                              isCheapest: entry.price <= cheapestPrice,
                              theme: theme,
                            )),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<_CompareEntry> _buildOfficialCompareEntries({
    required ActuellerCatalogItem base,
    required List<ActuellerCatalogItem> candidates,
  }) {
    final currentMarketId =
        normalizeMarketId(base.marketName) ?? base.marketName.toLowerCase();
    final bestByMarket = <String, ({ActuellerCatalogItem item, int score})>{};

    for (final candidate in candidates) {
      final candidateMarketId = normalizeMarketId(candidate.marketName) ??
          candidate.marketName.toLowerCase();
      if (candidateMarketId == currentMarketId) {
        continue;
      }
      if (base.sourceDepotId != null &&
          candidate.sourceDepotId == base.sourceDepotId) {
        continue;
      }
      final score = _officialCrossMarketMatchScore(
        base: base,
        candidate: candidate,
      );
      if (score < 0) {
        continue;
      }

      final previous = bestByMarket[candidateMarketId];
      if (previous == null ||
          score > previous.score ||
          (score == previous.score && candidate.price < previous.item.price)) {
        bestByMarket[candidateMarketId] = (item: candidate, score: score);
      }
    }

    return bestByMarket.values
        .map(
          (match) => _CompareEntry(
            marketName: match.item.marketName,
            productTitle: match.item.productTitle,
            price: match.item.price,
            weight: match.item.weight,
            isCurrent: false,
          ),
        )
        .toList()
      ..sort((a, b) => a.price.compareTo(b.price));
  }

  int _officialCrossMarketMatchScore({
    required ActuellerCatalogItem base,
    required ActuellerCatalogItem candidate,
  }) {
    final baseTitle = _normalizeMarketCompareValue(base.productTitle);
    final candidateTitle = _normalizeMarketCompareValue(candidate.productTitle);
    final baseBrand = _normalizeMarketCompareValue(base.brand ?? '');
    final candidateBrand = _normalizeMarketCompareValue(candidate.brand ?? '');
    final baseWeight = _normalizeMarketCompareValue(base.weight ?? '');
    final candidateWeight =
        _normalizeMarketCompareValue(candidate.weight ?? '');
    final genericScore =
        _crossMarketMatchScore(base: base, candidate: candidate);
    final overlap = _extractMarketCompareTokens(base)
        .intersection(_extractMarketCompareTokens(candidate));
    final baseCoreTokens = _extractOfficialCoreTokens(base);
    final candidateCoreTokens = _extractOfficialCoreTokens(candidate);
    final coreOverlap = baseCoreTokens.intersection(candidateCoreTokens);
    final exactTitle = baseTitle == candidateTitle;
    final sameBrand = baseBrand.isNotEmpty &&
        candidateBrand.isNotEmpty &&
        baseBrand == candidateBrand;
    final sameWeight = baseWeight.isNotEmpty &&
        candidateWeight.isNotEmpty &&
        baseWeight == candidateWeight;
    final hasModelToken = overlap.any(_isProductModelToken);
    final hasMeaningfulSingleCoreToken =
        coreOverlap.length == 1 && coreOverlap.first.length >= 4;
    final minCoreCount = baseCoreTokens.length < candidateCoreTokens.length
        ? baseCoreTokens.length
        : candidateCoreTokens.length;
    final coreSimilarity =
        minCoreCount == 0 ? 0 : coreOverlap.length / minCoreCount;

    if (base.sourceProductId != null &&
        candidate.sourceProductId != null &&
        base.sourceProductId == candidate.sourceProductId) {
      return 100;
    }

    if (exactTitle) {
      return 90 + (genericScore < 0 ? 0 : genericScore);
    }

    if (genericScore < 0 && !hasModelToken) {
      return -1;
    }

    if (hasModelToken && sameWeight) {
      return 78 + (genericScore < 0 ? 0 : genericScore);
    }

    if (sameWeight &&
        hasMeaningfulSingleCoreToken &&
        (baseCoreTokens.length == 1 || candidateCoreTokens.length == 1)) {
      return 72 + (genericScore < 0 ? 0 : genericScore);
    }

    if (sameBrand && sameWeight && coreOverlap.isNotEmpty) {
      return 70 + (genericScore < 0 ? 0 : genericScore);
    }

    if (coreOverlap.length >= 2 && coreSimilarity >= 0.5) {
      return 64 + (genericScore < 0 ? 0 : genericScore);
    }

    if (sameBrand && coreOverlap.length >= 2) {
      return 60 + (genericScore < 0 ? 0 : genericScore);
    }

    if (sameWeight && coreOverlap.length >= 2) {
      return 56 + (genericScore < 0 ? 0 : genericScore);
    }

    return -1;
  }

  int _crossMarketMatchScore({
    required ActuellerCatalogItem base,
    required ActuellerCatalogItem candidate,
  }) {
    if (candidate.id == base.id) return -1;
    if (candidate.marketName == base.marketName) return -1;
    if (candidate.category != base.category) return -1;

    final baseTitle = _normalizeMarketCompareValue(base.productTitle);
    final candidateTitle = _normalizeMarketCompareValue(candidate.productTitle);
    final baseBrand = _normalizeMarketCompareValue(base.brand ?? '');
    final candidateBrand = _normalizeMarketCompareValue(candidate.brand ?? '');
    final baseWeight = _normalizeMarketCompareValue(base.weight ?? '');
    final candidateWeight =
        _normalizeMarketCompareValue(candidate.weight ?? '');
    final baseTokens = _extractMarketCompareTokens(base);
    final candidateTokens = _extractMarketCompareTokens(candidate);
    final overlap = baseTokens.intersection(candidateTokens);
    final sameBrand = baseBrand.isNotEmpty &&
        candidateBrand.isNotEmpty &&
        baseBrand == candidateBrand;
    final sameWeight = baseWeight.isNotEmpty &&
        candidateWeight.isNotEmpty &&
        baseWeight == candidateWeight;
    final exactTitle = baseTitle == candidateTitle;
    final hasModelToken = overlap.any(_isProductModelToken);

    final hasStrongMatch = exactTitle ||
        hasModelToken ||
        (sameBrand && overlap.length >= 2) ||
        overlap.length >= 3 ||
        (sameWeight && overlap.length >= 2);
    if (!hasStrongMatch) {
      return -1;
    }

    var score = overlap.length;
    if (sameBrand) score += 3;
    if (sameWeight) score += 2;
    if (exactTitle) score += 4;
    if (hasModelToken) score += 5;
    return score;
  }

  Set<String> _extractMarketCompareTokens(ActuellerCatalogItem item) {
    final combined =
        [item.brand ?? '', item.productTitle, item.weight ?? ''].join(' ');
    return _normalizeMarketCompareValue(combined)
        .split(RegExp(r'\s+'))
        .where(
          (token) =>
              token.length >= 2 && !_marketCompareStopWords.contains(token),
        )
        .toSet();
  }

  Set<String> _extractOfficialCoreTokens(ActuellerCatalogItem item) {
    final brandTokens = _normalizeMarketCompareValue(item.brand ?? '')
        .split(RegExp(r'\s+'))
        .where((token) => token.length >= 2)
        .toSet();
    return _extractMarketCompareTokens(item)
        .where(
          (token) =>
              !brandTokens.contains(token) &&
              !_officialCompareSoftStopWords.contains(token) &&
              !RegExp(r'^\d+$').hasMatch(token),
        )
        .toSet();
  }

  String _normalizeMarketCompareValue(String value) {
    return repairTurkishText(value)
        .toLowerCase()
        .replaceAll('ç', 'c')
        .replaceAll('ğ', 'g')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ş', 's')
        .replaceAll('ü', 'u')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }

  bool _matchesActuellerSearch(ActuellerCatalogItem item, String query) {
    final normalizedQuery = _normalizeMarketCompareValue(query);
    if (normalizedQuery.isEmpty) return true;

    final haystack = _normalizeMarketCompareValue([
      item.productTitle,
      item.brand ?? '',
      item.weight ?? '',
      item.marketName,
    ].join(' '));

    final queryTokens = normalizedQuery
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty);
    return queryTokens.every(haystack.contains);
  }

  bool _matchesOfficialCategory(
      ActuellerCatalogItem item, String categoryLabel) {
    final itemCategory = item.sourceMenuCategory?.trim() ?? '';
    if (itemCategory.isEmpty) {
      return false;
    }

    return _normalizeMarketCompareValue(itemCategory) ==
        _normalizeMarketCompareValue(categoryLabel);
  }

  bool _isProductModelToken(String token) {
    return RegExp(r'[a-z]+\d', caseSensitive: false).hasMatch(token) ||
        RegExp(r'\d+[a-z]', caseSensitive: false).hasMatch(token) ||
        RegExp(r'^\d{4,}$').hasMatch(token);
  }
}

const _marketCompareStopWords = {
  'erkek',
  'kadin',
  'cocuk',
  'spor',
  'ayakkabi',
  'terlik',
  'gri',
  'beyaz',
  'siyah',
  'lacivert',
  'mavi',
  'kirmizi',
  'yesil',
  'adet',
  'paket',
  'gr',
  'g',
  'kg',
  'ml',
  'lt',
  'cm',
};

const _officialCompareSoftStopWords = {
  'meyve',
  'sebze',
  'urun',
  'urunu',
  'urunleri',
  'temizlik',
  'adet',
  'paket',
  'gr',
  'g',
  'kg',
  'ml',
  'lt',
  'klasik',
  'normal',
  'ultra',
};

// ════════════════════════════════════════════════════════════════
//  WIDGETS
// ════════════════════════════════════════════════════════════════

class _FilterChipWidget extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChipWidget({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: isSelected
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _CategoryTileCard extends StatelessWidget {
  final ProductCategory category;
  final int count;
  final bool isSelected;
  final bool isTr;
  final VoidCallback onTap;

  const _CategoryTileCard({
    required this.category,
    required this.count,
    required this.isSelected,
    required this.isTr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.78),
                  ],
                )
              : null,
          color: isSelected
              ? null
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              category.icon,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
            const Spacer(),
            Text(
              isTr ? category.labelTr : category.labelEn,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isTr ? '$count ürün' : '$count items',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.88)
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final ActuellerCatalogItem item;
  final bool isTr;
  final VoidCallback onCompare;

  const _ProductCard({
    required this.item,
    required this.isTr,
    required this.onCompare,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marketDisplay = displayNameForMarket(item.marketName);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onCompare,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            children: [
              // Left: product info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Market badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        marketDisplay.isEmpty ? item.marketName : marketDisplay,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Product title
                    Text(
                      item.productTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Details row: brand · weight · category
                    Row(
                      children: [
                        if (item.brand != null) ...[
                          Text(
                            item.brand!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (item.weight != null)
                            Text(
                              ' · ',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outlineVariant,
                              ),
                            ),
                        ],
                        if (item.weight != null)
                          Text(
                            item.weight!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right: price + compare button
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatPrice(item.price),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  Text(
                    'TL',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondaryContainer
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Market Karşılaştır',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.secondary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatPrice(double price) {
    if (price == price.roundToDouble()) {
      return price.toStringAsFixed(0);
    }
    return price.toStringAsFixed(2).replaceAll('.', ',');
  }
}

class _OfficialMarketCategory {
  final String labelTr;
  final String labelEn;
  final IconData icon;

  const _OfficialMarketCategory({
    required this.labelTr,
    required this.labelEn,
    required this.icon,
  });
}

const _officialMarketCategories = [
  _OfficialMarketCategory(
    labelTr: 'Meyve ve Sebze',
    labelEn: 'Fruit & Vegetables',
    icon: Icons.eco_rounded,
  ),
  _OfficialMarketCategory(
    labelTr: 'Et, Tavuk ve Balık',
    labelEn: 'Meat, Poultry & Fish',
    icon: Icons.set_meal_rounded,
  ),
  _OfficialMarketCategory(
    labelTr: 'Süt Ürünleri ve Kahvaltılık',
    labelEn: 'Dairy & Breakfast',
    icon: Icons.egg_alt_rounded,
  ),
  _OfficialMarketCategory(
    labelTr: 'Temel Gıda',
    labelEn: 'Staples',
    icon: Icons.grain_rounded,
  ),
  _OfficialMarketCategory(
    labelTr: 'İçecek',
    labelEn: 'Beverages',
    icon: Icons.local_drink_rounded,
  ),
  _OfficialMarketCategory(
    labelTr: 'Atıştırmalık ve Tatlı',
    labelEn: 'Snacks & Dessert',
    icon: Icons.cookie_rounded,
  ),
  _OfficialMarketCategory(
    labelTr: 'Temizlik ve Kişisel Bakım Ürünleri',
    labelEn: 'Cleaning & Personal Care',
    icon: Icons.cleaning_services_rounded,
  ),
];

class _OfficialCategoryTileCard extends StatelessWidget {
  final _OfficialMarketCategory category;
  final int count;
  final bool isSelected;
  final bool isTr;
  final VoidCallback onTap;

  const _OfficialCategoryTileCard({
    required this.category,
    required this.count,
    required this.isSelected,
    required this.isTr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.78),
                  ],
                )
              : null,
          color: isSelected
              ? null
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              category.icon,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
            const Spacer(),
            Text(
              isTr ? category.labelTr : category.labelEn,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurface,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isTr ? '$count ürün' : '$count items',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isSelected
                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.88)
                    : theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentViewedCard extends StatelessWidget {
  final ActuellerCatalogItem item;
  final bool isTr;
  final VoidCallback onTap;

  const _RecentViewedCard({
    required this.item,
    required this.isTr,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final marketDisplay = displayNameForMarket(item.marketName);
    return SizedBox(
      width: 220,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.28),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(
                    alpha: 0.55,
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  marketDisplay.isEmpty ? item.marketName : marketDisplay,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  item.productTitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${_formatCompactPrice(item.price)} TL',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (item.weight != null)
                Text(
                  item.weight!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCompactPrice(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }
}

class _ComparisonRow extends StatelessWidget {
  final String marketName;
  final String productTitle;
  final double price;
  final String? weight;
  final bool isCurrent;
  final bool isCheapest;
  final ThemeData theme;

  const _ComparisonRow({
    required this.marketName,
    required this.productTitle,
    required this.price,
    required this.weight,
    required this.isCurrent,
    required this.isCheapest,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    final display = displayNameForMarket(marketName);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isCurrent
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.25)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(14),
        border: isCurrent
            ? Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  display.isEmpty ? marketName : display,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isCheapest
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  productTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                if (weight != null)
                  Text(
                    weight!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant
                          .withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${price.toStringAsFixed(2).replaceAll('.', ',')} TL',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: isCheapest
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface,
                ),
              ),
              if (isCheapest)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E7D32).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'En ucuz',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF2E7D32),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompareEntry {
  final String marketName;
  final String productTitle;
  final double price;
  final String? weight;
  final bool isCurrent;

  const _CompareEntry({
    required this.marketName,
    required this.productTitle,
    required this.price,
    required this.weight,
    required this.isCurrent,
  });
}

class _LocationSessionCard extends StatelessWidget {
  final bool isTr;
  final String? locationLabel;
  final VoidCallback? onTap;

  const _LocationSessionCard({
    required this.isTr,
    required this.locationLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasLocation =
        locationLabel != null && locationLabel!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasLocation
                    ? Icons.location_on_rounded
                    : Icons.location_searching_rounded,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isTr ? 'Resmî Fiyat Konumu' : 'Official Price Location',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasLocation
                ? locationLabel!
                : (isTr
                    ? 'Karşılaştırmada yakındaki marketleri kullanmak için konum seç.'
                    : 'Pick a location so comparison uses nearby stores.'),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: hasLocation
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              height: 1.4,
              fontWeight: hasLocation ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: Icon(
                hasLocation ? Icons.edit_location_alt_rounded : Icons.search,
              ),
              label: Text(
                hasLocation
                    ? (isTr ? 'Konumu Güncelle' : 'Change Location')
                    : (isTr ? 'Konum Seç' : 'Choose Location'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final bool isTr;
  final bool usesOfficialSource;

  const _HeroCard({
    required this.isTr,
    required this.usesOfficialSource,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A1734),
            Color(0xFF982B4E),
            Color(0xFFE06C3C),
          ],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF982B4E).withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  isTr
                      ? (usesOfficialSource
                          ? 'Yakındaki Market Fiyatları'
                          : 'Markette Bugün Ne Ucuz?')
                      : (usesOfficialSource
                          ? 'Nearby Market Prices'
                          : 'Deal Radar'),
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            isTr
                ? (usesOfficialSource
                    ? 'Konumunu seç, yakın marketlerde aynı ürünün fiyatını karşılaştıralım. Resmî veriyi net ve hızlı gör.'
                    : 'Marketini seç, broşürleri tarayalım. İndirimli ürünleri kategorili ve net bir şekilde gör.')
                : (usesOfficialSource
                    ? 'Choose your location and compare the same product across nearby stores with official pricing data.'
                    : 'Pick your stores, we scan flyers. See discounted products clearly by category.'),
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

class _MarketSelectorCard extends StatelessWidget {
  final bool isTr;
  final AppProvider provider;

  const _MarketSelectorCard({
    required this.isTr,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedIds =
        provider.smartKitchenPreferences.preferredMarkets.toSet();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.storefront_rounded,
                  size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isTr ? 'Marketlerin' : 'Your stores',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                SmartActuellerSourceService.availableMarkets.map((market) {
              final isSelected = selectedIds.contains(market.id);
              return FilterChip(
                selected: isSelected,
                showCheckmark: false,
                avatar: Text(market.emoji),
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
                  ? 'İndirimlerini görmek istediğin en az bir market seç.'
                  : 'Pick at least one store to see deals.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
