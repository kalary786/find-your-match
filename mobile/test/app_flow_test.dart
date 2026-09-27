import 'package:find_your_match/app.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/session/session_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('an unconfigured project opens onboarding', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          splashHoldProvider.overrideWithValue(Duration.zero),
        ],
        child: const FindYourMatchApp(),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Step 1 of 4'), findsOneWidget);
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

  testWidgets('account recovery must be acknowledged before the profile form', (
    tester,
  ) async {
    await _pumpSeeded(
      tester,
      const SessionState.ready(uid: 'user-1', hasProfile: false),
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.textContaining('cannot be recovered'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'))
          .onPressed,
      isNull,
    );

    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
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

  testWidgets('sample home can open details, chat, filters, and delete', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpSeeded(
      tester,
      const SessionState.ready(uid: 'user-1', hasProfile: true),
    );

    await tester.tap(find.byKey(const Key('discover-card')));
    await tester.pumpAndSettle();
    expect(find.text('Block'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);

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
    await tester.pump();
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
}

Future<void> _pumpSeeded(WidgetTester tester, SessionState session) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sessionSeedProvider.overrideWithValue(session),
      ],
      child: const FindYourMatchApp(bootstrapOnStart: false),
    ),
  );
  await tester.pumpAndSettle();
}
