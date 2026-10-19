# Find Your Match (mobile)

Flutter client for Find Your Match. Meet. Match. Connect.

## Setup

```bash
flutter pub get
```

Point the app at your PHP API via `ApiConfig.baseUrl` / the in-app setup screen.

## Release signing (Android)

Copy `android/key.properties.example` to `android/key.properties` and fill in your upload keystore details. If `key.properties` is missing, release builds fall back to the debug keystore (fine for local size checks, not for Play Store).

## Smallest APK / Play Bundle

```bash
flutter clean
flutter pub get
# Smallest APKs (one per CPU type; drops x86_64) — share app-arm64-v8a-release.apk:
flutter build apk --release --split-per-abi --target-platform=android-arm,android-arm64 --obfuscate --split-debug-info=build/symbols --tree-shake-icons
# For Google Play (Play delivers the smallest per-device download):
flutter build appbundle --release --target-platform=android-arm,android-arm64 --obfuscate --split-debug-info=build/symbols
```

Expected result: about **7–10 MB** for `app-arm64-v8a-release.apk` (debug fat APKs are much larger because they include JIT/debug tooling and extra ABIs).

Outputs land in `build/app/outputs/flutter-apk/` and `build/app/outputs/bundle/release/`.

## Ads setup

Network banners, interstitials, app-open, and the Lofts link are configured in the admin **Network ads** page. The app requests **AdMob** units from those settings. Discover / Search / Matches also show self-hosted image ads via `PlacementAd` when uploaded in admin **Ads**.

### 1) AdMob App ID in the Android build

Set `android/app/build.gradle.kts` → `manifestPlaceholders["admobAppId"]` to your real AdMob App ID, then rebuild.

### 2) Ad unit IDs

Paste Banner / Interstitial / App open unit IDs on the admin Network ads page (same AdMob app as the App ID above).

### Packages

Only `google_mobile_ads` (no Meta mediation adapter — keeps the install size smaller).

## Checks

```bash
flutter analyze
flutter test
```

