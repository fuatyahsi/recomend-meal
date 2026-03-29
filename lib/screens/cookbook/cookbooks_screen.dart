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

  static const _defaultCookbookEmoji = '\u{1F4D2}';
  static const _emojiOptions = [
    '\u{1F4D2}',
    '\u{1F373}',
    '\u{1F955}',
    '\u{1F370}',
    '\u{1F96A}',
    '\u{1F41F}',
    '\u{1F96C}',
    '\u{1F35D}',
    '\u{1FAD9}',
    '\u{1F32E}',
    '\u{1F35C}',
    '\u2615',
  ];

  @override
  void initState() {
    super.initState();
    _loadCookbooks();
  }

  Future<void> _loadCookbooks() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      return;
    }

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
            isTr ? 'Giri\u015f yapmal\u0131s\u0131n.' : 'Please sign in.',
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
                          isTr ? 'Hen\u00fcz defterin yok' : 'No cookbooks yet',
                          style: theme.textTheme.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isTr
                              ? 'Tariflerini d\u00fczenlemek i\u00e7in bir defter olu\u015ftur.'
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
                                    Icons.delete_outline_rounded,
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
                              await _loadCookbooks();
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
    final messenger = ScaffoldMessenger.of(context);
    final nameController = TextEditingController();
    var selectedEmoji = _defaultCookbookEmoji;
    var isSubmitting = false;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: Text(
            isTr ? 'Yeni Defter Olu\u015ftur' : 'Create New Cookbook',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _emojiOptions.map((emoji) {
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
                  labelText: isTr ? 'Defter Ad\u0131' : 'Cookbook Name',
                  hintText: isTr
                      ? '\u00d6r: Haftal\u0131k Favoriler'
                      : 'e.g. Weekly Favorites',
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
              child: Text(isTr ? '\u0130ptal' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final trimmedName = nameController.text.trim();
                      if (trimmedName.isEmpty) {
                        return;
                      }

                      setDialogState(() => isSubmitting = true);

                      try {
                        await _cookbookService.createCookbook(
                          userId: userId,
                          name: trimmedName,
                          emoji: selectedEmoji,
                        );

                        if (!dialogContext.mounted) {
                          return;
                        }
                        Navigator.pop(dialogContext);
                        await _loadCookbooks();
                      } on CookbookAlreadyExistsException {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              isTr
                                  ? 'Ayn\u0131 isimde bir defter zaten var.'
                                  : 'A cookbook with the same name already exists.',
                            ),
                          ),
                        );
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
                  : Text(isTr ? 'Olu\u015ftur' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
