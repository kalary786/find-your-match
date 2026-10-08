import 'package:find_your_match/core/routing/app_routes.dart';
import 'package:find_your_match/core/session/session_state.dart';

/// Chooses the next location from the session. Pure so tests can cover it
/// without a server.
String? redirectForSession(SessionState session, String location) {
  switch (session.status) {
    case SessionStatus.loading:
      return location == AppRoutes.splash ? null : AppRoutes.splash;
    case SessionStatus.needsSetup:
      return location == AppRoutes.setup ? null : AppRoutes.setup;
    case SessionStatus.error:
      return location == AppRoutes.error ? null : AppRoutes.error;
    case SessionStatus.ready:
      final onboarding = location == AppRoutes.onboarding ||
          location.startsWith('${AppRoutes.onboarding}/');
      final legal = location == '/legal' || location.startsWith('/legal/');
      final leavingGate = location == AppRoutes.splash ||
          location == AppRoutes.setup ||
          location == AppRoutes.error;
      if (!session.hasProfile) {
        final signedIn = (session.uid ?? '').isNotEmpty;
        if (signedIn) {
          final creating = location == AppRoutes.createProfile || legal;
          return creating ? null : AppRoutes.createProfile;
        }
        return (onboarding || legal) ? null : AppRoutes.onboarding;
      }
      if (onboarding || leavingGate) return AppRoutes.discover;
      return null;
  }
}
