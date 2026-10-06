import 'package:find_your_match/features/profile/account_failure.dart';
import 'package:find_your_match/features/profile/profile_draft.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('birth date is sent as a calendar date, not a UTC shift', () {
    final draft = ProfileDraft(
      username: 'alex_1',
      birthDate: DateTime(1998, 4, 2),
      gender: 'Man',
      city: 'Pune',
      bio: 'A short bio for the form.',
      interests: const ['Music'],
      preferences: const ['Dating'],
      hasPhoto: true,
      photo: ProfilePhoto(bytes: Uint8List(8), contentType: 'image/jpeg'),
    );

    expect(draft.birthDateText, '1998-04-02');
    expect(draft.toCallableData()['birthDate'], '1998-04-02');
  });

  test('offline and duplicate-username errors stay explicit', () {
    expect(
      AccountFailure.fromCode('unavailable', null).kind,
      AccountFailureKind.offline,
    );
    expect(
      AccountFailure.fromCode('already-exists', 'That username is already taken.').message,
      'That username is already taken.',
    );
    expect(
      AccountFailure.fromCode('not-found', null).kind,
      AccountFailureKind.unavailable,
    );
  });
}
