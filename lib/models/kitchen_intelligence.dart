import 'ingredient.dart';
import 'recipe.dart';
import 'smart_kitchen.dart';

class PantryRiskItem {
  final Ingredient ingredient;
  final int count;
  final DateTime lastUpdatedAt;
  final int ageDays;
  final int shelfLifeDays;
  final double riskScore;
  final double estimatedLossValue;

  const PantryRiskItem({
    required this.ingredient,
    required this.count,
    required this.lastUpdatedAt,
    required this.ageDays,
    required this.shelfLifeDays,
    required this.riskScore,
    required this.estimatedLossValue,
  });

  bool get isHighRisk => riskScore >= 0.7;
  bool get isCritical => riskScore >= 1.0;
}

class WasteRescueSuggestion {
  final PantryRiskItem riskItem;
  final Recipe? rescueRecipe;
  final int missingUnits;
  final String titleTr;
  final String titleEn;
  final String bodyTr;
  final String bodyEn;

  const WasteRescueSuggestion({
    required this.riskItem,
    required this.rescueRecipe,
    required this.missingUnits,
    required this.titleTr,
    required this.titleEn,
    required this.bodyTr,
    required this.bodyEn,
  });

  String title(String locale) => locale == 'tr' ? titleTr : titleEn;
  String body(String locale) => locale == 'tr' ? bodyTr : bodyEn;
}

class MarketItemDeal {
  final SmartShoppingItem shoppingItem;
  final String market;
  final double unitPrice;
  final double totalPrice;
  final bool isCampaign;
  final String campaignLabelTr;
  final String campaignLabelEn;

  const MarketItemDeal({
    required this.shoppingItem,
    required this.market,
    required this.unitPrice,
    required this.totalPrice,
    required this.isCampaign,
    required this.campaignLabelTr,
    required this.campaignLabelEn,
  });

  String campaignLabel(String locale) =>
      locale == 'tr' ? campaignLabelTr : campaignLabelEn;
}

class MarketBasketComparison {
  final String market;
  final List<MarketItemDeal> deals;
  final double totalPrice;
  final int campaignCount;
  final double estimatedSavingsVsHighest;

  const MarketBasketComparison({
    required this.market,
    required this.deals,
    required this.totalPrice,
    required this.campaignCount,
    required this.estimatedSavingsVsHighest,
  });
}

class ReceiptScanResult {
  final List<Ingredient> matchedIngredients;
  final List<String> unmatchedLines;
  final double confidence;

  const ReceiptScanResult({
    required this.matchedIngredients,
    required this.unmatchedLines,
    required this.confidence,
  });
}

class PlateAnalysisResult {
  final String headlineTr;
  final String headlineEn;
  final String summaryTr;
  final String summaryEn;
  final String suggestedMoodId;
  final String shareCaptionTr;
  final String shareCaptionEn;
  final List<Recipe> matchedRecipes;

  const PlateAnalysisResult({
    required this.headlineTr,
    required this.headlineEn,
    required this.summaryTr,
    required this.summaryEn,
    required this.suggestedMoodId,
    required this.shareCaptionTr,
    required this.shareCaptionEn,
    required this.matchedRecipes,
  });

  String headline(String locale) => locale == 'tr' ? headlineTr : headlineEn;
  String summary(String locale) => locale == 'tr' ? summaryTr : summaryEn;
  String shareCaption(String locale) =>
      locale == 'tr' ? shareCaptionTr : shareCaptionEn;
}

class WeeklyMenuDigest {
  final String titleTr;
  final String titleEn;
  final String bodyTr;
  final String bodyEn;
  final List<Recipe> recipes;

  const WeeklyMenuDigest({
    required this.titleTr,
    required this.titleEn,
    required this.bodyTr,
    required this.bodyEn,
    required this.recipes,
  });

  String title(String locale) => locale == 'tr' ? titleTr : titleEn;
  String body(String locale) => locale == 'tr' ? bodyTr : bodyEn;
}

class DigitalTwinZone {
  final String id;
  final String labelTr;
  final String labelEn;
  final List<PantryRiskItem> items;

  const DigitalTwinZone({
    required this.id,
    required this.labelTr,
    required this.labelEn,
    required this.items,
  });

  String label(String locale) => locale == 'tr' ? labelTr : labelEn;
}

class FlavorPairSuggestion {
  final String titleTr;
  final String titleEn;
  final String bodyTr;
  final String bodyEn;
  final int score;

  const FlavorPairSuggestion({
    required this.titleTr,
    required this.titleEn,
    required this.bodyTr,
    required this.bodyEn,
    required this.score,
  });

  String title(String locale) => locale == 'tr' ? titleTr : titleEn;
  String body(String locale) => locale == 'tr' ? bodyTr : bodyEn;
}
