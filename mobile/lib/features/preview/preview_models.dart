class Person {
  const Person({
    required this.id,
    required this.username,
    required this.displayName,
    required this.age,
    required this.gender,
    required this.city,
    required this.bio,
    required this.interests,
    required this.preferences,
    required this.hue,
    required this.isSample,
    this.birthDate,
    this.hasPhoto = true,
    this.online = false,
    this.lastActive = 'Active today',
    this.verified = false,
    this.likesYou = false,
  });

  final String id;
  final String username;
  final String displayName;
  final int age;
  final String gender;
  final String city;
  final String bio;
  final List<String> interests;
  final List<String> preferences;
  final double hue;
  final bool isSample;
  final DateTime? birthDate;
  final bool hasPhoto;
  final bool online;
  final String lastActive;
  final bool verified;
  final bool likesYou;

  String get initials {
    final parts = displayName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase());
    final value = parts.join();
    return value.isEmpty ? '?' : value;
  }

  Person copyWith({
    String? username,
    String? displayName,
    int? age,
    String? gender,
    String? city,
    String? bio,
    List<String>? interests,
    List<String>? preferences,
    bool? hasPhoto,
    DateTime? birthDate,
    bool? isSample,
    bool? online,
    String? lastActive,
  }) {
    return Person(
      id: id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      city: city ?? this.city,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      preferences: preferences ?? this.preferences,
      hue: hue,
      isSample: isSample ?? this.isSample,
      birthDate: birthDate ?? this.birthDate,
      hasPhoto: hasPhoto ?? this.hasPhoto,
      online: online ?? this.online,
      lastActive: lastActive ?? this.lastActive,
      verified: verified,
      likesYou: likesYou,
    );
  }
}

class PreviewMessage {
  const PreviewMessage({
    required this.id,
    required this.fromMe,
    required this.text,
    required this.timeLabel,
  });

  final String id;
  final bool fromMe;
  final String text;
  final String timeLabel;
}

class SearchFilter {
  const SearchFilter({
    this.minAge = 18,
    this.maxAge = 45,
    this.gender,
    this.interests = const {},
    this.preferences = const {},
  });

  final int minAge;
  final int maxAge;
  final String? gender;
  final Set<String> interests;
  final Set<String> preferences;

  bool get isActive =>
      minAge != 18 ||
      maxAge != 45 ||
      gender != null ||
      interests.isNotEmpty ||
      preferences.isNotEmpty;

  SearchFilter copyWith({
    int? minAge,
    int? maxAge,
    String? gender,
    bool clearGender = false,
    Set<String>? interests,
    Set<String>? preferences,
  }) {
    return SearchFilter(
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      gender: clearGender ? null : (gender ?? this.gender),
      interests: interests ?? this.interests,
      preferences: preferences ?? this.preferences,
    );
  }
}

abstract final class ProfileOptions {
  static const genders = ['Woman', 'Man', 'Non-binary', 'Prefer not to say'];
  static const interests = [
    'Coffee',
    'Hiking',
    'Cooking',
    'Music',
    'Travel',
    'Reading',
    'Fitness',
    'Movies',
    'Art',
    'Photography',
  ];
  static const preferences = [
    'Friendship',
    'Dating',
    'Long-term relationship',
    'Marriage',
  ];
  static const reportReasons = [
    'Harassment',
    'Spam',
    'Fake profile',
    'Inappropriate photo',
    'Hate',
    'Threat',
    'Other',
  ];
}
