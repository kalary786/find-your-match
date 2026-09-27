enum SessionStatus { loading, needsSetup, ready, error }

class SessionState {
  const SessionState._({
    required this.status,
    this.uid,
    this.hasProfile = false,
    this.errorMessage,
  });

  const SessionState.loading() : this._(status: SessionStatus.loading);

  const SessionState.needsSetup() : this._(status: SessionStatus.needsSetup);

  const SessionState.ready({
    required String uid,
    required bool hasProfile,
  }) : this._(
         status: SessionStatus.ready,
         uid: uid,
         hasProfile: hasProfile,
       );

  const SessionState.failed(String message)
    : this._(status: SessionStatus.error, errorMessage: message);

  final SessionStatus status;
  final String? uid;
  final bool hasProfile;
  final String? errorMessage;
}
