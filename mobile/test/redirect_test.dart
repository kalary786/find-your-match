import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/routing/session_redirect.dart';
import 'package:find_your_match/core/session/session_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const readyWithoutProfile = SessionState.ready(
    uid: 'user-1',
    hasProfile: false,
  );
  const readyWithProfile = SessionState.ready(
    uid: 'user-1',
    hasProfile: true,
  );

  test('loading stays on the splash route', () {
    expect(
      redirectForSession(const SessionState.loading(), AppRoutes.discover),
      AppRoutes.splash,
    );
    expect(
      redirectForSession(const SessionState.loading(), AppRoutes.splash),
      isNull,
    );
  });

  test('a missing website address opens setup', () {
    expect(
      redirectForSession(const SessionState.needsSetup(), AppRoutes.splash),
      AppRoutes.setup,
    );
  });

  test('legal pages stay open while a profile is still missing', () {
    expect(
      redirectForSession(readyWithoutProfile, AppRoutes.terms),
      isNull,
    );
  });

  test('a signed-in user without a profile opens onboarding', () {
    expect(
      redirectForSession(readyWithoutProfile, AppRoutes.discover),
      AppRoutes.onboarding,
    );
    expect(
      redirectForSession(readyWithoutProfile, AppRoutes.account),
      isNull,
    );
  });

  test('a completed profile leaves onboarding for Discover', () {
    expect(
      redirectForSession(readyWithProfile, AppRoutes.account),
      AppRoutes.discover,
    );
    expect(
      redirectForSession(readyWithProfile, AppRoutes.discover),
      isNull,
    );
  });

  test('session errors open the error screen', () {
    expect(
      redirectForSession(
        const SessionState.failed('offline'),
        AppRoutes.splash,
      ),
      AppRoutes.error,
    );
  });
}
