import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/community_recipe_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/community_recipe_service.dart';

class SubmitRecipeScreen extends StatefulWidget {
  const SubmitRecipeScreen({super.key});

  @override
  State<SubmitRecipeScreen> createState() => _SubmitRecipeScreenState();
}

class _SubmitRecipeScreenState extends State<SubmitRecipeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameTrController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _descTrController = TextEditingController();
  final _descEnController = TextEditingController();
  final _recipeService = CommunityRecipeService();

  String _difficulty = 'easy';
  String _category = 'main';
  int _prepTime = 10;
  int _cookTime = 20;
  int _servings = 4;
  String _emoji = '🍽️';
  bool _isSubmitting = false;

  final List<_StepInput> _stepsTr = [_StepInput()];
  final List<_StepInput> _stepsEn = [_StepInput()];

  final List<String> _emojis = [
    '🍽️', '🍳', '🥣', '🍝', '🍗', '🥩', '🐟', '🥬',
    '🍆', '🥔', '🫘', '🌾', '🥗', '🍲', '🥘', '🧁',
  ];

  @override
  void dispose() {
    _nameTrController.dispose();
    _nameEnController.dispose();
    _descTrController.dispose();
    _descEnController.dispose();
    for (final s in _stepsTr) s.controller.dispose();
    for (final s in _stepsEn) s.controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) return;

    setState(() => _isSubmitting = true);

    try {
      final recipe = CommunityRecipe(
        id: '',
        userId: auth.currentUser!.uid,
        userDisplayName: auth.currentUser!.displayName,
        userPhotoURL: auth.currentUser!.photoURL,
        nameTr: _nameTrController.text.trim(),
        nameEn: _nameEnController.text.trim().isEmpty
            ? _nameTrController.text.trim()
            : _nameEnController.text.trim(),
        descriptionTr: _descTrController.text.trim(),
        descriptionEn: _descEnController.text.trim().isEmpty
            ? _descTrController.text.trim()
            : _descEnController.text.trim(),
        ingredients: [], // simplified for now
        stepsTr: _stepsTr
            .asMap()
            .entries
            .where((e) => e.value.controller.text.isNotEmpty)
            .map((e) => CommunityRecipeStep(
                  stepNumber: e.key + 1,
                  instruction: e.value.controller.text.trim(),
                ))
            .toList(),
        stepsEn: _stepsEn
            .asMap()
            .entries
            .where((e) => e.value.controller.text.isNotEmpty)
            .map((e) => CommunityRecipeStep(
                  stepNumber: e.key + 1,
                  instruction: e.value.controller.text.trim(),
                ))
            .toList(),
        prepTimeMinutes: _prepTime,
        cookTimeMinutes: _cookTime,
        servings: _servings,
        difficulty: _difficulty,
        category: _category,
        imageEmoji: _emoji,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _recipeService.submitRecipe(recipe);
      await auth.refreshUser(); // Check for new badges

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).languageCode == 'tr'
                ? 'Tarifin paylaşıldı!'
                : 'Recipe shared!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTr = AppLocalizations.of(context).languageCode == 'tr';

    return Scaffold(
      appBar: AppBar(
        title: Text(isTr ? 'Tarif Paylaş' : 'Share Recipe'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Emoji picker
              Text(isTr ? 'Tarif İkonu' : 'Recipe Icon',
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _emojis
                    .map((e) => GestureDetector(
                          onTap: () => setState(() => _emoji = e),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _emoji == e
                                  ? theme.colorScheme.primaryContainer
                                  : null,
                              borderRadius: BorderRadius.circular(8),
                              border: _emoji == e
                                  ? Border.all(color: theme.colorScheme.primary)
                                  : null,
                            ),
                            child: Text(e, style: const TextStyle(fontSize: 28)),
                          ),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),

              // Name TR
              TextFormField(
                controller: _nameTrController,
                decoration: InputDecoration(
                  labelText: '${isTr ? "Tarif Adı" : "Recipe Name"} (TR) *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? (isTr ? 'Tarif adı gerekli' : 'Recipe name required')
                    : null,
              ),
              const SizedBox(height: 12),

              // Name EN
              TextFormField(
                controller: _nameEnController,
                decoration: InputDecoration(
                  labelText: '${isTr ? "Tarif Adı" : "Recipe Name"} (EN)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),

              // Description TR
              TextFormField(
                controller: _descTrController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: '${isTr ? "Açıklama" : "Description"} (TR) *',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? (isTr ? 'Açıklama gerekli' : 'Description required')
                    : null,
              ),
              const SizedBox(height: 12),

              // Description EN
              TextFormField(
                controller: _descEnController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: '${isTr ? "Açıklama" : "Description"} (EN)',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),

              // Metadata row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _difficulty,
                      decoration: InputDecoration(
                        labelText: isTr ? 'Zorluk' : 'Difficulty',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 'easy', child: Text(isTr ? 'Kolay' : 'Easy')),
                        DropdownMenuItem(
                            value: 'medium', child: Text(isTr ? 'Orta' : 'Medium')),
                        DropdownMenuItem(
                            value: 'hard', child: Text(isTr ? 'Zor' : 'Hard')),
                      ],
                      onChanged: (v) => setState(() => _difficulty = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: InputDecoration(
                        labelText: isTr ? 'Kategori' : 'Category',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 'breakfast',
                            child: Text(isTr ? 'Kahvaltı' : 'Breakfast')),
                        DropdownMenuItem(
                            value: 'soup',
                            child: Text(isTr ? 'Çorba' : 'Soup')),
                        DropdownMenuItem(
                            value: 'main',
                            child: Text(isTr ? 'Ana Yemek' : 'Main')),
                        DropdownMenuItem(
                            value: 'side',
                            child: Text(isTr ? 'Garnitür' : 'Side')),
                        DropdownMenuItem(
                            value: 'dessert',
                            child: Text(isTr ? 'Tatlı' : 'Dessert')),
                      ],
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Time and servings
              Row(
                children: [
                  _NumberField(
                    label: isTr ? 'Hazırlık (dk)' : 'Prep (min)',
                    value: _prepTime,
                    onChanged: (v) => setState(() => _prepTime = v),
                  ),
                  const SizedBox(width: 12),
                  _NumberField(
                    label: isTr ? 'Pişirme (dk)' : 'Cook (min)',
                    value: _cookTime,
                    onChanged: (v) => setState(() => _cookTime = v),
                  ),
                  const SizedBox(width: 12),
                  _NumberField(
                    label: isTr ? 'Porsiyon' : 'Servings',
                    value: _servings,
                    onChanged: (v) => setState(() => _servings = v),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Steps TR
              Text(
                isTr ? 'Hazırlanış Adımları (TR) *' : 'Preparation Steps (TR) *',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._stepsTr.asMap().entries.map((e) => _StepField(
                    index: e.key,
                    controller: e.value.controller,
                    onRemove: _stepsTr.length > 1
                        ? () => setState(() => _stepsTr.removeAt(e.key))
                        : null,
                  )),
              TextButton.icon(
                onPressed: () => setState(() => _stepsTr.add(_StepInput())),
                icon: const Icon(Icons.add),
                label: Text(isTr ? 'Adım Ekle' : 'Add Step'),
              ),

              const SizedBox(height: 16),

              // Steps EN
              Text(
                isTr ? 'Hazırlanış Adımları (EN)' : 'Preparation Steps (EN)',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ..._stepsEn.asMap().entries.map((e) => _StepField(
                    index: e.key,
                    controller: e.value.controller,
                    onRemove: _stepsEn.length > 1
                        ? () => setState(() => _stepsEn.removeAt(e.key))
                        : null,
                  )),
              TextButton.icon(
                onPressed: () => setState(() => _stepsEn.add(_StepInput())),
                icon: const Icon(Icons.add),
                label: Text(isTr ? 'Adım Ekle' : 'Add Step'),
              ),

              const SizedBox(height: 32),

              // Submit
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submit,
                  icon: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                  label: Text(isTr ? 'Tarifi Paylaş' : 'Share Recipe'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepInput {
  final TextEditingController controller = TextEditingController();
}

class _StepField extends StatelessWidget {
  final int index;
  final TextEditingController controller;
  final VoidCallback? onRemove;

  const _StepField({
    required this.index,
    required this.controller,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 14,
            child: Text('${index + 1}', style: const TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextFormField(
              controller: controller,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Adım ${index + 1} / Step ${index + 1}',
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _NumberField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, size: 20),
                onPressed: value > 1 ? () => onChanged(value - 5) : null,
              ),
              Text('$value',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, size: 20),
                onPressed: () => onChanged(value + 5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
