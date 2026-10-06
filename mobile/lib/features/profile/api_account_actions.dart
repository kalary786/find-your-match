import 'package:find_your_match/core/session/session_controller.dart';
import 'package:find_your_match/features/profile/account_actions.dart';
import 'package:find_your_match/features/profile/profile_draft.dart';
import 'package:find_your_match/features/profile/saved_account.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiAccountActions implements AccountActions {
  ApiAccountActions(this._ref);

  final Ref _ref;

  @override
  Future<CreateOutcome> create(ProfileDraft draft) async {
    final saved = await _ref.read(matchApiProvider).createProfile(draft);
    _ref.read(savedAccountProvider.notifier).replace(saved.account);
    _ref.read(sessionControllerProvider.notifier).adoptAccount(
      uid: saved.account.person.id,
      hasProfile: true,
    );
    return CreateOutcome(
      alreadyExisted: saved.alreadyExisted,
      account: saved.account,
    );
  }

  @override
  Future<SavedAccount> update(ProfileDraft draft) async {
    final account = await _ref.read(matchApiProvider).updateProfile(draft);
    _ref.read(savedAccountProvider.notifier).replace(account);
    return account;
  }

  @override
  Future<void> setHidden(bool hidden) async {
    final account = await _ref.read(matchApiProvider).setHidden(hidden);
    _ref.read(savedAccountProvider.notifier).replace(account);
  }

  @override
  Future<void> deleteAccount() async {
    await _ref.read(matchApiProvider).deleteAccount();
    await _ref.read(sessionControllerProvider.notifier).signOut();
  }
}

final accountActionsProvider = Provider<AccountActions>(
  (ref) => ApiAccountActions(ref),
);
