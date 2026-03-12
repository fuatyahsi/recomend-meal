import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  bool _isInitialized = false;
  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  int _actionCount = 0;
  static const int _interstitialFrequency = 3; // Show every 3 actions

  // Test Ad Unit IDs (replace with real ones for production)
  String get bannerAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'  // Android test
      : 'ca-app-pub-3940256099942544/2934735716';  // iOS test

  String get interstitialAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/1033173712'
      : 'ca-app-pub-3940256099942544/4411468910';

  String get rewardedAdUnitId => Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/5224354917'
      : 'ca-app-pub-3940256099942544/1712485313';

  Future<void> initialize() async {
    if (_isInitialized) return;
    await MobileAds.instance.initialize();
    _isInitialized = true;
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  // --- Banner Ad ---
  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    )..load();
  }

  // --- Interstitial Ad ---
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadInterstitialAd(); // Preload next
            },
          );
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  /// Track user actions and show interstitial when threshold reached
  void trackAction() {
    _actionCount++;
  }

  bool shouldShowInterstitial() {
    return _actionCount >= _interstitialFrequency && _interstitialAd != null;
  }

  Future<void> showInterstitialAd() async {
    if (_interstitialAd != null) {
      await _interstitialAd!.show();
      _interstitialAd = null;
      _actionCount = 0;
    }
  }

  // --- Rewarded Ad ---
  void _loadRewardedAd() {
    RewardedAd.load(
      adUnitId: rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
        },
      ),
    );
  }

  bool get isRewardedAdReady => _rewardedAd != null;

  Future<bool> showRewardedAd() async {
    if (_rewardedAd == null) return false;

    bool rewarded = false;
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd(); // Preload next
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        rewarded = true;
      },
    );

    _rewardedAd = null;
    return rewarded;
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}
