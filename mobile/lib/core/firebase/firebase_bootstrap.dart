import 'package:find_your_match/core/firebase/firebase_app_config.dart';
import 'package:firebase_core/firebase_core.dart';

/// Initializes the Firebase client only after the local project flag is on.
/// Android reads the app id from `google-services.json` when that file exists.
Future<void> initializeFirebaseIfConfigured() async {
  if (!FirebaseAppConfig.isConfigured) return;
  await Firebase.initializeApp();
}
