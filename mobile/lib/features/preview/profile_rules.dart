/// Age and field checks for the profile form.
/// The server repeats these checks before anything is stored.
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

/// Only [username], [birthDate] (18+), and [country] are required.
/// Gender, bio, photo, interests, and preferences may be empty.
class ProfileFieldErrors {
  const ProfileFieldErrors({
    this.username,
    this.birthDate,
    this.country,
  });

  final String? username;
  final String? birthDate;
  final String? country;

  bool get hasAny =>
      username != null || birthDate != null || country != null;

  String? get firstMessage => username ?? birthDate ?? country;
}

ProfileFieldErrors validateProfileFields({
  required String username,
  required DateTime? birthDate,
  required String country,
  required Set<String> takenUsernames,
  DateTime? today,
}) {
  String? usernameError;
  String? birthError;
  String? countryError;

  final name = username.trim().toLowerCase();
  if (name.isEmpty) {
    usernameError = 'Enter a username.';
  } else if (!RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(name)) {
    usernameError =
        'Username must be 3–20 characters: lowercase letters, numbers, or underscore.';
  } else if (takenUsernames.contains(name)) {
    usernameError = 'That username is already used.';
  }

  final now = today ?? DateTime.now();
  if (birthDate == null) {
    birthError = 'Enter your date of birth.';
  } else if (!isAtLeast18(birthDate, now)) {
    birthError = 'You must be 18 or older. No profile was saved.';
  }

  final place = country.trim();
  if (place.isEmpty) {
    countryError = 'Enter your country.';
  } else if (!RegExp(r"^[A-Za-z][A-Za-z .'-]{1,39}$").hasMatch(place)) {
    countryError = 'Enter a country using letters, up to 40 characters.';
  }

  return ProfileFieldErrors(
    username: usernameError,
    birthDate: birthError,
    country: countryError,
  );
}

/// Returns the first required-field error, or null when the profile can be saved.
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
  return validateProfileFields(
    username: username,
    birthDate: birthDate,
    country: city,
    takenUsernames: takenUsernames,
    today: today,
  ).firstMessage;
}
