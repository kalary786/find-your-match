import 'package:find_your_match/core/api/api_config.dart';
import 'package:find_your_match/core/api/http_match_api.dart';
import 'package:find_your_match/core/api/match_api.dart';
import 'package:find_your_match/core/api/token_store.dart';
import 'package:find_your_match/core/session/session_state.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/profile/saved_account.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final apiBaseUrlProvider = Provider<String>((ref) => ApiConfig.baseUrl);

final tokenStoreProvider = Provider<TokenStore>((ref) => PrefsTokenStore());

final matchApiProvider = Provider<MatchApi>((ref) {
  return HttpMatchApi(
    baseUrl: ref.watch(apiBaseUrlProvider),
    tokens: ref.watch(tokenStoreProvider),
  );
});

/// When set, routing tests skip the network and use this session as-is.
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

    final base = ref.read(apiBaseUrlProvider).trim();
    if (base.isEmpty) {
      final hold = ref.read(splashHoldProvider);
      if (hold > Duration.zero) {
        await Future<void>.delayed(hold);
      }
      if (ref.read(sessionSeedProvider) != null) return;
      state = const SessionState.needsSetup();
      return;
    }

    state = const SessionState.loading();
    try {
      final me = await ref.read(matchApiProvider).restore();
      if (me == null) {
        ref.read(savedAccountProvider.notifier).replace(null);
        state = const SessionState.ready(uid: '', hasProfile: false);
        return;
      }
      ref.read(savedAccountProvider.notifier).replace(me.account);
      state = SessionState.ready(uid: me.userId, hasProfile: me.hasProfile);
    } on AccountFailure catch (error) {
      state = SessionState.failed(
        error.kind == AccountFailureKind.offline
            ? 'You appear to be offline. Connect and try again.'
            : error.message,
      );
    } catch (error, stackTrace) {
      debugPrint('Session bootstrap failed: $error\n$stackTrace');
      state = const SessionState.failed(
        'Could not start your session. Check your connection and try again.',
      );
    }
  }

  void adoptAccount({required String uid, required bool hasProfile}) {
    state = SessionState.ready(uid: uid, hasProfile: hasProfile);
  }

  Future<void> signOut() async {
    try {
      await ref.read(matchApiProvider).logout();
    } on AccountFailure {
      // The token is cleared by the API client.
    }
    ref.read(savedAccountProvider.notifier).replace(null);
    state = const SessionState.ready(uid: '', hasProfile: false);
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
