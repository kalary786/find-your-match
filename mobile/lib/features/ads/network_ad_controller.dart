import 'dart:async';

import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/features/ads/network_ad_settings.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const launchCountKey = 'fym_ad_launches';

abstract class FullScreenAdPlayer {
  Future<void> show(AdSlot slot);
}

class NoopFullScreenPlayer implements FullScreenAdPlayer {
  const NoopFullScreenPlayer();

  @override
  Future<void> show(AdSlot slot) async {}
}

final fullScreenAdPlayerProvider = Provider<FullScreenAdPlayer>(
  (ref) => const NoopFullScreenPlayer(),
);

typedef AdClock = DateTime Function();

final adClockProvider = Provider<AdClock>((ref) => DateTime.now);

class NetworkAdState {
  const NetworkAdState({
    this.settings = NetworkAdSettings.off,
    this.loaded = false,
    this.bannerRoll = 0,
  });

  final NetworkAdSettings settings;
  final bool loaded;
  final int bannerRoll;
}

class NetworkAdController extends Notifier<NetworkAdState> {
  var _loading = false;
  var _showing = false;
  var _launchHandled = false;
  var _launches = 0;
  var _pageCount = 0;
  var _chatCount = 0;
  var _pendingMessages = 0;
  var _roll = 0;
  String? _pendingPath;
  String? _lastPage;
  DateTime? _lastFullScreen;

  @override
  NetworkAdState build() => const NetworkAdState();

  Future<void> load() async {
    if (state.loaded || _loading) return;
    if (ref.read(socialSeedProvider) != null) {
      state = const NetworkAdState(loaded: true);
      return;
    }
    _loading = true;
    try {
      final settings = await ref.read(matchApiProvider).networkAds();
      _launches = await _readLaunches();
      state = NetworkAdState(
        settings: settings,
        loaded: true,
        bannerRoll: ref.read(adClockProvider)().millisecondsSinceEpoch,
      );
    } catch (_) {
      state = const NetworkAdState(loaded: true);
    } finally {
      _loading = false;
    }
    final pending = _pendingMessages;
    _pendingMessages = 0;
    for (var i = 0; i < pending; i++) {
      _countMessage();
    }
    final path = _pendingPath;
    if (path != null) _applyLocation(path);
  }

  void onLocation(String path) {
    _pendingPath = path;
    if (!state.loaded) return;
    _applyLocation(path);
  }

  void onMessageSent() {
    if (!state.loaded) {
      _pendingMessages += 1;
      return;
    }
    _countMessage();
  }

  void _applyLocation(String path) {
    if (!countsAsContentPage(path) || path == _lastPage) return;
    _lastPage = path;
    final settings = state.settings;
    if (!settings.interstitialEnabled) return;
    _pageCount += 1;
    _openLaunchIfNeeded();
    if (dueEvery(_pageCount, settings.pageInterval)) {
      _present(
        chooseSlot(interstitialChoices(settings, inChat: false), _nextRoll()),
      );
    }
  }

  void _openLaunchIfNeeded() {
    if (_launchHandled) return;
    _launchHandled = true;
    final settings = state.settings;
    if (!settings.interstitialEnabled) return;
    _launches += 1;
    unawaited(_writeLaunches(_launches));
    if (!dueOnLaunch(
      count: _launches,
      interval: settings.launchInterval,
      showFirst: settings.showFirstLaunch,
    )) {
      return;
    }
    if (settings.admobAppOpenUnit.isNotEmpty) {
      _present(AdSlot(AdNetwork.admobAppOpen, settings.admobAppOpenUnit));
      return;
    }
    _present(
      chooseSlot(interstitialChoices(settings, inChat: false), _nextRoll()),
    );
  }

  void _countMessage() {
    final settings = state.settings;
    if (!settings.interstitialEnabled) return;
    _chatCount += 1;
    if (!dueEvery(_chatCount, settings.chatInterval)) return;
    _present(
      chooseSlot(interstitialChoices(settings, inChat: true), _nextRoll()),
    );
  }

  void _present(AdSlot? slot) {
    if (slot == null || _showing) return;
    final now = ref.read(adClockProvider)();
    if (!cooledDown(_lastFullScreen, now)) return;
    _showing = true;
    _lastFullScreen = now;
    final player = ref.read(fullScreenAdPlayerProvider);
    unawaited(() async {
      try {
        await player.show(slot);
      } catch (_) {
      } finally {
        _showing = false;
      }
    }());
  }

  int _nextRoll() {
    _roll += 1;
    return state.bannerRoll + _roll;
  }

  Future<int> _readLaunches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(launchCountKey) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _writeLaunches(int count) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(launchCountKey, count);
    } catch (_) {}
  }
}

final networkAdControllerProvider =
    NotifierProvider<NetworkAdController, NetworkAdState>(
      NetworkAdController.new,
    );
