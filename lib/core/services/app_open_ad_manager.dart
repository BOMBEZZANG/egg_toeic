import 'dart:async';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:egg_toeic/ad_helper.dart';

class AppOpenAdManager {
  static final AppOpenAdManager _instance = AppOpenAdManager._internal();
  factory AppOpenAdManager() => _instance;
  AppOpenAdManager._internal();

  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isAdLoaded = false;

  /// Maximum duration for ad loading timeout
  static const int maxLoadDuration = 10; // seconds (test ads usually load in 1-3 seconds)

  /// Load the app open ad
  Future<void> loadAd() async {
    print('🎯 Loading app open ad with test ID: ${AdHelper.appOpenAdUnitId}');

    final completer = Completer<void>();

    AppOpenAd.load(
      adUnitId: AdHelper.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          print('✅ ✅ ✅ App open ad loaded successfully!');
          _appOpenAd = ad;
          _isAdLoaded = true;
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
        onAdFailedToLoad: (error) {
          print('❌ ❌ ❌ App open ad failed to load!');
          print('Error Code: ${error.code}');
          print('Error Domain: ${error.domain}');
          print('Error Message: ${error.message}');
          _isAdLoaded = false;
          if (!completer.isCompleted) {
            completer.complete();
          }
        },
      ),
    );

    // Timeout after maxLoadDuration seconds
    Timer(const Duration(seconds: maxLoadDuration), () {
      if (!completer.isCompleted) {
        print('⏰ App open ad loading timed out after $maxLoadDuration seconds');
        completer.complete();
      }
    });

    return completer.future;
  }

  /// Show the app open ad if loaded
  Future<void> showAdIfAvailable(Function onAdDismissed) async {
    print('📺 showAdIfAvailable called - _isAdLoaded: $_isAdLoaded, _isShowingAd: $_isShowingAd');

    if (!_isAdLoaded) {
      print('📭 App open ad is not loaded yet - calling onAdDismissed');
      onAdDismissed();
      return;
    }

    if (_isShowingAd) {
      print('📺 App open ad is already being shown');
      return;
    }

    if (_appOpenAd == null) {
      print('📭 App open ad is null - calling onAdDismissed');
      onAdDismissed();
      return;
    }

    print('🎬 Setting up ad callbacks and showing ad...');
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        print('✅ ✅ ✅ TEST AD IS NOW SHOWING FULL SCREEN!');
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ ❌ ❌ App open ad failed to show!');
        print('Show Error: $error');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _isAdLoaded = false;
        onAdDismissed();
      },
      onAdDismissedFullScreenContent: (ad) {
        print('✅ Test ad was dismissed by user');
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _isAdLoaded = false;
        onAdDismissed();
      },
    );

    print('🚀 Calling _appOpenAd.show()...');
    _appOpenAd!.show();
  }

  /// Dispose the ad
  void dispose() {
    _appOpenAd?.dispose();
    _appOpenAd = null;
    _isAdLoaded = false;
    _isShowingAd = false;
  }
}