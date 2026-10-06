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
      gender: 'Woman',
      city: 'Kochi',
      bio: 'A short bio for the form.',
      hasPhoto: true,
      interests: {'Coffee'},
      preferences: {'Dating'},
      takenUsernames: const {},
      today: today,
    );
    expect(error, contains('18 or older'));
  });

  test('a taken username cannot be reused', () {
    final error = validateProfile(
      username: 'sample_mina',
      birthDate: DateTime(1998, 4, 2),
      gender: 'Man',
      city: 'Pune',
      bio: 'A short bio for the form.',
      hasPhoto: true,
      interests: {'Music'},
      preferences: {'Friendship'},
      takenUsernames: const {'sample_mina'},
      today: today,
    );
    expect(error, contains('already used'));
  });

  test('a valid adult profile passes', () {
    expect(
      validateProfile(
        username: 'alex_1',
        birthDate: DateTime(1998, 4, 2),
        gender: 'Man',
        city: 'Pune',
        bio: 'A short bio for the form.',
        hasPhoto: true,
        interests: {'Music'},
        preferences: {'Friendship'},
        takenUsernames: const {'sample_mina'},
        today: today,
      ),
      isNull,
    );
  });
}
