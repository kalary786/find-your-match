import 'package:flutter/foundation.dart';

class ProfilePhoto {
  const ProfilePhoto({required this.bytes, required this.contentType});

  final Uint8List bytes;
  final String contentType;
}

class ProfileDraft {
  const ProfileDraft({
    required this.username,
    required this.birthDate,
    required this.gender,
    required this.city,
    required this.bio,
    required this.interests,
    required this.preferences,
    required this.hasPhoto,
    this.photo,
  });

  final String username;
  final DateTime birthDate;
  final String gender;
  final String city;
  final String bio;
  final List<String> interests;
  final List<String> preferences;
  final bool hasPhoto;
  final ProfilePhoto? photo;

  String get birthDateText {
    final year = birthDate.year.toString().padLeft(4, '0');
    final month = birthDate.month.toString().padLeft(2, '0');
    final day = birthDate.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  Map<String, Object?> toCallableData() {
    return {
      'username': username,
      'birthDate': birthDateText,
      'gender': gender,
      'city': city,
      'bio': bio,
      'interests': interests,
      'relationshipPreferences': preferences,
    };
  }
}
