import 'package:find_your_match/core/session/auth_gateway.dart';
import 'package:find_your_match/core/session/profile_gateway.dart';
import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/core/session/session_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('anonymous sign-in runs before the profile check', () async {
    final auth = _FakeAuth('user-1');
    final profiles = _FakeProfiles(completed: true);
    final container = ProviderContainer(
      overrides: [
        firebaseConfiguredProvider.overrideWithValue(true),
        authGatewayProvider.overrideWithValue(auth),
        profileGatewayProvider.overrideWithValue(profiles),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionControllerProvider.notifier).bootstrap();

    final state = container.read(sessionControllerProvider);
    expect(auth.calls, 1);
    expect(profiles.seenUid, 'user-1');
    expect(state.status, SessionStatus.ready);
    expect(state.uid, 'user-1');
    expect(state.hasProfile, isTrue);
  });

  test('a missing profile keeps the user out of home', () async {
    final container = ProviderContainer(
      overrides: [
        firebaseConfiguredProvider.overrideWithValue(true),
        authGatewayProvider.overrideWithValue(_FakeAuth('user-2')),
        profileGatewayProvider.overrideWithValue(
          _FakeProfiles(completed: false),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionControllerProvider.notifier).bootstrap();

    final state = container.read(sessionControllerProvider);
    expect(state.hasProfile, isFalse);
    expect(state.status, SessionStatus.ready);
  });

  test('Firebase stays untouched when the project is not configured', () async {
    final auth = _FakeAuth('should-not-run');
    final container = ProviderContainer(
      overrides: [
        firebaseConfiguredProvider.overrideWithValue(false),
        splashHoldProvider.overrideWithValue(Duration.zero),
        authGatewayProvider.overrideWithValue(auth),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionControllerProvider.notifier).bootstrap();

    final state = container.read(sessionControllerProvider);
    expect(auth.calls, 0);
    expect(state.status, SessionStatus.ready);
    expect(state.hasProfile, isFalse);
    expect(state.uid, 'local-preview');
  });

  test('auth failures surface a message and do not invent a profile', () async {
    final container = ProviderContainer(
      overrides: [
        firebaseConfiguredProvider.overrideWithValue(true),
        authGatewayProvider.overrideWithValue(
          _FakeAuth.error(const AuthFailure('Anonymous sign-in did not return a user.')),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(sessionControllerProvider.notifier).bootstrap();

    final state = container.read(sessionControllerProvider);
    expect(state.status, SessionStatus.error);
    expect(state.hasProfile, isFalse);
    expect(state.errorMessage, contains('Anonymous sign-in'));
  });
}

class _FakeAuth implements AuthGateway {
  _FakeAuth(this.uid) : failure = null;

  _FakeAuth.error(this.failure) : uid = '';

  final String uid;
  final AuthFailure? failure;
  int calls = 0;

  @override
  Future<String> ensureAnonymousUser() async {
    calls += 1;
    final error = failure;
    if (error != null) throw error;
    return uid;
  }
}

class _FakeProfiles implements ProfileGateway {
  _FakeProfiles({required this.completed});

  final bool completed;
  String? seenUid;

  @override
  Future<bool> hasCompletedProfile(String uid) async {
    seenUid = uid;
    return completed;
  }
}
