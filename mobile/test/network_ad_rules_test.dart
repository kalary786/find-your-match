import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/features/ads/network_ad_controller.dart';
import 'package:find_your_match/features/ads/network_ad_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_match_api.dart';

void main() {
  test('banner stays off chat unless AdMob in chats is on', () {
    const settings = NetworkAdSettings(
      bannerEnabled: true,
      admobBannerUnit: 'ca-app-pub-3940256099942544/6300978111',
      facebookBanner: '999',
    );
    expect(bannerChoices(settings, inChat: false), hasLength(1));
    expect(bannerChoices(settings, inChat: true), isEmpty);
    expect(
      bannerChoices(
        const NetworkAdSettings(
          bannerEnabled: true,
          admobBannerUnit: 'ca-app-pub-3940256099942544/6300978111',
          admobInChats: true,
        ),
        inChat: true,
      ),
      hasLength(1),
    );
  });

  test('full-screen ads rotate AdMob and Monetag, and chat skips AdMob', () {
    const settings = NetworkAdSettings(
      interstitialEnabled: true,
      admobInterstitialUnit: 'ca-app-pub-3940256099942544/1033173712',
      monetagLink: 'https://example.com/offer',
      facebookInterstitial: '123',
    );
    final outside = interstitialChoices(settings, inChat: false);
    expect(outside.map((slot) => slot.network), [
      AdNetwork.admob,
      AdNetwork.monetag,
    ]);
    expect(chooseSlot(outside, 1)!.network, AdNetwork.monetag);
    expect(
      interstitialChoices(settings, inChat: true).single.network,
      AdNetwork.monetag,
    );
    expect(
      interstitialChoices(
        const NetworkAdSettings(
          interstitialEnabled: true,
          monetagLink: 'javascript:alert(1)',
        ),
        inChat: true,
      ),
      isEmpty,
    );
  });

  test('page, chat, and launch frequencies follow the saved interval', () {
    expect(dueEvery(4, 4), isTrue);
    expect(dueEvery(3, 4), isFalse);
    expect(dueEvery(1, 0), isFalse);
    expect(
      dueOnLaunch(count: 1, interval: 4, showFirst: true),
      isTrue,
    );
    expect(
      dueOnLaunch(count: 1, interval: 4, showFirst: false),
      isFalse,
    );
    expect(dueOnLaunch(count: 4, interval: 4, showFirst: false), isTrue);
    expect(countsAsContentPage('/discover'), isTrue);
    expect(countsAsContentPage('/report/9'), isFalse);
    expect(countsAsContentPage('/settings/delete-account'), isFalse);
    expect(countsAsContentPage('/conversation/4'), isFalse);
    final now = DateTime(2026, 10, 10, 12);
    expect(cooledDown(now, now.add(const Duration(seconds: 44))), isFalse);
    expect(cooledDown(now, now.add(fullScreenCooldown)), isTrue);
  });

  test('a signed-in session shows a full-screen ad on the saved page count', () async {
    final shown = <AdSlot>[];
    var now = DateTime(2026, 10, 10, 12);
    final api = FakeMatchApi()
      ..networkAdResult = const NetworkAdSettings(
        interstitialEnabled: true,
        pageInterval: 2,
        launchInterval: 0,
        showFirstLaunch: false,
        admobInterstitialUnit: 'unit-1',
      );
    final container = ProviderContainer(
      overrides: [
        matchApiProvider.overrideWithValue(api),
        fullScreenAdPlayerProvider.overrideWithValue(_RecordingPlayer(shown)),
        adClockProvider.overrideWithValue(() => now),
      ],
    );
    addTearDown(container.dispose);
    final ads = container.read(networkAdControllerProvider.notifier);
    await ads.load();
    ads.onLocation('/discover');
    ads.onLocation('/search');
    await Future<void>.delayed(Duration.zero);
    expect(shown.map((slot) => slot.id), ['unit-1']);
    now = now.add(const Duration(seconds: 20));
    ads.onLocation('/matches');
    ads.onLocation('/profile');
    await Future<void>.delayed(Duration.zero);
    expect(shown, hasLength(1));
    now = now.add(fullScreenCooldown);
    ads.onLocation('/settings');
    ads.onLocation('/notices');
    await Future<void>.delayed(Duration.zero);
    expect(shown, hasLength(2));
  });
}

class _RecordingPlayer implements FullScreenAdPlayer {
  _RecordingPlayer(this.shown);

  final List<AdSlot> shown;

  @override
  Future<void> show(AdSlot slot) async {
    shown.add(slot);
  }
}
