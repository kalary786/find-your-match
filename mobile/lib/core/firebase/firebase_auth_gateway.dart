import 'package:find_your_match/core/session/auth_gateway.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthGateway implements AuthGateway {
  @override
  Future<String> ensureAnonymousUser() async {
    final current = FirebaseAuth.instance.currentUser;
    if (current != null) return current.uid;

    final credential = await FirebaseAuth.instance.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw const AuthFailure('Anonymous sign-in did not return a user.');
    }
    return user.uid;
  }
}
