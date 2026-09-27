# Find Your Match

Meet. Match. Connect.

This repository is an 18+ Android dating and social matching app. The Flutter UI is in place with on-device sample profiles for layout. Firebase is not connected yet, so nothing is written to a database.

The Android app lives in `mobile/`.

## Run the app

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

The first launch shows onboarding and a profile form that stays on the phone. Discover, search, matches, and chat use clearly labeled sample people.

Setup steps for Firebase, AdMob, and Play Console are in [docs/SETUP.md](docs/SETUP.md). That document is a setup guide, not a statement that the app complies with Google Play policy.
