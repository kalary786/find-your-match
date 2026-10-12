import 'dart:async';

import 'package:find_your_match/features/ads/ad_config.dart';
import 'package:find_your_match/features/ads/ads_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Preloads one AdMob interstitial (Meta via mediation) with gentle frequency.
class InterstitialManager {
  InterstitialManager(this._ads);

  final AdsService _ads;
  InterstitialAd? _ad;
  var _loading = false;
  var _showing = false;
  final _startedAt = DateTime.now();
  DateTime? _lastShown;

  static const _minSessionAge = Duration(seconds: 60);
  static const _minGap = Duration(minutes: 3);

  Future<void> preload() async {
    if (_loading || _ad != null) return;
    _loading = true;
    try {
      await _ads.ready;
      final done = Completer<void>();
      await InterstitialAd.load(
        adUnitId: AdConfig.interstitialId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            AdsService.logLoad(
              format: 'interstitial',
              success: true,
              network: ad.responseInfo?.mediationAdapterClassName,
            );
            _ad = ad;
            if (!done.isCompleted) done.complete();
          },
          onAdFailedToLoad: (error) {
            AdsService.logLoad(
              format: 'interstitial',
              success: false,
              error: error.message,
            );
            _ad = null;
            if (!done.isCompleted) done.complete();
          },
        ),
      );
      await done.future;
    } catch (error) {
      if (kDebugMode) debugPrint('[ads] interstitial preload: $error');
      _ad = null;
    } finally {
      _loading = false;
    }
  }

  /// Shows a preloaded interstitial when frequency rules allow.
  Future<bool> maybeShow() async {
    if (_showing) return false;
    final now = DateTime.now();
    if (now.difference(_startedAt) < _minSessionAge) return false;
    if (_lastShown != null && now.difference(_lastShown!) < _minGap) {
      return false;
    }
    if (_ad == null) {
      await preload();
    }
    final ad = _ad;
    if (ad == null) return false;

    _showing = true;
    _ad = null;
    final done = Completer<void>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (shown) {
        shown.dispose();
        if (!done.isCompleted) done.complete();
      },
      onAdFailedToShowFullScreenContent: (shown, error) {
        AdsService.logLoad(
          format: 'interstitial-show',
          success: false,
          error: error.message,
        );
        shown.dispose();
        if (!done.isCompleted) done.complete();
      },
      onAdShowedFullScreenContent: (shown) {
        AdsService.logLoad(
          format: 'interstitial-show',
          success: true,
          network: shown.responseInfo?.mediationAdapterClassName,
        );
      },
    );
    try {
      await ad.show();
      _lastShown = DateTime.now();
      await done.future.timeout(
        const Duration(minutes: 2),
        onTimeout: () {},
      );
      return true;
    } catch (error) {
      if (kDebugMode) debugPrint('[ads] interstitial show: $error');
      ad.dispose();
      return false;
    } finally {
      _showing = false;
      unawaited(preload());
    }
  }

  void dispose() {
    _ad?.dispose();
    _ad = null;
  }
}

final interstitialManagerProvider = Provider<InterstitialManager>((ref) {
  final manager = InterstitialManager(ref.watch(adsServiceProvider));
  ref.onDispose(manager.dispose);
  unawaited(manager.preload());
  return manager;
});
