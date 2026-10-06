import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SavedAccount {
  const SavedAccount({required this.person, required this.hidden});

  final Person person;
  final bool hidden;
}

class SavedAccountController extends Notifier<SavedAccount?> {
  @override
  SavedAccount? build() => null;

  void replace(SavedAccount? account) => state = account;
}

final savedAccountProvider =
    NotifierProvider<SavedAccountController, SavedAccount?>(
      SavedAccountController.new,
    );
