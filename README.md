# Find Your Match

Meet. Match. Connect.

This repository is an 18+ Android dating and social matching app. The Flutter UI is in `mobile/`. Accounts, profiles, photos, matches, chats, reports, and ads are stored by the PHP site in `server/`, which you upload to your own hosting. There is no Firebase.

The admin panel is `server/admin/`. From there you can block or delete users, delete chats, review reports, and turn ads on or off. The admin password never goes in the Android app.

## Run the app

```bash
cd mobile
flutter pub get
flutter analyze
flutter test
flutter run
```

Set `ApiConfig.baseUrl` in `mobile/lib/core/api/api_config.dart` to the public `server` folder, for example `https://example.com/server`. Until that address is set, the app stays on the setup screen.

Setup steps are in [docs/SETUP.md](docs/SETUP.md). That document is a setup guide, not a statement that the app complies with Google Play policy.
