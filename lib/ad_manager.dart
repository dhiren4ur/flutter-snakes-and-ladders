import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';

class AdManager {
  static AdManager? _instance;
  static AdManager get instance => _instance ??= AdManager._internal();

  AdManager._internal();

  // ========== ANDROID ONLY AD UNIT IDS ==========
  // These are your real Android ad unit IDs
  static const String _bannerAdUnitId = 'ca-app-pub-9159991034200271/7756678111';
  static const String _interstitialAdUnitId = 'ca-app-pub-9159991034200271/2778123105';

  // Your Google Ad Manager App ID (Add this too!)
  // Get from: https://admob.google.com/home -> Settings -> App Settings
  static const String googleAdMobAppId = 'ca-app-pub-9159991034200271~3637265768'; // Replace with YOUR app ID

  BannerAd? _bannerAd;
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  // ========== Initialize AdMob ==========
  Future<void> initialize() async {
    if (Platform.isAndroid && !kIsWeb) {
      try {
        print('🚀 Initializing Google Mobile Ads...');
        await MobileAds.instance.initialize();
        print('✅ Google Mobile Ads initialized successfully');
        
        // Start loading interstitial ad in background
        _loadInterstitialAd();
      } catch (e) {
        print('❌ Error initializing ads: $e');
      }
    } else if (!Platform.isAndroid) {
      print('⚠️ AdMob: Only Android is supported. Ads disabled on this platform.');
    }
  }

  // ========== Banner Ad Methods ==========
  void loadBannerAd({required Function(BannerAd) onAdLoaded}) {
    if (Platform.isAndroid && !kIsWeb) {
      print('📦 Loading Banner Ad...');
      
      // Dispose old banner ad if exists to prevent memory leak
      _bannerAd?.dispose();
      _bannerAd = null;
      
      try {
        _bannerAd = BannerAd(
          adUnitId: _bannerAdUnitId,
          size: AdSize.banner,
          request: const AdRequest(),
          listener: BannerAdListener(
            onAdLoaded: (ad) {
              print('✅ Banner ad loaded successfully');
              onAdLoaded(ad as BannerAd);
            },
            onAdFailedToLoad: (ad, error) {
              print('❌ Banner ad failed to load: ${error.message}');
              ad.dispose();
              
              // Retry loading banner ad after 30 seconds
              print('🔄 Retrying banner ad in 30 seconds...');
              Future.delayed(const Duration(seconds: 30), () {
                loadBannerAd(onAdLoaded: onAdLoaded);
              });
            },
            onAdOpened: (ad) {
              print('📱 Banner ad opened');
            },
            onAdClosed: (ad) {
              print('❌ Banner ad closed');
            },
          ),
        );
        _bannerAd!.load();
      } catch (e) {
        print('❌ Error loading banner ad: $e');
      }
    } else {
      print('⚠️ Banner ads not available on this platform');
    }
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    print('🧹 Banner ad disposed');
  }

  // ========== Interstitial Ad Methods ==========
  void _loadInterstitialAd() {
    if (Platform.isAndroid && !kIsWeb) {
      print('📦 Loading Interstitial Ad...');
      
      try {
        InterstitialAd.load(
          adUnitId: _interstitialAdUnitId,
          request: const AdRequest(),
          adLoadCallback: InterstitialAdLoadCallback(
            onAdLoaded: (ad) {
              print('✅ Interstitial ad loaded successfully');
              _interstitialAd = ad;
              _isInterstitialAdReady = true;
              
              // Set full screen content callback
              _setInterstitialCallbacks(ad);
            },
            onAdFailedToLoad: (error) {
              print('❌ Interstitial ad failed to load: ${error.message}');
              _isInterstitialAdReady = false;
              
              // Retry after 1 minute if failed
              print('🔄 Retrying interstitial ad in 1 minute...');
              Future.delayed(const Duration(minutes: 1), _loadInterstitialAd);
            },
          ),
        );
      } catch (e) {
        print('❌ Error loading interstitial ad: $e');
      }
    }
  }

  // Set callbacks for interstitial ad display
  void _setInterstitialCallbacks(InterstitialAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        print('🎬 Interstitial ad showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        print('❌ Interstitial ad dismissed');
        ad.dispose();
        _isInterstitialAdReady = false;
        // Reload for next time
        _loadInterstitialAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        print('❌ Interstitial ad failed to show: ${error.message}');
        ad.dispose();
        _isInterstitialAdReady = false;
        // Reload for next time
        _loadInterstitialAd();
      },
    );
  }

  void showInterstitialAd({VoidCallback? onAdClosed}) {
    if (Platform.isAndroid && !kIsWeb) {
      if (_isInterstitialAdReady && _interstitialAd != null) {
        print('🎬 Showing Interstitial Ad...');
        
        try {
          _interstitialAd!.show();
          
          // Make sure callback is called after ad is dismissed
          // (Already handled in _setInterstitialCallbacks, but calling explicitly won't hurt)
          Future.delayed(const Duration(seconds: 1), () {
            if (!_isInterstitialAdReady) {
              // Ad was shown and dismissed
              onAdClosed?.call();
            }
          });
        } catch (e) {
          print('❌ Error showing interstitial ad: $e');
          _isInterstitialAdReady = false;
          onAdClosed?.call();
          _loadInterstitialAd();
        }
      } else {
        print('⚠️ Interstitial ad not ready. Loading...');
        onAdClosed?.call();
        // Try to load if not ready
        if (!_isInterstitialAdReady) {
          _loadInterstitialAd();
        }
      }
    } else {
      print('⚠️ Interstitial ads not available on this platform');
      onAdClosed?.call();
    }
  }

  // Check if interstitial ad is ready
  bool get isInterstitialAdReady => _isInterstitialAdReady;

  // Dispose all ads
  void dispose() {
    print('🧹 Disposing all ads...');
    _bannerAd?.dispose();
    _interstitialAd?.dispose();
    _bannerAd = null;
    _interstitialAd = null;
    _isInterstitialAdReady = false;
  }
}
