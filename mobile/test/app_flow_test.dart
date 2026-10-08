import 'package:find_your_match/app.dart';
import 'package:find_your_match/core/api/match_api.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/session/session_state.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/social/social_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_match_api.dart';

void main() {
  testWidgets('an empty website address opens setup', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splashHoldProvider.overrideWithValue(Duration.zero),
          apiBaseUrlProvider.overrideWithValue(''),
        ],
        child: const FindYourMatchApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Add your website address'), findsOneWidget);
    expect(find.text('Connect Firebase to continue'), findsNothing);
  });

  testWidgets('a user without a profile lands on onboarding', (tester) async {
    await _pumpSeeded(
      tester,
      const SessionState.ready(uid: 'user-1', hasProfile: false),
    );

    expect(find.text('Meet. Match. Connect.'), findsOneWidget);
    expect(find.text('Step 1 of 4'), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('email and password are required before the profile form', (
    tester,
  ) async {
    final api = FakeMatchApi();
    await _pumpSeeded(
      tester,
      const SessionState.ready(uid: '', hasProfile: false),
      api: api,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Email'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNull,
    );

    await tester.enterText(find.byType(TextField).at(0), 'ada@example.com');
    await tester.enterText(find.byType(TextField).at(1), 'password1');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNull,
    );

    await tester.ensureVisible(find.byKey(const Key('agree-legal')));
    await tester.tap(find.byKey(const Key('agree-legal')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNotNull,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Step 4 of 4'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Date of birth'), findsOneWidget);
    expect(find.text('Save profile'), findsOneWidget);
  });

  testWidgets('home can open details, chat, filters, and delete', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const mina = Person(
      id: '2',
      username: 'mina',
      displayName: 'Mina',
      age: 27,
      gender: 'Woman',
      city: 'Kochi',
      bio: 'Weekend walks and home cooking.',
      interests: ['Cooking', 'Travel'],
      preferences: ['Dating'],
      hue: 12,
      isSample: false,
    );
    const leila = Person(
      id: '3',
      username: 'leila',
      displayName: 'Leila',
      age: 26,
      gender: 'Woman',
      city: 'Mumbai',
      bio: 'Morning runs and neighborhood coffee.',
      interests: ['Fitness', 'Coffee'],
      preferences: ['Dating'],
      hue: 28,
      isSample: false,
    );

    await _pumpSeeded(
      tester,
      const SessionState.ready(uid: 'user-1', hasProfile: true),
      api: FakeMatchApi(),
      social: SocialState(
        discover: [mina],
        matches: [leila],
        chats: [ChatThread(person: leila, lastMessage: 'See you Saturday')],
        messages: {
          '3': [
            ChatMessage(
              id: 'm1',
              fromMe: false,
              text: 'See you Saturday',
              timeLabel: 'Yesterday',
            ),
          ],
        },
        loaded: true,
      ),
    );

    await tester.tap(find.byKey(const Key('discover-card')));
    await tester.pumpAndSettle();
    expect(find.text('Block'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Unmatch'), findsNothing);

    await tester.tap(find.byKey(const Key('report-user')));
    await tester.pumpAndSettle();
    expect(find.text('Submit report'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Search'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Filters'));
    await tester.pumpAndSettle();
    expect(find.text('Search filters'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Chats'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leila'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('chat-input')),
      'Hello from the preview',
    );
    await tester.tap(find.byTooltip('Send'));
    await tester.pumpAndSettle();
    expect(find.text('Hello from the preview'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();
    expect(find.text('Show online status'), findsOneWidget);
    await tester.tap(find.byKey(const Key('blocked-users-tile')));
    await tester.pumpAndSettle();
    expect(find.text('No blocked people'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('delete-account-tile')));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.tap(find.byKey(const Key('confirm-delete')));
    await tester.pumpAndSettle();
    expect(find.text('Step 1 of 4'), findsOneWidget);
  });

  testWidgets('a match can be removed and the password can be changed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const leila = Person(
      id: '3',
      username: 'leila',
      displayName: 'Leila',
      age: 26,
      gender: 'Woman',
      city: 'Mumbai',
      bio: 'Morning runs and neighborhood coffee.',
      interests: ['Fitness', 'Coffee'],
      preferences: ['Dating'],
      hue: 28,
      isSample: false,
    );
    final api = FakeMatchApi();
    await _pumpSeeded(
      tester,
      const SessionState.ready(uid: 'user-1', hasProfile: true),
      api: api,
      social: SocialState(
        matches: [leila],
        chats: [ChatThread(person: leila, lastMessage: 'See you Saturday')],
        loaded: true,
      ),
    );

    await tester.tap(find.text('Matches'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Leila'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('unmatch-user')));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Unmatch'));
    await tester.pumpAndSettle();

    expect(find.text('Match removed.'), findsOneWidget);
    expect(find.text('Leila'), findsNothing);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('settings-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('change-password-tile')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('current-password')),
      'old-pass',
    );
    await tester.enterText(
      find.byKey(const Key('new-password')),
      'new-password',
    );
    await tester.enterText(
      find.byKey(const Key('confirm-password')),
      'new-password',
    );
    await tester.pump();
    await tester.tap(find.byKey(const Key('save-password')));
    await tester.pumpAndSettle();

    expect(api.changedPassword, 'new-password');
    expect(find.text('Current password'), findsNothing);
  });
}

Future<void> _pumpSeeded(
  WidgetTester tester,
  SessionState session, {
  MatchApi? api,
  SocialState? social,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionSeedProvider.overrideWithValue(session),
        if (api != null) matchApiProvider.overrideWithValue(api),
        if (social != null) socialSeedProvider.overrideWithValue(social),
      ],
      child: const FindYourMatchApp(bootstrapOnStart: false),
    ),
  );
  await tester.pumpAndSettle();
}
