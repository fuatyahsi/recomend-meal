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
  final bool isLiveData;
  final String campaignLabelTr;
  final String campaignLabelEn;

  const MarketItemDeal({
    required this.shoppingItem,
    required this.market,
    required this.unitPrice,
    required this.totalPrice,
    required this.isCampaign,
    required this.isLiveData,
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
  final bool isLiveData;
  final String sourceLabel;

  const MarketBasketComparison({
    required this.market,
    required this.deals,
    required this.totalPrice,
    required this.campaignCount,
    required this.estimatedSavingsVsHighest,
    required this.isLiveData,
    required this.sourceLabel,
  });
}

class ReceiptScanResult {
  final List<Ingredient> matchedIngredients;
  final List<String> unmatchedLines;
  final double confidence;
  final String rawText;
  final String? detectedStore;
  final List<String> detectedLabels;
  final String? capturedImagePath;

  const ReceiptScanResult({
    required this.matchedIngredients,
    required this.unmatchedLines,
    required this.confidence,
    this.rawText = '',
    this.detectedStore,
    this.detectedLabels = const [],
    this.capturedImagePath,
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
  final List<String> detectedLabels;
  final int estimatedCalories;
  final String analysisPrompt;
  final String? capturedImagePath;
  final double confidence;

  const PlateAnalysisResult({
    required this.headlineTr,
    required this.headlineEn,
    required this.summaryTr,
    required this.summaryEn,
    required this.suggestedMoodId,
    required this.shareCaptionTr,
    required this.shareCaptionEn,
    required this.matchedRecipes,
    this.detectedLabels = const [],
    this.estimatedCalories = 0,
    this.analysisPrompt = '',
    this.capturedImagePath,
    this.confidence = 0,
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

class ReceiptVisionCapture {
  final String imagePath;
  final String rawText;
  final List<String> labels;
  final String? detectedStore;
  final double confidence;

  const ReceiptVisionCapture({
    required this.imagePath,
    required this.rawText,
    required this.labels,
    required this.detectedStore,
    required this.confidence,
  });
}

class PlateVisionCapture {
  final String imagePath;
  final List<String> labels;
  final String prompt;
  final int estimatedCalories;
  final double confidence;

  const PlateVisionCapture({
    required this.imagePath,
    required this.labels,
    required this.prompt,
    required this.estimatedCalories,
    required this.confidence,
  });
}

class PantryVisionImageCapture {
  final String imagePath;
  final String rawText;
  final List<String> labels;
  final double confidence;

  const PantryVisionImageCapture({
    required this.imagePath,
    required this.rawText,
    required this.labels,
    required this.confidence,
  });
}

class PantryVisionCapture {
  final String imagePath;
  final String rawText;
  final List<String> labels;
  final List<Ingredient> detectedIngredients;
  final double confidence;

  const PantryVisionCapture({
    required this.imagePath,
    required this.rawText,
    required this.labels,
    required this.detectedIngredients,
    required this.confidence,
  });
}

class PantryVisionSuggestion {
  final Ingredient ingredient;
  final int estimatedDaysLeft;
  final Recipe? rescueRecipe;
  final String titleTr;
  final String titleEn;
  final String bodyTr;
  final String bodyEn;

  const PantryVisionSuggestion({
    required this.ingredient,
    required this.estimatedDaysLeft,
    required this.rescueRecipe,
    required this.titleTr,
    required this.titleEn,
    required this.bodyTr,
    required this.bodyEn,
  });

  String title(String locale) => locale == 'tr' ? titleTr : titleEn;
  String body(String locale) => locale == 'tr' ? bodyTr : bodyEn;
}

class SurpriseBasketPick {
  final SmartShoppingItem shoppingItem;
  final String market;
  final double linePrice;
  final double estimatedSavingsVsHighest;

  const SurpriseBasketPick({
    required this.shoppingItem,
    required this.market,
    required this.linePrice,
    required this.estimatedSavingsVsHighest,
  });
}

class SurpriseBasketStop {
  final String market;
  final List<SurpriseBasketPick> picks;
  final double subtotal;

  const SurpriseBasketStop({
    required this.market,
    required this.picks,
    required this.subtotal,
  });
}

class SurpriseBasketPlan {
  final String titleTr;
  final String titleEn;
  final String bodyTr;
  final String bodyEn;
  final List<SurpriseBasketStop> stops;
  final double totalSpend;
  final double estimatedSavings;

  const SurpriseBasketPlan({
    required this.titleTr,
    required this.titleEn,
    required this.bodyTr,
    required this.bodyEn,
    required this.stops,
    required this.totalSpend,
    required this.estimatedSavings,
  });

  String title(String locale) => locale == 'tr' ? titleTr : titleEn;
  String body(String locale) => locale == 'tr' ? bodyTr : bodyEn;
}

class PriceTickerEntry {
  final Ingredient ingredient;
  final String market;
  final double price;
  final double deltaPercent;
  final bool isDrop;
  final String labelTr;
  final String labelEn;

  const PriceTickerEntry({
    required this.ingredient,
    required this.market,
    required this.price,
    required this.deltaPercent,
    required this.isDrop,
    required this.labelTr,
    required this.labelEn,
  });

  String label(String locale) => locale == 'tr' ? labelTr : labelEn;
}

class ProductPriceTickerEntry {
  final String productTitle;
  final String market;
  final double price;
  final double deltaPercent;
  final bool isDrop;

  const ProductPriceTickerEntry({
    required this.productTitle,
    required this.market,
    required this.price,
    required this.deltaPercent,
    required this.isDrop,
  });
}

class NeighborhoodSavingsEntry {
  final int rank;
  final String name;
  final String districtTr;
  final String districtEn;
  final double savingsValue;
  final int completedChallenges;
  final bool isCurrentUser;

  const NeighborhoodSavingsEntry({
    required this.rank,
    required this.name,
    required this.districtTr,
    required this.districtEn,
    required this.savingsValue,
    required this.completedChallenges,
    required this.isCurrentUser,
  });

  String district(String locale) => locale == 'tr' ? districtTr : districtEn;
}

class SponsoredRecipePlacement {
  final Recipe recipe;
  final String sponsorName;
  final String partnerName;
  final String titleTr;
  final String titleEn;
  final String bodyTr;
  final String bodyEn;
  final String ctaTr;
  final String ctaEn;

  const SponsoredRecipePlacement({
    required this.recipe,
    required this.sponsorName,
    required this.partnerName,
    required this.titleTr,
    required this.titleEn,
    required this.bodyTr,
    required this.bodyEn,
    required this.ctaTr,
    required this.ctaEn,
  });

  String title(String locale) => locale == 'tr' ? titleTr : titleEn;
  String body(String locale) => locale == 'tr' ? bodyTr : bodyEn;
  String cta(String locale) => locale == 'tr' ? ctaTr : ctaEn;
}

class RemoteMarketQuote {
  final String ingredientId;
  final String market;
  final double unitPrice;
  final bool isCampaign;
  final String campaignLabelTr;
  final String campaignLabelEn;

  const RemoteMarketQuote({
    required this.ingredientId,
    required this.market,
    required this.unitPrice,
    required this.isCampaign,
    required this.campaignLabelTr,
    required this.campaignLabelEn,
  });
}

class MarketFeedSnapshot {
  final String sourceLabel;
  final DateTime fetchedAt;
  final List<RemoteMarketQuote> quotes;

  const MarketFeedSnapshot({
    required this.sourceLabel,
    required this.fetchedAt,
    required this.quotes,
  });
}

class MarketSyncStatus {
  final bool isLoading;
  final bool usedLiveData;
  final String sourceLabel;
  final DateTime? lastSyncedAt;
  final String? message;

  const MarketSyncStatus({
    required this.isLoading,
    required this.usedLiveData,
    required this.sourceLabel,
    required this.lastSyncedAt,
    required this.message,
  });

  const MarketSyncStatus.idle()
      : isLoading = false,
        usedLiveData = false,
        sourceLabel = '',
        lastSyncedAt = null,
        message = null;
}
