import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:find_your_match/core/session/profile_gateway.dart';

class FirestoreProfileGateway implements ProfileGateway {
  @override
  Future<bool> hasCompletedProfile(String uid) async {
    final snapshot = await FirebaseFirestore.instance
        .doc('users/$uid/public/profile')
        .get();
    final data = snapshot.data();
    return snapshot.exists && data?['onboardingComplete'] == true;
  }
}
