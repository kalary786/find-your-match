enum AccountFailureKind {
  validation,
  offline,
  taken,
  missing,
  rate,
  unavailable,
  unknown,
}

class AccountFailure implements Exception {
  const AccountFailure(this.kind, this.message);

  final AccountFailureKind kind;
  final String message;

  static AccountFailure fromCode(String code, String? message) {
    switch (code) {
      case 'unavailable':
      case 'deadline-exceeded':
      case 'network-request-failed':
        return const AccountFailure(
          AccountFailureKind.offline,
          'You appear to be offline. Nothing was saved. Connect and try again.',
        );
      case 'already-exists':
        return AccountFailure(
          AccountFailureKind.taken,
          message ?? 'That username is already taken.',
        );
      case 'invalid-argument':
        return AccountFailure(
          AccountFailureKind.validation,
          message ?? 'Check the form and try again.',
        );
      case 'resource-exhausted':
        return AccountFailure(
          AccountFailureKind.rate,
          message ?? 'Please wait a few seconds before saving again.',
        );
      case 'failed-precondition':
        return AccountFailure(
          AccountFailureKind.missing,
          message ?? 'Create a profile before changing it.',
        );
      case 'not-found':
        return AccountFailure(
          AccountFailureKind.unavailable,
          message ?? 'That profile is not available.',
        );
      case 'unauthenticated':
        return const AccountFailure(
          AccountFailureKind.unknown,
          'Sign in again.',
        );
      case 'blocked':
        return AccountFailure(
          AccountFailureKind.unknown,
          message ?? 'This account is blocked.',
        );
      default:
        return AccountFailure(
          AccountFailureKind.unknown,
          message ?? 'The profile could not be saved. Try again.',
        );
    }
  }

  @override
  String toString() => message;
}
