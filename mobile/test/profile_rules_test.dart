import 'package:find_your_match/features/preview/profile_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final today = DateTime(2026, 9, 27);

  test('a birthday today counts as 18', () {
    expect(isAtLeast18(DateTime(2008, 9, 27), today), isTrue);
    expect(isAtLeast18(DateTime(2008, 9, 28), today), isFalse);
  });

  test('an under-18 date is rejected and nothing would be saved', () {
    final error = validateProfile(
      username: 'alex',
      birthDate: DateTime(2010, 1, 1),
      gender: null,
      city: 'Pakistan',
      bio: '',
      hasPhoto: false,
      interests: {},
      preferences: {},
      takenUsernames: const {},
      today: today,
    );
    expect(error, contains('18 or older'));
  });

  test('a taken username cannot be reused', () {
    final error = validateProfile(
      username: 'sample_mina',
      birthDate: DateTime(1998, 4, 2),
      gender: null,
      city: 'Pakistan',
      bio: '',
      hasPhoto: false,
      interests: {},
      preferences: {},
      takenUsernames: const {'sample_mina'},
      today: today,
    );
    expect(error, contains('already used'));
  });

  test('only username, country, and age are required', () {
    expect(
      validateProfile(
        username: 'alex_1',
        birthDate: DateTime(1998, 4, 2),
        gender: null,
        city: 'Pakistan',
        bio: '',
        hasPhoto: false,
        interests: {},
        preferences: {},
        takenUsernames: const {'sample_mina'},
        today: today,
      ),
      isNull,
    );
  });

  test('empty required fields show errors on those fields', () {
    final errors = validateProfileFields(
      username: '',
      birthDate: null,
      country: '',
      takenUsernames: const {},
      today: today,
    );
    expect(errors.username, contains('username'));
    expect(errors.birthDate, contains('date of birth'));
    expect(errors.country, contains('country'));
    expect(errors.hasAny, isTrue);
  });
}
