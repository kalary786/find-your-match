import 'dart:io';

import 'package:find_your_match/core/api/match_api.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/features/ads/external_link.dart';
import 'package:find_your_match/features/ads/placement_ad.dart';
import 'package:find_your_match/features/notices/notices_page.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_match_api.dart';

void main() {
  test('only full http and https links can leave the app', () {
    expect(externalHttpUri('https://example.com/offer'), isNotNull);
    expect(externalHttpUri('http://example.com'), isNotNull);
    expect(externalHttpUri('javascript:alert(1)'), isNull);
    expect(externalHttpUri('intent://scan'), isNull);
    expect(externalHttpUri('not a url'), isNull);
    expect(externalHttpUri(''), isNull);
  });

  test('a notice stays unread until that notice is opened', () async {
    final api = FakeMatchApi()
      ..noticeResult = const [
        AppNotice(
          id: '4',
          title: 'Hello',
          body: 'A note for you',
          linkUrl: 'https://example.com',
          timeLabel: 'Now',
          read: false,
        ),
        AppNotice(
          id: '5',
          title: 'Other',
          body: 'Second note',
          linkUrl: '',
          timeLabel: 'Later',
          read: false,
        ),
      ];
    final container = ProviderContainer(
      overrides: [matchApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    final notices = container.read(noticeControllerProvider.notifier);
    await notices.refresh();
    expect(api.readIds, isEmpty);
    expect(container.read(noticeControllerProvider).unread, 2);
    await notices.markRead('4');
    expect(api.readIds, ['4']);
    expect(container.read(noticeControllerProvider).unread, 1);
    await notices.markRead('4');
    expect(api.readIds, ['4']);
  });

  testWidgets('a missing ad image is not shown', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          socialSeedProvider.overrideWithValue(
            const SocialState(
              ads: {
                'discover': HostedAd(
                  id: '1',
                  title: 'Cafe',
                  imageUrl: '',
                  linkUrl: 'https://example.com',
                  placement: 'discover',
                ),
              },
            ),
          ),
        ],
        child: const MaterialApp(
          home: Scaffold(body: PlacementAd(placement: 'discover')),
        ),
      ),
    );
    expect(find.text('Cafe'), findsNothing);
    expect(find.byType(InkWell), findsNothing);
  });

  test('custom image ads stay off chat, report, and delete', () {
    final adWidget = File('lib/features/ads/placement_ad.dart').readAsStringSync();
    expect(adWidget, contains('externalHttpUri'));
    expect(adWidget, contains('cacheWidth'));
    expect(
      File('lib/features/ads/external_link.dart').readAsStringSync(),
      contains('LaunchMode.externalApplication'),
    );
    expect(File('pubspec.yaml').readAsStringSync(), contains('google_mobile_ads'));
    for (final path in [
      'lib/features/chat/chat_room_page.dart',
      'lib/features/chat/chats_page.dart',
      'lib/features/safety/report_user_page.dart',
      'lib/features/safety/delete_account_page.dart',
    ]) {
      expect(File(path).readAsStringSync(), isNot(contains('PlacementAd')));
    }
    for (final path in [
      'lib/features/safety/report_user_page.dart',
      'lib/features/safety/delete_account_page.dart',
    ]) {
      expect(File(path).readAsStringSync(), isNot(contains('NetworkBanner')));
    }
    for (final path in [
      'lib/features/discover/discover_page.dart',
      'lib/features/search/search_page.dart',
      'lib/features/matches/matches_page.dart',
    ]) {
      expect(File(path).readAsStringSync(), contains('PlacementAd'));
    }
  });

  test('admin actions stay authorized and destructive steps ask first', () {
    final root = Directory('../server/admin').existsSync()
        ? '../server'
        : 'server';
    for (final name in [
      'users.php',
      'chats.php',
      'chat.php',
      'reports.php',
      'ads.php',
      'network_ads.php',
      'notices.php',
    ]) {
      final source = File('$root/admin/$name').readAsStringSync();
      expect(source, contains('require_admin()'), reason: name);
      expect(source, contains('csrf_ok()'), reason: name);
    }
    final users = File('$root/admin/users.php').readAsStringSync();
    expect(users, contains('Block this user? They will be signed out.'));
    expect(users, contains('Delete this user and their chats?'));
    expect(users, contains('delete_user_account'));
    expect(users, contains("status_html"));
    final reports = File('$root/admin/reports.php').readAsStringSync();
    expect(reports, contains('SELECT reported_id FROM reports'));
    expect(reports, isNot(contains("name=\"user_id\"")));
    expect(reports, contains('Delete this user?'));
    final notices = File('$root/admin/notices.php').readAsStringSync();
    expect(notices, contains('Remove this notice?'));
    expect(notices, contains('optional_link'));
    final networkAds = File('$root/admin/network_ads.php').readAsStringSync();
    expect(networkAds, contains('banner_enabled'));
    expect(networkAds, contains('interstitial_enabled'));
    expect(networkAds, contains('monetag_link'));
    expect(networkAds, contains('Show every 4 pages'));
    expect(networkAds, contains('Show every 20 messages sent'));
    expect(networkAds, contains('Save network ads'));
    final bootstrap = File('$root/lib/bootstrap.php').readAsStringSync();
    expect(bootstrap, contains('function network_ad_from_post'));
    expect(bootstrap, contains('optional_link((string) (\$post[\'monetag_link\']'));
    expect(bootstrap, contains('admob_in_chats'));
    final api = File('$root/api/index.php').readAsStringSync();
    expect(api, contains("'networkAds' => list_network_ads()"));
    expect(api, contains('function list_network_ads'));
    final ads = File('$root/admin/ads.php').readAsStringSync();
    expect(ads, contains('optional_link'));
    expect(ads, contains('store_image'));
    expect(ads, contains('rel="noopener noreferrer"'));
    expect(ads, contains('Remove this ad?'));
    final chats = File('$root/admin/chats.php').readAsStringSync();
    expect(chats, contains('delete_conversation'));
    expect(chats, contains('Delete this chat and its messages?'));
    final listAds = api.substring(api.indexOf('function list_ads'));
    expect(listAds, contains('active = 1'));
    expect(listAds, contains('AD_PLACEMENTS'));
    expect(bootstrap, contains('function delete_conversation'));
    expect(bootstrap, contains('DELETE FROM matches'));
    expect(bootstrap, contains('DELETE FROM swipes'));
    expect(bootstrap, contains('parse_url'));
    expect(bootstrap, isNot(contains('error_log')));
    final login = File('$root/admin/index.php').readAsStringSync();
    expect(login, contains('password_verify'));
    expect(login, contains('rate_limit_blocked(\'admin-login\''));
    expect(login, isNot(contains('error_log')));
    expect(notices, contains('That action is not available.'));
  });
}
