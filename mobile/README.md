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

## Checks

```bash
flutter analyze
flutter test
```
