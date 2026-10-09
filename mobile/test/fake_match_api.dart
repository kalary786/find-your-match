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

  String? changedPassword;
  String? deletedWithPassword;

  @override
  Future<void> deleteAccount({required String password}) async {
    deletedWithPassword = password;
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String password,
  }) async {
    changedPassword = password;
  }

  int sendCalls = 0;
  AccountFailure? sendError;
  Future<void> Function()? sendGate;
  int messageCalls = 0;
  String? lastBefore;
  List<ChatMessage> messageResult = const [];
  Map<String, List<ChatMessage>> olderMessages = const {};
  AccountFailure? messageError;
  Future<void> Function()? messageGate;
  int likeCalls = 0;
  bool likeMatched = false;
  List<Person> matchesResult = const [];
  List<ChatThread> chatsResult = const [];
  List<Person> blockedResult = const [];
  List<Person> discoverResult = const [];
  int unblockCalls = 0;
  int matchesCalls = 0;
  Future<void> Function()? matchesGate;
  int blockCalls = 0;

  @override
  Future<ChatMessage> sendMessage({
    required String userId,
    required String text,
  }) async {
    sendCalls += 1;
    final gate = sendGate;
    if (gate != null) await gate();
    final error = sendError;
    if (error != null) throw error;
    return ChatMessage(id: 'sent', fromMe: true, text: text, timeLabel: 'Now');
  }

  @override
  Future<List<ChatMessage>> messages(String userId, {String? before}) async {
    messageCalls += 1;
    lastBefore = before;
    final gate = messageGate;
    if (gate != null) await gate();
    final error = messageError;
    if (error != null) throw error;
    if (before != null) return olderMessages[before] ?? const [];
    return messageResult;
  }

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
  Future<List<Person>> discover() async => discoverResult;

  @override
  Future<List<Person>> search({
    required String query,
    required SearchFilter filter,
  }) => _missing();

  @override
  Future<bool> like(String userId) async {
    likeCalls += 1;
    return likeMatched;
  }

  @override
  Future<void> pass(String userId) => _missing();

  @override
  Future<void> unmatch(String userId) async {}

  @override
  Future<List<Person>> matches() async {
    matchesCalls += 1;
    final gate = matchesGate;
    if (gate != null) await gate();
    return matchesResult;
  }

  @override
  Future<List<ChatThread>> chats() async => chatsResult;

  @override
  Future<void> block(String userId) async {
    blockCalls += 1;
  }

  @override
  Future<void> unblock(String userId) async {
    unblockCalls += 1;
  }

  @override
  Future<List<Person>> blocked() async => blockedResult;

  @override
  Future<void> report({
    required String userId,
    required String reason,
    required String details,
  }) => _missing();

  @override
  Future<HostedAd?> ad(String placement) => _missing();

  @override
  Future<List<AppNotice>> notices() async => const [];

  @override
  Future<void> readNotice(String id) async {}
}

Future<T> _missing<T>() {
  throw UnimplementedError('This test API call was not expected.');
}
