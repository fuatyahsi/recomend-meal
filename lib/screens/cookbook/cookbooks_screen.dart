import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cookbook_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
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
      _cookbooks = await _cookbookService.getUserCookbooks(auth.currentUser!.uid);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = context.read<AppProvider>().locale.languageCode == 'tr';
    final auth = context.watch<AuthProvider>();

    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: Text(isTr ? 'Tarif Defterlerim' : 'My Cookbooks')),
        body: Center(child: Text(isTr ? 'Giriş yapmalısın' : 'Please sign in')),
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
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('📒', style: TextStyle(fontSize: 64)),
                      const SizedBox(height: 16),
                      Text(
                        isTr
                            ? 'Henüz defterin yok'
                            : 'No cookbooks yet',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isTr
                            ? 'Tarifleri düzenlemek için defter oluştur'
                            : 'Create a cookbook to organize recipes',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _cookbooks.length,
                  itemBuilder: (context, index) {
                    final cb = _cookbooks[index];
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
                            child: Text(cb.emoji,
                                style: const TextStyle(fontSize: 28)),
                          ),
                        ),
                        title: Text(cb.name,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          '${cb.totalRecipes} ${isTr ? 'tarif' : 'recipes'}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete, color: Colors.red, size: 20),
                                  const SizedBox(width: 8),
                                  Text(isTr ? 'Sil' : 'Delete'),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 'delete') {
                              await _cookbookService.deleteCookbook(cb.id);
                              _loadCookbooks();
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context, isTr, auth.currentUser!.uid),
        icon: const Icon(Icons.add),
        label: Text(isTr ? 'Yeni Defter' : 'New Cookbook'),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, bool isTr, String userId) {
    final nameController = TextEditingController();
    String selectedEmoji = '📒';
    final emojis = ['📒', '🍳', '🥗', '🍰', '🥩', '🐟', '🥬', '🍝', '🫘', '🌮', '🍜', '☕'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isTr ? 'Yeni Defter Oluştur' : 'Create New Cookbook'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Emoji seçici
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: emojis.map((e) => GestureDetector(
                  onTap: () => setDialogState(() => selectedEmoji = e),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: selectedEmoji == e
                          ? Theme.of(context).colorScheme.primaryContainer
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      border: selectedEmoji == e
                          ? Border.all(color: Theme.of(context).colorScheme.primary)
                          : null,
                    ),
                    child: Text(e, style: const TextStyle(fontSize: 24)),
                  ),
                )).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: isTr ? 'Defter Adı' : 'Cookbook Name',
                  hintText: isTr ? 'ör: Diyet Tarifleri' : 'e.g. Diet Recipes',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(isTr ? 'İptal' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) return;
                await _cookbookService.createCookbook(
                  userId: userId,
                  name: nameController.text.trim(),
                  emoji: selectedEmoji,
                );
                Navigator.pop(context);
                _loadCookbooks();
              },
              child: Text(isTr ? 'Oluştur' : 'Create'),
            ),
          ],
        ),
      ),
    );
  }
}
