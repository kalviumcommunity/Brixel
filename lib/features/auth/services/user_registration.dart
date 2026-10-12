abstract class UserRegistration {
  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  });
}