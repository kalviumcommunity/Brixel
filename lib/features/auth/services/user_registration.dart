abstract class UserRegistration {
  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  });
}

/// Authentication succeeded, but access-profile persistence was not confirmed.
/// The account must remain behind AuthStateGate until an administrator repairs
/// its profile or the pending write is acknowledged.
class RegistrationProfileUnavailable implements Exception {
  const RegistrationProfileUnavailable();
}
