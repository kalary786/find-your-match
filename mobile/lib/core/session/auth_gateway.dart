/// Starts or resumes the anonymous Firebase user.
abstract class AuthGateway {
  Future<String> ensureAnonymousUser();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;
}
