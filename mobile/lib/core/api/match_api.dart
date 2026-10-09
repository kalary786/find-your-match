import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/profile/profile_draft.dart';
import 'package:find_your_match/features/profile/saved_account.dart';

class AuthSession {
  const AuthSession({
    required this.token,
    required this.userId,
    required this.hasProfile,
    this.account,
  });

  final String token;
  final String userId;
  final bool hasProfile;
  final SavedAccount? account;
}

class MeResult {
  const MeResult({
    required this.userId,
    required this.hasProfile,
    this.account,
    this.showOnline = false,
    this.showLastActive = false,
  });

  final String userId;
  final bool hasProfile;
  final SavedAccount? account;
  final bool showOnline;
  final bool showLastActive;
}

class ChatThread {
  const ChatThread({required this.person, required this.lastMessage});

  final Person person;
  final String lastMessage;
}

class ProfileSave {
  const ProfileSave({required this.alreadyExisted, required this.account});

  final bool alreadyExisted;
  final SavedAccount account;
}

class AppNotice {
  const AppNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.linkUrl,
    required this.timeLabel,
    required this.read,
  });

  final String id;
  final String title;
  final String body;
  final String linkUrl;
  final String timeLabel;
  final bool read;

  AppNotice copyWith({bool? read}) {
    return AppNotice(
      id: id,
      title: title,
      body: body,
      linkUrl: linkUrl,
      timeLabel: timeLabel,
      read: read ?? this.read,
    );
  }
}

abstract class MatchApi {
  Future<MeResult?> restore();

  Future<AuthSession> register({
    required String email,
    required String password,
  });

  Future<AuthSession> login({required String email, required String password});

  Future<void> logout();

  Future<ProfileSave> createProfile(ProfileDraft draft);

  Future<SavedAccount> updateProfile(ProfileDraft draft);

  Future<SavedAccount> setHidden(bool hidden);

  Future<void> setPrivacy({
    required bool showOnline,
    required bool showLastActive,
  });

  Future<void> deleteAccount({required String password});

  Future<void> changePassword({
    required String currentPassword,
    required String password,
  });

  Future<List<Person>> discover();

  Future<List<Person>> search({
    required String query,
    required SearchFilter filter,
  });

  Future<bool> like(String userId);

  Future<void> pass(String userId);

  Future<void> unmatch(String userId);

  Future<List<Person>> matches();

  Future<List<ChatThread>> chats();

  Future<List<ChatMessage>> messages(String userId, {String? before});

  Future<ChatMessage> sendMessage({
    required String userId,
    required String text,
  });

  Future<void> block(String userId);

  Future<void> unblock(String userId);

  Future<List<Person>> blocked();

  Future<void> report({
    required String userId,
    required String reason,
    required String details,
  });

  Future<HostedAd?> ad(String placement);

  Future<List<AppNotice>> notices();

  Future<void> readNotice(String id);
}
