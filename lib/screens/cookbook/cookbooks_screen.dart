import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/cookbook_model.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/cookbook_service.dart';

class CookbooksScreen extends StatefulWidget {
  const CookbooksScreen({super.key});

  @override
  State<CookbooksScreen> createState() => _CookbooksScreenState();
}

class _CookbooksScreenState extends State<CookbooksScreen> {
  final _cookbookService = CookbookService();
  List<Cookbook> _cookbooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCookbooks();
  }

  Future<void> _loadCookbooks() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;
    try {
      _cookbooks = await _cookbookService.getUserCookbooks(
        auth.currentUser!.uid,
      );
    } catch (_) {}
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = context.read<AppProvider>().locale.languageCode == 'tr';
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(
          title: Text(isTr ? 'Tarif Defterlerim' : 'My Cookbooks'),
        ),
        body: Center(
          child: Text(
            isTr ? 'Giriş yapmalısın.' : 'Please sign in.',
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isTr ? 'Tarif Defterlerim' : 'My Cookbooks'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _cookbooks.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.menu_book_rounded,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          isTr ? 'Henüz defterin yok' : 'No cookbooks yet',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isTr
                              ? 'Tariflerini düzenlemek için bir defter oluştur.'
                              : 'Create a cookbook to organize your recipes.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cookbooks.length,
                  itemBuilder: (context, index) {
                    final cookbook = _cookbooks[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              cookbook.emoji,
                              style: const TextStyle(fontSize: 28),
                            ),
                          ),
                        ),
                        title: Text(
                          cookbook.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${cookbook.totalRecipes} ${isTr ? 'tarif' : 'recipes'}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.delete,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(isTr ? 'Sil' : 'Delete'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'delete') {
                              await _cookbookService
                                  .deleteCookbook(cookbook.id);
                              _loadCookbooks();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            _showCreateDialog(context, isTr, auth.currentUser!.uid),
        icon: const Icon(Icons.add),
        label: Text(isTr ? 'Yeni Defter' : 'New Cookbook'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, bool isTr, String userId) {
    final nameController = TextEditingController();
    var selectedEmoji = '\u{1F4D2}';
    var isSubmitting = false;
    const emojis = [
      '\u{1F4D2}',
      '\u{1F373}',
      '\u{1F955}',
      '\u{1F370}',
      '\u{1F96A}',
      '\u{1F41F}',
      '\u{1F96C}',
      '\u{1F35D}',
      '\u{1FAD8}',
      '\u{1F32E}',
      '\u{1F35C}',
      '\u{2615}',
    ];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            isTr ? 'Yeni Defter Oluştur' : 'Create New Cookbook',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: emojis.map((emoji) {
                  return GestureDetector(
                    onTap: isSubmitting
                        ? null
                        : () => setDialogState(() => selectedEmoji = emoji),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: selectedEmoji == emoji
                            ? Theme.of(dialogContext)
                                .colorScheme
                                .primaryContainer
                            : null,
                        borderRadius: BorderRadius.circular(8),
                        border: selectedEmoji == emoji
                            ? Border.all(
                                color:
                                    Theme.of(dialogContext).colorScheme.primary,
                              )
                            : null,
                      ),
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                enabled: !isSubmitting,
                decoration: InputDecoration(
                  labelText: isTr ? 'Defter Adı' : 'Cookbook Name',
                  hintText:
                      isTr ? 'Ör: Haftalık Favoriler' : 'e.g. Weekly Favorites',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: Text(isTr ? 'İptal' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final trimmedName = nameController.text.trim();
                      if (trimmedName.isEmpty) return;

                      setDialogState(() => isSubmitting = true);

                      try {
                        await _cookbookService.createCookbook(
                          userId: userId,
                          name: trimmedName,
                          emoji: selectedEmoji,
                        );

                        if (!dialogContext.mounted) return;
                        Navigator.pop(dialogContext);
                        _loadCookbooks();
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isTr ? 'Oluştur' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
