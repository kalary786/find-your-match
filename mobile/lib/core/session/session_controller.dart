import 'package:find_your_match/core/firebase/firebase_app_config.dart';
import 'package:find_your_match/core/firebase/firebase_auth_gateway.dart';
import 'package:find_your_match/core/firebase/firestore_profile_gateway.dart';
import 'package:find_your_match/core/session/auth_gateway.dart';
import 'package:find_your_match/core/session/profile_gateway.dart';
import 'package:find_your_match/core/session/session_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseConfiguredProvider = Provider<bool>(
  (ref) => FirebaseAppConfig.isConfigured,
);

final authGatewayProvider = Provider<AuthGateway>(
  (ref) => FirebaseAuthGateway(),
);

final profileGatewayProvider = Provider<ProfileGateway>(
  (ref) => FirestoreProfileGateway(),
);

/// When set, routing tests skip Firebase and use this session as-is.
final sessionSeedProvider = Provider<SessionState?>((ref) => null);

/// Keeps the splash on screen briefly. Tests override this to zero.
final splashHoldProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 700),
);

class SessionController extends Notifier<SessionState> {
  @override
  SessionState build() {
    return ref.watch(sessionSeedProvider) ?? const SessionState.loading();
  }

  Future<void> bootstrap() async {
    if (ref.read(sessionSeedProvider) != null) return;

    state = const SessionState.loading();
    if (!ref.read(firebaseConfiguredProvider)) {
      final hold = ref.read(splashHoldProvider);
      if (hold > Duration.zero) {
        await Future<void>.delayed(hold);
      }
      if (ref.read(sessionSeedProvider) != null) return;
      state = const SessionState.ready(
        uid: 'local-preview',
        hasProfile: false,
      );
      return;
    }

    try {
      final uid = await ref.read(authGatewayProvider).ensureAnonymousUser();
      final hasProfile = await ref
          .read(profileGatewayProvider)
          .hasCompletedProfile(uid);
      state = SessionState.ready(uid: uid, hasProfile: hasProfile);
    } on AuthFailure catch (error) {
      state = SessionState.failed(error.message);
    } catch (error, stackTrace) {
      debugPrint('Session bootstrap failed: $error\n$stackTrace');
      state = const SessionState.failed(
        'Could not start your session. Check your connection and try again.',
      );
    }
  }

  void completeLocalProfile() {
    final current = state;
    if (current.status != SessionStatus.ready) return;
    state = SessionState.ready(
      uid: current.uid ?? 'local-preview',
      hasProfile: true,
    );
  }

  void forgetLocalProfile() {
    final current = state;
    state = SessionState.ready(
      uid: current.uid ?? 'local-preview',
      hasProfile: false,
    );
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
