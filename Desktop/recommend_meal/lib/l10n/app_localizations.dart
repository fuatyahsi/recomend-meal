import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get languageCode => locale.languageCode;

  // --- App General ---
  String get appName => _t('FridgeChef', 'BuzdolabıŞef');
  String get appTagline => _t(
    'Cook with what you have!',
    'Elindekiyle pişir!',
  );

  // --- Navigation ---
  String get home => _t('Home', 'Ana Sayfa');
  String get myIngredients => _t('My Ingredients', 'Malzemelerim');
  String get recipes => _t('Recipes', 'Tarifler');
  String get favorites => _t('Favorites', 'Favoriler');
  String get settings => _t('Settings', 'Ayarlar');

  // --- Home Screen ---
  String get welcomeTitle => _t(
    'What\'s in your fridge?',
    'Buzdolabında ne var?',
  );
  String get welcomeSubtitle => _t(
    'Select your ingredients and discover recipes you can make!',
    'Malzemelerini seç, yapabileceğin tarifleri keşfet!',
  );
  String get startCooking => _t('Start Cooking', 'Yemek Yapmaya Başla');
  String get selectIngredients => _t('Select Ingredients', 'Malzemeleri Seç');

  // --- Ingredient Selection ---
  String get searchIngredients => _t('Search ingredients...', 'Malzeme ara...');
  String get selectedIngredients => _t('Selected', 'Seçilen');
  String get clearAll => _t('Clear All', 'Tümünü Temizle');
  String get findRecipes => _t('Find Recipes', 'Tarif Bul');
  String ingredientsSelected(int count) =>
      _t('$count ingredients selected', '$count malzeme seçildi');

  // --- Recipe List ---
  String get recipesFound => _t('Recipes Found', 'Bulunan Tarifler');
  String get noRecipesFound => _t(
    'No recipes found with your ingredients',
    'Malzemelerinle uyuşan tarif bulunamadı',
  );
  String get canMake => _t('Can make!', 'Yapabilirsin!');
  String get almostCanMake => _t('Almost!', 'Neredeyse!');
  String get matchPercentage => _t('match', 'uyum');
  String missingIngredients(int count) =>
      _t('$count missing ingredients', '$count eksik malzeme');
  String get showAll => _t('Show All', 'Tümünü Göster');
  String get showOnlyFullMatch =>
      _t('Full match only', 'Sadece tam uyuşanlar');

  // --- Recipe Detail ---
  String get ingredients => _t('Ingredients', 'Malzemeler');
  String get preparation => _t('Preparation', 'Hazırlanış');
  String get prepTime => _t('Prep', 'Hazırlık');
  String get cookTime => _t('Cook', 'Pişirme');
  String get totalTime => _t('Total', 'Toplam');
  String get servings => _t('Servings', 'Porsiyon');
  String get difficulty => _t('Difficulty', 'Zorluk');
  String get minutes => _t('min', 'dk');
  String get step => _t('Step', 'Adım');
  String get youHaveThis => _t('You have this ✓', 'Bu sende var ✓');
  String get youNeedThis => _t('Missing ✗', 'Eksik ✗');
  String get optional => _t('Optional', 'İsteğe bağlı');

  // --- Settings ---
  String get language => _t('Language', 'Dil');
  String get turkish => _t('Turkish', 'Türkçe');
  String get english => _t('English', 'İngilizce');
  String get darkMode => _t('Dark Mode', 'Karanlık Mod');
  String get about => _t('About', 'Hakkında');
  String get version => _t('Version', 'Sürüm');

  // --- Categories ---
  String get all => _t('All', 'Tümü');
  String get breakfast => _t('Breakfast', 'Kahvaltı');
  String get soup => _t('Soups', 'Çorbalar');
  String get mainDish => _t('Main Dish', 'Ana Yemek');
  String get sideDish => _t('Side Dish', 'Garnitür');
  String get dessert => _t('Dessert', 'Tatlı');

  String _t(String en, String tr) => locale.languageCode == 'tr' ? tr : en;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'tr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
