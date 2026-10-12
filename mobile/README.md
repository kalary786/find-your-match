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

AdMob is the mediation host; Meta Audience Network is added as a **bidding** source in the AdMob console. The app only requests AdMob unit IDs — mediation picks AdMob or Meta per impression (no client-side 50/50 rotation). If both fail, `SmartBannerAd` falls back to the self-hosted `PlacementAd`.

### 1) Put your real AdMob IDs in the app

Edit `lib/features/ads/ad_config.dart`:

- Replace `YOUR_BANNER_ID`, `YOUR_INTERSTITIAL_ID`, `YOUR_NATIVE_ID` (and the prod app id).
- Debug / profile builds use Google **test** units automatically (`kUseTestAds = !kReleaseMode`).
- Android app id placeholder: `android/app/build.gradle.kts` → `manifestPlaceholders["admobAppId"]` (test id is already set).

Optional debug helpers:

- Add your device to `AdConfig.testDeviceIds` (hash from logcat).
- For Meta test ads, add the Meta hashed device id in Audience Network Testing (hash is logged by the Meta SDK).

### 2) AdMob console — mediation group

1. Create an AdMob app (Android) and Banner + Interstitial ad units.
2. **Mediation** → create a mediation group for **Banner** (Android) and another for **Interstitial**.
3. Add **Meta Audience Network** as a **bidding** source.
4. Enter the Meta Placement IDs that match each format.
5. Keep AdMob in the same group so bidding can choose the higher-paying network.

### 3) Meta Business / Audience Network

1. In Meta Business Suite / Audience Network, create the app (same package: `com.findyourmatch.app`).
2. Create Banner and Interstitial placements.
3. Copy those Placement IDs into the AdMob mediation group (step 2).
4. Ensure the property is approved for Audience Network.

### 4) Check AdMob vs Meta share

In AdMob: **Mediation** reports (or Reporting → filter by mediation network). Compare impressions / estimated earnings for AdMob vs Meta on the same ad units over a few days.

### Packages

Only `google_mobile_ads` and `gma_mediation_meta` (official Meta adapter). No `facebook_audience_network`.

## Checks

```bash
flutter analyze
flutter test
```

