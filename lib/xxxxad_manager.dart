import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AdManager {
  static AdManager? _instance;
  static AdManager get instance => _instance ??= AdManager._internal();
  AdManager._internal();

  // ========== ANDROID ONLY - NO TEST IDS ==========
  
  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      // ⭐ TODO: INSERT YOUR REAL BANNER AD UNIT ID from AdMob
      // Format: ca-app-pub-XXXXXXXXXXXXXXXX/YYYYYYYYYYYYYY
      return 'ca-app-pub-9159991034200271/7756678111';
    }
    return '';
  }

  static String get interstitialAdUnitId {
    if (Platform.isAndroid) {
      // ⭐ TODO: INSERT YOUR REAL INTERSTITIAL AD UNIT ID from AdMob
      // Format: ca-app-pub-XXXXXXXXXXXXXXXX/ZZZZZZZZZZZZZZ
      return 'ca-app-pub-9159991034200271/2778123105';
    }
    return '';
  }

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  // ========== Initialize AdMob ==========
  Future<void> initialize() async {
    if (Platform.isAndroid) {
      try {
        print('🚀 Initializing Google Mobile Ads...');
        await MobileAds.instance.initialize();
        print('✅ Google Mobile Ads initialized');
        _loadInterstitialAd();
      } catch (e) {
        print('❌ Error initializing ads: $e');
      }
    }
  }

  // ========== Banner Ad Methods ==========
  void loadBannerAd({required Function(BannerAd) onAdLoaded}) {
    if (Platform.isAndroid) {
      print('📦 Loading Banner Ad...');
      try {
        _bannerAd = BannerAd(
          adUnitId: bannerAdUnitId,
          size: AdSize.banner,
          request: const AdRequest(),
          listener: BannerAdListener(
            onAdLoaded: (ad) {
              print('✅ Banner ad loaded');
              onAdLoaded(ad as BannerAd);
            },
            onAdFailedToLoad: (ad, error) {
              print('❌ Banner ad failed: ${error.message}');
              ad.dispose();
            },
          ),
        );
        
        _bannerAd!.load();
      } catch (e) {
        print('❌ Banner ad error: $e');
      }
    }
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  // ========== Interstitial Ad Methods ==========
  void _loadInterstitialAd() {
    if (Platform.isAndroid) {
      print('📦 Loading Interstitial Ad...');
      try {
        InterstitialAd.load(
          adUnitId: interstitialAdUnitId,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              print('✅ Interstitial ad loaded');
              _interstitialAd = ad;
              _isInterstitialAdReady = true;

              ad.fullScreenContentCallback = FullScreenContentCallback(
                onAdDismissedFullScreenContent: (ad) {
                  print('❌ Interstitial ad dismissed');
                  ad.dispose();
                  _loadInterstitialAd();
                },
                onAdFailedToShowFullScreenContent: (ad, error) {
                  print('❌ Interstitial ad failed: $error');
                  ad.dispose();
                  _loadInterstitialAd();
                },
              );
            },
            onAdFailedToLoad: (error) {
              print('❌ Interstitial ad failed to load: ${error.message}');
              _isInterstitialAdReady = false;
              Future.delayed(const Duration(minutes: 1), _loadInterstitialAd);
            },
          ),
        );
      } catch (e) {
        print('❌ Interstitial ad error: $e');
      }
    }
  }

  void showInterstitialAd({VoidCallback? onAdClosed}) {
    if (Platform.isAndroid) {
      if (_isInterstitialAdReady && _interstitialAd != null) {
        print('🎬 Showing Interstitial Ad...');
        
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            print('❌ Interstitial dismissed, reloading...');
            ad.dispose();
            _isInterstitialAdReady = false;
            _loadInterstitialAd();
            onAdClosed?.call();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            print('❌ Interstitial failed: $error');
            ad.dispose();
            _isInterstitialAdReady = false;
            _loadInterstitialAd();
            onAdClosed?.call();
          },
        );
        
        _interstitialAd!.show();
      } else {
        print('⚠️ Interstitial ad not ready');
        onAdClosed?.call();
      }
    } else {
      onAdClosed?.call();
    }
  }

  bool get isInterstitialAdReady => _isInterstitialAdReady;

  void dispose() {
    print('🧹 Disposing ads...');
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
  }
}
