import 'dart:async';

import 'package:find_your_match/features/ads/external_link.dart';
import 'package:find_your_match/features/ads/network_ad_controller.dart';
import 'package:find_your_match/features/ads/network_ad_settings.dart';
import 'package:flutter/widgets.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void>? _mobileAdsReady;

Future<void> _prepareMobileAds() async {
  final pending = _mobileAdsReady;
  if (pending != null) {
    try {
      await pending;
    } catch (_) {}
    return;
  }
  final next = MobileAds.instance.initialize().then((_) {});
  _mobileAdsReady = next;
  try {
    await next;
  } catch (_) {
    if (identical(_mobileAdsReady, next)) _mobileAdsReady = null;
  }
}

class LiveFullScreenAdPlayer implements FullScreenAdPlayer {
  const LiveFullScreenAdPlayer();

  @override
  Future<void> show(AdSlot slot) async {
    try {
      switch (slot.network) {
        case AdNetwork.admob:
          await _showInterstitial(slot.id);
        case AdNetwork.admobAppOpen:
          await _showAppOpen(slot.id);
        case AdNetwork.monetag:
          final uri = externalHttpUri(slot.id);
          if (uri == null) return;
          await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
      }
    } catch (_) {}
  }

  Future<void> _showInterstitial(String unitId) {
    final done = Completer<void>();
    _prepareMobileAds().then((_) {
      InterstitialAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                if (!done.isCompleted) done.complete();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                if (!done.isCompleted) done.complete();
              },
            );
            ad.show();
          },
          onAdFailedToLoad: (error) {
            if (!done.isCompleted) done.complete();
          },
        ),
      );
    }).catchError((_) {
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }

  Future<void> _showAppOpen(String unitId) {
    final done = Completer<void>();
    _prepareMobileAds().then((_) {
      AppOpenAd.load(
        adUnitId: unitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                if (!done.isCompleted) done.complete();
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                if (!done.isCompleted) done.complete();
              },
            );
            ad.show();
          },
          onAdFailedToLoad: (error) {
            if (!done.isCompleted) done.complete();
          },
        ),
      );
    }).catchError((_) {
      if (!done.isCompleted) done.complete();
    });
    return done.future;
  }
}

Widget liveBannerView({required String unitId, required bool large}) {
  return _LiveBanner(key: ValueKey('$unitId:$large'), unitId: unitId, large: large);
}

class _LiveBanner extends StatefulWidget {
  const _LiveBanner({
    required this.unitId,
    required this.large,
    super.key,
  });

  final String unitId;
  final bool large;

  @override
  State<_LiveBanner> createState() => _LiveBannerState();
}

class _LiveBannerState extends State<_LiveBanner> {
  BannerAd? _ad;
  var _ready = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      await _prepareMobileAds();
    } catch (_) {
      return;
    }
    if (!mounted) return;
    final ad = BannerAd(
      adUnitId: widget.unitId,
      size: widget.large ? AdSize.largeBanner : AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _ready = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          if (mounted) setState(() => _ad = null);
        },
      ),
    );
    _ad = ad;
    try {
      await ad.load();
    } catch (_) {
      ad.dispose();
      if (mounted) setState(() => _ad = null);
    }
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_ready || ad == null) return const SizedBox.shrink();
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
