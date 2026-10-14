import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  AdService({this.rewardedAdUnitId});

  final String? rewardedAdUnitId;
  RewardedAd? _rewardedAd;
  bool _isInitialized = false;

  bool get hasLiveAdUnit =>
      rewardedAdUnitId != null && rewardedAdUnitId!.trim().isNotEmpty;

  Future<void> initialize() async {
    if (!hasLiveAdUnit) {
      _isInitialized = true;
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _isInitialized = true;
      _loadRewardedAd();
    } catch (_) {
      _isInitialized = false;
    }
  }

  void _loadRewardedAd() {
    if (!hasLiveAdUnit || !_isInitialized) return;
    RewardedAd.load(
      adUnitId: rewardedAdUnitId!,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
        },
        onAdFailedToLoad: (_) {
          _rewardedAd = null;
        },
      ),
    );
  }

  Future<bool> showRewardedAd({
    required VoidCallback onRewardEarned,
  }) async {
    if (!hasLiveAdUnit || _rewardedAd == null) {
      onRewardEarned();
      return true;
    }

    final ad = _rewardedAd!;
    _rewardedAd = null;
    bool earned = false;

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _loadRewardedAd();
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        _loadRewardedAd();
      },
    );

    await ad.show(
      onUserEarnedReward: (_, __) {
        earned = true;
        onRewardEarned();
      },
    );
    return earned;
  }
}
