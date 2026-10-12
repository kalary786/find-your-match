import 'dart:async';

import 'package:find_your_match/features/ads/ad_config.dart';
import 'package:find_your_match/features/ads/ads_service.dart';
import 'package:find_your_match/features/ads/placement_ad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Adaptive AdMob banner (Meta via mediation). Falls back to [PlacementAd].
class SmartBannerAd extends ConsumerStatefulWidget {
  const SmartBannerAd({required this.placement, super.key});

  final String placement;

  @override
  ConsumerState<SmartBannerAd> createState() => _SmartBannerAdState();
}

class _SmartBannerAdState extends ConsumerState<SmartBannerAd> {
  BannerAd? _ad;
  var _ready = false;
  var _useHosted = false;
  var _attempt = 0;
  Timer? _retry;

  bool get _inWidgetTest =>
      WidgetsBinding.instance.runtimeType.toString().contains(
        'TestWidgetsFlutterBinding',
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    try {
      await ref.read(adsServiceProvider).ready;
    } catch (_) {}
    if (!mounted) return;
    await _load();
  }

  Future<void> _load() async {
    if (!mounted || _useHosted) return;
    final width = MediaQuery.sizeOf(context).width.truncate();
    AdSize? size;
    try {
      // Anchored adaptive (current orientation). Prefer the non-deprecated API.
      size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
    } catch (_) {
      size = AdSize.banner;
    }
    size ??= AdSize.banner;
    if (!mounted) return;

    await _ad?.dispose();
    _ad = null;
    _ready = false;

    final ad = BannerAd(
      adUnitId: AdConfig.bannerId,
      size: size,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (loaded) {
          AdsService.logLoad(
            format: 'banner',
            success: true,
            network: loaded.responseInfo?.mediationAdapterClassName,
          );
          if (!mounted) {
            loaded.dispose();
            return;
          }
          setState(() {
            _ready = true;
            _useHosted = false;
          });
        },
        onAdFailedToLoad: (failed, error) {
          AdsService.logLoad(
            format: 'banner',
            success: false,
            error: error.message,
          );
          failed.dispose();
          if (!mounted) return;
          setState(() {
            _ad = null;
            _ready = false;
          });
          _onFailed();
        },
      ),
    );
    _ad = ad;
    try {
      await ad.load();
    } catch (error) {
      AdsService.logLoad(
        format: 'banner',
        success: false,
        error: '$error',
      );
      await ad.dispose();
      if (mounted) {
        setState(() => _ad = null);
        _onFailed();
      }
    }
  }

  void _onFailed() {
    _attempt += 1;
    if (_attempt == 1) {
      final delay = _inWidgetTest
          ? Duration.zero
          : const Duration(seconds: 30);
      _retry?.cancel();
      _retry = Timer(delay, () {
        if (mounted) _load();
      });
      return;
    }
    if (mounted) setState(() => _useHosted = true);
  }

  @override
  void dispose() {
    _retry?.cancel();
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_useHosted) {
      return PlacementAd(placement: widget.placement);
    }
    final ad = _ad;
    if (!_ready || ad == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: theme.colorScheme.surfaceContainerLowest,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
              child: Text(
                'Ad',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            SizedBox(
              width: ad.size.width.toDouble(),
              height: ad.size.height.toDouble(),
              child: AdWidget(ad: ad),
            ),
          ],
        ),
      ),
    );
  }
}
