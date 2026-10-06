import 'package:find_your_match/core/api/match_api.dart';
import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/profile/profile_draft.dart';
import 'package:find_your_match/features/profile/saved_account.dart';

class FakeMatchApi implements MatchApi {
  MeResult? restoreResult;
  AccountFailure? restoreError;
  int restoreCalls = 0;
  AuthSession authResult = const AuthSession(
    token: 'token',
    userId: 'user-9',
    hasProfile: false,
  );

  @override
  Future<MeResult?> restore() async {
    restoreCalls += 1;
    final error = restoreError;
    if (error != null) throw error;
    return restoreResult;
  }

  @override
  Future<AuthSession> register({
    required String email,
    required String password,
  }) async {
    return authResult;
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    return authResult;
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> deleteAccount() async {}

  @override
  Future<ChatMessage> sendMessage({
    required String userId,
    required String text,
  }) async {
    return ChatMessage(
      id: 'sent',
      fromMe: true,
      text: text,
      timeLabel: 'Now',
    );
  }

  @override
  Future<List<ChatMessage>> messages(String userId) async => const [];

  @override
  Future<ProfileSave> createProfile(ProfileDraft draft) => _missing();

  @override
  Future<SavedAccount> updateProfile(ProfileDraft draft) => _missing();

  @override
  Future<SavedAccount> setHidden(bool hidden) => _missing();

  @override
  Future<void> setPrivacy({
    required bool showOnline,
    required bool showLastActive,
  }) => _missing();

  @override
  Future<List<Person>> discover() => _missing();

  @override
  Future<List<Person>> search({
    required String query,
    required SearchFilter filter,
  }) => _missing();

  @override
  Future<bool> like(String userId) => _missing();

  @override
  Future<void> pass(String userId) => _missing();

  @override
  Future<List<Person>> matches() => _missing();

  @override
  Future<List<ChatThread>> chats() => _missing();

  @override
  Future<void> block(String userId) => _missing();

  @override
  Future<void> unblock(String userId) => _missing();

  @override
  Future<List<Person>> blocked() => _missing();

  @override
  Future<void> report({
    required String userId,
    required String reason,
    required String details,
  }) => _missing();

  @override
  Future<HostedAd?> ad(String placement) => _missing();
}

Future<T> _missing<T>() {
  throw UnimplementedError('This test API call was not expected.');
}
