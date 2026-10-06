import 'package:find_your_match/features/preview/preview_models.dart';
import 'package:find_your_match/features/preview/profile_rules.dart';
import 'package:find_your_match/features/profile/profile_draft.dart';

Person personFromDraft(ProfileDraft draft, {String id = 'me', double hue = 8}) {
  return Person(
    id: id,
    username: draft.username,
    displayName: draft.username,
    age: ageInYears(draft.birthDate, DateTime.now()),
    gender: draft.gender,
    city: draft.city,
    bio: draft.bio,
    interests: draft.interests,
    preferences: draft.preferences,
    hue: hue,
    isSample: false,
    birthDate: draft.birthDate,
    hasPhoto: draft.hasPhoto,
  );
}

DateTime? parseBirthDate(Object? value) {
  if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return null;
  }
  final parts = value.split('-').map(int.parse).toList();
  return exactDate(parts[0], parts[1], parts[2]);
}

List<String> stringList(Object? value) {
  if (value is! List) return const [];
  return [for (final item in value) item.toString()];
}

Map<String, dynamic> stringKeyMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, item) => MapEntry(key.toString(), item));
}

Person personFromServer({
  required String uid,
  required Map<String, dynamic> profile,
  required DateTime? birthDate,
  required String? photoUrl,
}) {
  final username = profile['username']?.toString() ?? '';
  return Person(
    id: uid,
    username: username,
    displayName: username,
    age: profile['age'] is num ? (profile['age'] as num).toInt() : 0,
    gender: profile['gender']?.toString() ?? '',
    city: profile['city']?.toString() ?? '',
    bio: profile['bio']?.toString() ?? '',
    interests: stringList(profile['interests']),
    preferences: stringList(
      profile['preferences'] ?? profile['relationshipPreferences'],
    ),
    hue: profile['hue'] is num ? (profile['hue'] as num).toDouble() : 8,
    isSample: false,
    birthDate: birthDate,
    hasPhoto: photoUrl != null && photoUrl.isNotEmpty,
    photoUrl: photoUrl,
    online: profile['online'] == true,
    lastActive: profile['lastActive']?.toString() ?? '',
  );
}
