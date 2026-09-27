/// Reads whether this user already finished profile creation.
abstract class ProfileGateway {
  Future<bool> hasCompletedProfile(String uid);
}
