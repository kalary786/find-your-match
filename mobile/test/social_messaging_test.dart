import 'dart:async';

import 'package:find_your_match/core/api/match_api.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/session/session_state.dart';
import 'package:find_your_match/features/chat/chat_room_page.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_match_api.dart';

void main() {
  test('chat polling runs only while the conversation is active', () {
    expect(
      shouldPollChat(
        foreground: true,
        routeCurrent: true,
        matched: true,
        blocked: false,
      ),
      isTrue,
    );
    expect(
      shouldPollChat(
        foreground: false,
        routeCurrent: true,
        matched: true,
        blocked: false,
      ),
      isFalse,
    );
    expect(
      shouldPollChat(
        foreground: true,
        routeCurrent: false,
        matched: true,
        blocked: false,
      ),
      isFalse,
    );
    expect(
      shouldPollChat(
        foreground: true,
        routeCurrent: true,
        matched: false,
        blocked: false,
      ),
      isFalse,
    );
    expect(
      shouldPollChat(
        foreground: true,
        routeCurrent: true,
        matched: true,
        blocked: true,
      ),
      isFalse,
    );
  });

  test('older messages stay in order and a repeated id is not duplicated', () {
    final merged = mergeChatMessages(
      [
        const ChatMessage(id: '3', fromMe: true, text: 'new', timeLabel: '2'),
        const ChatMessage(id: 'local', fromMe: true, text: 'pending', timeLabel: '3'),
      ],
      const [
        ChatMessage(id: '1', fromMe: false, text: 'old', timeLabel: '1'),
        ChatMessage(id: '3', fromMe: true, text: 'new', timeLabel: '2'),
      ],
    );
    expect(merged.map((message) => message.id), ['1', '3', 'local']);
  });

  test('a message refresh does not overlap itself', () async {
    final gate = Completer<void>();
    final api = FakeMatchApi()..messageGate = () => gate.future;
    final container = ProviderContainer(
      overrides: [matchApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);

    final first = container
        .read(socialControllerProvider.notifier)
        .refreshMessages('2');
    await Future<void>.delayed(Duration.zero);
    final second = container
        .read(socialControllerProvider.notifier)
        .refreshMessages('2');
    await Future<void>.delayed(Duration.zero);
    expect(api.messageCalls, 1);
    gate.complete();
    await first;
    await second;
    expect(api.messageCalls, 1);
  });

  test('an expired session signs out and a closed chat drops the match', () async {
    final expired = FakeMatchApi()
      ..messageError = const AccountFailure(
        AccountFailureKind.unknown,
        'Sign in again.',
      );
    final expiredContainer = ProviderContainer(
      overrides: [matchApiProvider.overrideWithValue(expired)],
    );
    addTearDown(expiredContainer.dispose);
    await expiredContainer
        .read(socialControllerProvider.notifier)
        .refreshMessages('2');
    expect(expiredContainer.read(sessionControllerProvider).uid, isEmpty);
    expect(
      expiredContainer.read(sessionControllerProvider).status,
      SessionStatus.ready,
    );

    final closed = FakeMatchApi()
      ..messageError = const AccountFailure(
        AccountFailureKind.unavailable,
        'That profile is not available.',
      );
    final container = ProviderContainer(
      overrides: [
        matchApiProvider.overrideWithValue(closed),
        socialControllerProvider.overrideWith(_MatchedSocial.new),
      ],
    );
    addTearDown(container.dispose);
    expect(container.read(socialControllerProvider).isMatched('2'), isTrue);
    await container.read(socialControllerProvider.notifier).refreshMessages('2');
    expect(container.read(socialControllerProvider).isMatched('2'), isFalse);
    expect(container.read(socialControllerProvider).chats, isEmpty);
  });

  test('block hides the person and unblock does not invent a match', () async {
    final api = FakeMatchApi()
      ..blockedResult = [_person]
      ..matchesResult = const []
      ..chatsResult = const []
      ..discoverResult = const [];
    final container = ProviderContainer(
      overrides: [
        matchApiProvider.overrideWithValue(api),
        socialSeedProvider.overrideWithValue(
          SocialState(
            discover: [_person],
            searchResults: [_person],
            matches: [_person],
            chats: [ChatThread(person: _person, lastMessage: 'Hi')],
            messages: {
              '2': [
                ChatMessage(
                  id: '1',
                  fromMe: true,
                  text: 'Hi',
                  timeLabel: 'Now',
                ),
              ],
            },
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(socialControllerProvider.notifier).block('2');
    final blocked = container.read(socialControllerProvider);
    expect(blocked.discover, isEmpty);
    expect(blocked.searchResults, isEmpty);
    expect(blocked.matches, isEmpty);
    expect(blocked.chats, isEmpty);
    expect(blocked.messages['2'], isNull);
    expect(blocked.blocked.single.id, '2');

    await container.read(socialControllerProvider.notifier).unblock('2');
    final restored = container.read(socialControllerProvider);
    expect(restored.blocked, isEmpty);
    expect(restored.matches, isEmpty);
    expect(restored.chats, isEmpty);
    expect(api.unblockCalls, 1);
  });

  test('unblock shows a match that still exists on the server', () async {
    final api = FakeMatchApi()
      ..matchesResult = [_person]
      ..chatsResult = [ChatThread(person: _person, lastMessage: 'Hi')];
    final container = ProviderContainer(
      overrides: [
        matchApiProvider.overrideWithValue(api),
        socialSeedProvider.overrideWithValue(
          SocialState(blocked: [_person], matches: [_person]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(socialControllerProvider.notifier).unblock('2');
    expect(container.read(socialControllerProvider).matches.single.id, '2');
    expect(container.read(socialControllerProvider).chats, hasLength(1));
  });

  test('unmatch of a blocked person does not put them back in Discover', () async {
    final container = ProviderContainer(
      overrides: [
        matchApiProvider.overrideWithValue(FakeMatchApi()),
        socialSeedProvider.overrideWithValue(
          SocialState(matches: [_person], blocked: [_person]),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(socialControllerProvider.notifier).unmatch('2');
    final state = container.read(socialControllerProvider);
    expect(state.matches, isEmpty);
    expect(state.discover, isEmpty);
    expect(state.blocked.single.id, '2');
  });

  test('a repeated like keeps a single match from the server', () async {
    final api = FakeMatchApi()
      ..likeMatched = true
      ..matchesResult = [_person]
      ..chatsResult = [ChatThread(person: _person, lastMessage: '')];
    final container = ProviderContainer(
      overrides: [
        matchApiProvider.overrideWithValue(api),
        socialSeedProvider.overrideWithValue(SocialState(discover: [_person])),
      ],
    );
    addTearDown(container.dispose);
    final social = container.read(socialControllerProvider.notifier);
    expect(await social.like('2'), isTrue);
    expect(await social.like('2'), isTrue);
    expect(api.likeCalls, 2);
    expect(container.read(socialControllerProvider).discover, isEmpty);
    expect(container.read(socialControllerProvider).matches, [_person]);
  });

  test('older pages load behind the newest messages', () async {
    final api = FakeMatchApi()
      ..messageResult = [
        const ChatMessage(id: '3', fromMe: true, text: 'new', timeLabel: '3'),
      ]
      ..olderMessages = {
        '3': const [
          ChatMessage(id: '1', fromMe: false, text: 'old', timeLabel: '1'),
        ],
      };
    final container = ProviderContainer(
      overrides: [
        matchApiProvider.overrideWithValue(api),
        socialControllerProvider.overrideWith(_MatchedSocial.new),
      ],
    );
    addTearDown(container.dispose);
    final social = container.read(socialControllerProvider.notifier);
    await social.refreshMessages('2');
    await social.loadOlderMessages('2');
    expect(
      container
          .read(socialControllerProvider)
          .messages['2']!
          .map((message) => message.id),
      ['1', '3'],
    );
    expect(api.lastBefore, '3');
  });

  testWidgets('a failed send keeps the text for a retry', (tester) async {
    final api = FakeMatchApi()
      ..sendError = const AccountFailure(
        AccountFailureKind.offline,
        'You appear to be offline. Nothing was saved. Connect and try again.',
      );
    await _pumpChat(tester, api);
    await tester.enterText(find.byKey(const Key('chat-input')), 'Hello');
    await tester.ensureVisible(find.byIcon(Icons.send));
    await tester.tap(find.byIcon(Icons.send));
    await tester.pumpAndSettle();
    expect(find.textContaining('offline'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byKey(const Key('chat-input'))).controller?.text,
      'Hello',
    );
  });

  testWidgets('a second tap does not send another message', (tester) async {
    final gate = Completer<void>();
    final busy = FakeMatchApi()..sendGate = () => gate.future;
    await _pumpChat(tester, busy);
    await tester.enterText(find.byKey(const Key('chat-input')), 'Hello again');
    await tester.ensureVisible(find.byIcon(Icons.send));
    await tester.tap(find.byIcon(Icons.send));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('chat-input')), 'Second');
    await tester.tap(find.byIcon(Icons.send), warnIfMissed: false);
    await tester.pump();
    expect(busy.sendCalls, 1);
    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('the composer stops at 1000 characters', (tester) async {
    await _pumpChat(tester, FakeMatchApi());
    await tester.enterText(find.byKey(const Key('chat-input')), 'a' * 1001);
    expect(
      tester.widget<TextField>(find.byKey(const Key('chat-input'))).controller?.text.length,
      1000,
    );
  });

  testWidgets('polling pauses while the app is backgrounded', (tester) async {
    var leftForeground = false;
    addTearDown(() {
      if (!leftForeground) return;
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });
    final api = FakeMatchApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchApiProvider.overrideWithValue(api),
          socialControllerProvider.overrideWith(_MatchedSocial.new),
        ],
        child: const MaterialApp(home: ChatRoomPage(userId: '2')),
      ),
    );
    await tester.pump();
    expect(api.messageCalls, 1);

    await tester.pump(const Duration(seconds: 4));
    expect(api.messageCalls, 2);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    leftForeground = true;
    await tester.pump(const Duration(seconds: 4));
    expect(api.messageCalls, 2);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    leftForeground = false;
    await tester.pump();
    expect(api.messageCalls, 3);
  });

  testWidgets('a blocked match cannot keep typing in the open chat', (tester) async {
    await _pumpChat(
      tester,
      FakeMatchApi(),
      social: SocialState(matches: [_person], blocked: [_person]),
    );
    expect(find.byKey(const Key('chat-input')), findsNothing);
    expect(find.textContaining('closes when someone is blocked'), findsOneWidget);
  });
}

Future<void> _pumpChat(
  WidgetTester tester,
  FakeMatchApi api, {
  SocialState? social,
}) {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchApiProvider.overrideWithValue(api),
        socialSeedProvider.overrideWithValue(
          social ??
              SocialState(
                matches: [_person],
                chats: [ChatThread(person: _person, lastMessage: '')],
              ),
        ),
      ],
      child: const MaterialApp(home: ChatRoomPage(userId: '2')),
    ),
  );
}

class _MatchedSocial extends SocialController {
  @override
  SocialState build() {
    return SocialState(
      matches: [_person],
      chats: [ChatThread(person: _person, lastMessage: 'Hi')],
      messages: {
        '2': const [
          ChatMessage(id: '3', fromMe: true, text: 'Hi', timeLabel: 'Now'),
        ],
      },
    );
  }
}

const _person = Person(
  id: '2',
  username: 'mina',
  displayName: 'Mina',
  age: 27,
  gender: 'Woman',
  city: 'Kochi',
  bio: 'Weekend walks.',
  interests: ['Cooking'],
  preferences: ['Dating'],
  hue: 12,
  isSample: false,
);
