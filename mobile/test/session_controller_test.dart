import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/session/session_state.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/profile/saved_account.dart';
import 'package:find_your_match/core/api/match_api.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_match_api.dart';

void main() {
  test('a saved token loads the profile before home', () async {
    final api = FakeMatchApi()
      ..restoreResult = MeResult(
        userId: 'user-1',
        hasProfile: true,
        account: SavedAccount(person: _person('user-1'), hidden: false),
      );
    final container = ProviderContainer(
      overrides: [
        apiBaseUrlProvider.overrideWithValue('https://example.test/server'),
        matchApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionControllerProvider.notifier).bootstrap();

    final state = container.read(sessionControllerProvider);
    expect(api.restoreCalls, 1);
    expect(state.status, SessionStatus.ready);
    expect(state.uid, 'user-1');
    expect(state.hasProfile, isTrue);
    expect(container.read(savedAccountProvider)?.person.username, 'ada');
  });

  test('a missing profile keeps the user out of home', () async {
    final api = FakeMatchApi()
      ..restoreResult = const MeResult(userId: 'user-2', hasProfile: false);
    final container = ProviderContainer(
      overrides: [
        apiBaseUrlProvider.overrideWithValue('https://example.test/server'),
        matchApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionControllerProvider.notifier).bootstrap();

    final state = container.read(sessionControllerProvider);
    expect(state.hasProfile, isFalse);
    expect(state.status, SessionStatus.ready);
  });

  test('an empty website address does not call the server', () async {
    final api = FakeMatchApi();
    final container = ProviderContainer(
      overrides: [
        apiBaseUrlProvider.overrideWithValue(''),
        splashHoldProvider.overrideWithValue(Duration.zero),
        matchApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionControllerProvider.notifier).bootstrap();

    final state = container.read(sessionControllerProvider);
    expect(api.restoreCalls, 0);
    expect(state.status, SessionStatus.needsSetup);
  });

  test('auth failures surface a message and do not invent a profile', () async {
    final api = FakeMatchApi()
      ..restoreError = const AccountFailure(
        AccountFailureKind.unknown,
        'Sign in again.',
      );
    final container = ProviderContainer(
      overrides: [
        apiBaseUrlProvider.overrideWithValue('https://example.test/server'),
        matchApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionControllerProvider.notifier).bootstrap();

    final state = container.read(sessionControllerProvider);
    expect(state.status, SessionStatus.error);
    expect(state.hasProfile, isFalse);
    expect(state.errorMessage, contains('Sign in again'));
  });
}

Person _person(String id) {
  return Person(
    id: id,
    username: 'ada',
    displayName: 'ada',
    age: 28,
    gender: 'Woman',
    city: 'Lahore',
    bio: 'A short bio for the form.',
    interests: const ['Coffee'],
    preferences: const ['Dating'],
    hue: 12,
    isSample: false,
  );
}
