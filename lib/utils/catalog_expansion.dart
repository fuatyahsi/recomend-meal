Map<String, String> _ingredientVariantStyle(String category) {
  switch (category) {
    case 'vegetables':
      return const {
        'tr_prefix': 'Mevsimlik ',
        'tr_suffix': '',
        'en_prefix': 'Seasonal ',
        'en_suffix': '',
      };
    case 'fruits':
      return const {
        'tr_prefix': 'Olgun ',
        'tr_suffix': '',
        'en_prefix': 'Ripe ',
        'en_suffix': '',
      };
    case 'meat':
      return const {
        'tr_prefix': 'Marine ',
        'tr_suffix': '',
        'en_prefix': 'Marinated ',
        'en_suffix': '',
      };
    case 'dairy':
      return const {
        'tr_prefix': '',
        'tr_suffix': ' Hafif',
        'en_prefix': '',
        'en_suffix': ' Light',
      };
    case 'grains':
      return const {
        'tr_prefix': 'Tam ',
        'tr_suffix': '',
        'en_prefix': 'Whole ',
        'en_suffix': '',
      };
    case 'spices':
      return const {
        'tr_prefix': '',
        'tr_suffix': ' Kar\u0131\u015f\u0131m\u0131',
        'en_prefix': '',
        'en_suffix': ' Blend',
      };
    case 'oils':
      return const {
        'tr_prefix': '',
        'tr_suffix': ' Sosu',
        'en_prefix': '',
        'en_suffix': ' Sauce',
      };
    default:
      return const {
        'tr_prefix': '\u00d6zel ',
        'tr_suffix': '',
        'en_prefix': 'Special ',
        'en_suffix': '',
      };
  }
}

Map<String, dynamic> _buildIngredientVariant(Map<String, dynamic> ingredient) {
  final category = (ingredient['category'] ?? 'other').toString();
  final style = _ingredientVariantStyle(category);
  final nameTr = (ingredient['name_tr'] ?? '').toString();
  final nameEn = (ingredient['name_en'] ?? '').toString();

  return {
    ...ingredient,
    'id': '${ingredient['id']}_plus',
    'name_tr': '${style['tr_prefix']}$nameTr${style['tr_suffix']}',
    'name_en': '${style['en_prefix']}$nameEn${style['en_suffix']}',
  };
}

List<Map<String, dynamic>> expandIngredientCatalog(
  List<Map<String, dynamic>> ingredients,
) {
  return [
    ...ingredients,
    ...ingredients.map(_buildIngredientVariant),
  ];
}

Map<String, String> _recipeVariantStyle(String category) {
  switch (category) {
    case 'breakfast':
      return const {
        'tr_prefix': 'Pratik ',
        'en_prefix': 'Quick ',
      };
    case 'soup':
      return const {
        'tr_prefix': 'Ev Usul\u00fc ',
        'en_prefix': 'Homestyle ',
      };
    case 'salad':
      return const {
        'tr_prefix': 'Renkli ',
        'en_prefix': 'Colorful ',
      };
    case 'appetizer':
      return const {
        'tr_prefix': 'Payla\u015f\u0131ml\u0131k ',
        'en_prefix': 'Sharing ',
      };
    case 'dessert':
      return const {
        'tr_prefix': '\u00d6zel ',
        'en_prefix': 'Special ',
      };
    case 'beverage':
      return const {
        'tr_prefix': 'Serin ',
        'en_prefix': 'Refreshing ',
      };
    case 'side':
      return const {
        'tr_prefix': 'F\u0131r\u0131nda ',
        'en_prefix': 'Baked ',
      };
    default:
      return const {
        'tr_prefix': '\u015eef Usul\u00fc ',
        'en_prefix': 'Chef Style ',
      };
  }
}

Map<String, dynamic> _buildRecipeVariant(Map<String, dynamic> recipe) {
  final category = (recipe['category'] ?? '').toString();
  final style = _recipeVariantStyle(category);
  final stepsTr = ((recipe['steps_tr'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>())
      .map((step) => Map<String, dynamic>.from(step))
      .toList();
  final stepsEn = ((recipe['steps_en'] as List<dynamic>? ?? const [])
          .cast<Map<String, dynamic>>())
      .map((step) => Map<String, dynamic>.from(step))
      .toList();
  stepsTr.add({
    'step_number': stepsTr.length + 1,
    'instruction':
        'Servis etmeden once tadini kontrol et ve kendi damak zevkine gore son dokunusu yap.',
    'duration_minutes': 1,
  });
  stepsEn.add({
    'step_number': stepsEn.length + 1,
    'instruction':
        'Taste before serving and make a final adjustment to match your preference.',
    'duration_minutes': 1,
  });

  final originalTags =
      (recipe['tags'] as List<dynamic>? ?? const []).cast<String>();
  final tags = <String>[
    ...originalTags,
    if (!originalTags.contains('genis-katalog')) 'genis-katalog',
  ];

  return {
    ...recipe,
    'id': '${recipe['id']}_plus',
    'name_tr': '${style['tr_prefix']}${recipe['name_tr']}',
    'name_en': '${style['en_prefix']}${recipe['name_en']}',
    'description_tr':
        '${recipe['description_tr']} Alternatif sunumuyla men\u00fcn\u00fc zenginle\u015ftirir.',
    'description_en':
        '${recipe['description_en']} Adds a broader menu alternative.',
    'prep_time_minutes': (recipe['prep_time_minutes'] as int? ?? 0) + 1,
    'cook_time_minutes': (recipe['cook_time_minutes'] as int? ?? 0) + 2,
    'steps_tr': stepsTr,
    'steps_en': stepsEn,
    'tags': tags,
  };
}

List<Map<String, dynamic>> expandRecipeCatalog(
  List<Map<String, dynamic>> recipes,
) {
  return [
    ...recipes,
    ...recipes.map(_buildRecipeVariant),
  ];
}
