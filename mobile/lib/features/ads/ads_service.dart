import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Initializes UMP consent + Mobile Ads once. Safe to call multiple times.
class AdsService {
  AdsService();

  Completer<void>? _ready;
  var _started = false;

  /// Completer after consent gathering and [MobileAds.instance.initialize].
  Future<void> get ready => _ready?.future ?? Future.value();

  Future<void> start() {
    if (_ready != null) return _ready!.future;
    _ready = Completer<void>();
    _run().whenComplete(() {
      if (!(_ready?.isCompleted ?? true)) {
        _ready!.complete();
      }
    });
    return _ready!.future;
  }

  Future<void> _run() async {
    if (_started) return;
    _started = true;
    try {
      await _gatherConsent();
      await MobileAds.instance.initialize();
      if (kDebugMode) {
        debugPrint('[ads] MobileAds initialized');
      }
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('[ads] init failed: $error\n$stack');
      }
    }
  }

  Future<void> _gatherConsent() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((formError) {
            if (kDebugMode && formError != null) {
              debugPrint('[ads] consent form: ${formError.message}');
            }
          });
        } catch (error) {
          if (kDebugMode) debugPrint('[ads] consent show failed: $error');
        } finally {
          if (!done.isCompleted) done.complete();
        }
      },
      (error) {
        if (kDebugMode) {
          debugPrint('[ads] consent update failed: ${error.message}');
        }
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {},
    );
  }

  Future<bool> privacyOptionsRequired() async {
    try {
      final status =
          await ConsentInformation.instance.getPrivacyOptionsRequirementStatus();
      return status == PrivacyOptionsRequirementStatus.required;
    } catch (_) {
      return false;
    }
  }

  Future<void> showPrivacyOptions() async {
    await ConsentForm.showPrivacyOptionsForm((formError) {
      if (kDebugMode && formError != null) {
        debugPrint('[ads] privacy options: ${formError.message}');
      }
    });
  }
}

final adsServiceProvider = Provider<AdsService>((ref) => AdsService());
