import 'package:flutter/foundation.dart';

/// Central AdMob unit IDs. Mediation (Meta) is configured in the AdMob console
/// against these same units — the app only requests the AdMob unit ID.
abstract final class AdConfig {
  /// When true, Google sample / test ad units are used.
  static const bool kUseTestAds = !kReleaseMode;

  static const _testAppId = 'ca-app-pub-3940256099942544~3347511713';
  static const _testBanner = 'ca-app-pub-3940256099942544/6300978111';
  static const _testInterstitial = 'ca-app-pub-3940256099942544/1033173712';
  static const _testNative = 'ca-app-pub-3940256099942544/2247696110';

  /// Replace these with your real AdMob IDs before shipping a release build.
  static const _prodAppId = 'YOUR_ADMOB_APP_ID';
  static const _prodBanner = 'YOUR_BANNER_ID';
  static const _prodInterstitial = 'YOUR_INTERSTITIAL_ID';
  static const _prodNative = 'YOUR_NATIVE_ID';

  static String get appId => kUseTestAds ? _testAppId : _prodAppId;

  static String get bannerId => kUseTestAds ? _testBanner : _prodBanner;

  static String get interstitialId =>
      kUseTestAds ? _testInterstitial : _prodInterstitial;

  static String get nativeId => kUseTestAds ? _testNative : _prodNative;

  /// Optional hashed test device IDs for [RequestConfiguration] in debug.
  /// Copy the ID from logcat (`Use RequestConfiguration.Builder...`).
  static const List<String> testDeviceIds = <String>[
    // '33BE2250B43518CCDA7DE426D04EE231',
  ];
}
