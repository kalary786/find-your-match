import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/profile/profile_draft.dart';
import 'package:find_your_match/features/profile/saved_account.dart';
import 'package:image_picker/image_picker.dart';

class CreateOutcome {
  const CreateOutcome({required this.alreadyExisted, required this.account});

  final bool alreadyExisted;
  final SavedAccount account;
}

abstract class AccountActions {
  Future<CreateOutcome> create(ProfileDraft draft);
  Future<SavedAccount> update(ProfileDraft draft);
  Future<void> setHidden(bool hidden);
  Future<void> deleteAccount({required String password});
}

const maxPhotoBytes = 5 * 1024 * 1024;

Future<ProfilePhoto?> pickGalleryPhoto() async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: 1600,
    imageQuality: 85,
  );
  if (file == null) return null;
  final bytes = await file.readAsBytes();
  if (bytes.length > maxPhotoBytes) {
    throw const AccountFailure(
      AccountFailureKind.validation,
      'Profile photos must be smaller than 5 MB.',
    );
  }
  return ProfilePhoto(bytes: bytes, contentType: 'image/jpeg');
}
