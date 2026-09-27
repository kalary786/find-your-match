/// Local switch for the Firebase client project.
///
/// Leave [isConfigured] false until `google-services.json` is in place and
/// Anonymous Auth plus Cloud Firestore are enabled. This file must never hold
/// admin credentials or a service account.
abstract final class FirebaseAppConfig {
  static const bool isConfigured = false;
}
