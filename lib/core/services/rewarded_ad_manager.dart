import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:egg_toeic/ad_helper.dart';

class RewardedAdManager {
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isAdShowing = false;

  /// Load the rewarded ad
  Future<bool> loadAd() async {
    print('🎁 Loading rewarded ad with test ID: ${AdHelper.rewardedAdUnitId}');

    final completer = Completer<bool>();

    await RewardedAd.load(
      adUnitId: AdHelper.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ ✅ ✅ Rewarded ad loaded successfully!');
          _rewardedAd = ad;
          _isAdLoaded = true;
          if (!completer.isCompleted) {
            completer.complete(true);
          }
        },
        onAdFailedToLoad: (error) {
          print('❌ ❌ ❌ Rewarded ad failed to load!');
          print('Error Code: ${error.code}');
          print('Error Domain: ${error.domain}');
          print('Error Message: ${error.message}');
          _isAdLoaded = false;
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        },
      ),
    );

    // Timeout after 10 seconds
    Timer(const Duration(seconds: 10), () {
      if (!completer.isCompleted) {
        print('⏰ Rewarded ad loading timed out');
        completer.complete(false);
      }
    });

    return completer.future;
  }

  /// Show the rewarded ad if loaded
  Future<bool> showAd() async {
    print('🎁 showAd called - _isAdLoaded: $_isAdLoaded, _isAdShowing: $_isAdShowing');

    if (!_isAdLoaded || _rewardedAd == null) {
      print('📭 Rewarded ad is not loaded');
      return false;
    }

    if (_isAdShowing) {
      print('📺 Rewarded ad is already being shown');
      return false;
    }

    final completer = Completer<bool>();
    bool userEarnedReward = false;

    print('🎬 Setting up rewarded ad callbacks and showing ad...');
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isAdShowing = true;
        print('✅ ✅ ✅ REWARDED AD IS NOW SHOWING FULL SCREEN!');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ ❌ ❌ Rewarded ad failed to show!');
        print('Show Error: $error');
        _isAdShowing = false;
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
        if (!completer.isCompleted) {
          completer.complete(false);
        }
      },
      onAdDismissedFullScreenContent: (ad) {
        print('✅ Rewarded ad was dismissed by user');
        _isAdShowing = false;
        ad.dispose();
        _rewardedAd = null;
        _isAdLoaded = false;
        if (!completer.isCompleted) {
          completer.complete(userEarnedReward);
        }
      },
    );

    // Handle the reward
    await _rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        userEarnedReward = true;
        print('🎉 🎉 🎉 User earned reward: ${reward.amount} ${reward.type}');
      },
    );

    return completer.future;
  }

  /// Dispose the ad
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isAdLoaded = false;
    _isAdShowing = false;
  }
}