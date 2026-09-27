/// Age and field checks for the on-device profile form.
/// Nothing here writes to Firebase.
bool isAtLeast18(DateTime birth, DateTime today) {
  final cutoff = DateTime(today.year - 18, today.month, today.day);
  return !birth.isAfter(cutoff);
}

DateTime? exactDate(int? year, int? month, int? day) {
  if (year == null || month == null || day == null) return null;
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return date;
}

int ageInYears(DateTime birth, DateTime today) {
  var age = today.year - birth.year;
  final birthday = DateTime(today.year, birth.month, birth.day);
  if (birthday.isAfter(today)) age -= 1;
  return age;
}

String? validateProfile({
  required String username,
  required DateTime? birthDate,
  required String? gender,
  required String city,
  required String bio,
  required bool hasPhoto,
  required Set<String> interests,
  required Set<String> preferences,
  required Set<String> takenUsernames,
  DateTime? today,
}) {
  final name = username.trim().toLowerCase();
  if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(name)) {
    return 'Username must be 3–20 characters: lowercase letters, numbers, or underscore.';
  }
  if (takenUsernames.contains(name)) {
    return 'That username is already used by a sample profile.';
  }
  if (birthDate == null) return 'Enter your date of birth.';
  final now = today ?? DateTime.now();
  if (!isAtLeast18(birthDate, now)) {
    return 'You must be 18 or older. No profile was saved.';
  }
  if (gender == null || !const {
    'Woman',
    'Man',
    'Non-binary',
    'Prefer not to say',
  }.contains(gender)) {
    return 'Choose a gender.';
  }
  final cityName = city.trim();
  if (!RegExp(r"^[A-Za-z][A-Za-z .'-]{1,39}$").hasMatch(cityName)) {
    return 'Enter a city using letters, up to 40 characters.';
  }
  if (!hasPhoto) return 'Add a preview photo to continue.';
  final about = bio.trim();
  if (about.length < 8 || about.length > 300) {
    return 'Bio must be between 8 and 300 characters.';
  }
  if (interests.isEmpty) return 'Choose at least one interest.';
  if (preferences.isEmpty) return 'Choose at least one relationship preference.';
  return null;
}
