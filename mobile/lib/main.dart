import 'package:find_your_match/app.dart';
import 'package:find_your_match/core/firebase/firebase_bootstrap.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeFirebaseIfConfigured();
  runApp(const ProviderScope(child: FindYourMatchApp()));
}
