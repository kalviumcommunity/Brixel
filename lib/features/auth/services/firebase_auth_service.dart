import 'package:firebase_auth/firebase_auth.dart';

import 'authentication_state.dart';
import 'user_authentication.dart';

class FirebaseAuthService implements UserAuthentication, AuthenticationState {
  FirebaseAuthService({FirebaseAuth? firebaseAuth})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _firebaseAuth;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> authStateChanges() {
    return _firebaseAuth.authStateChanges();
  }

  @override
  Stream<String?> watchUserId() {
    return _firebaseAuth.authStateChanges().map((user) => user?.uid);
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    return _firebaseAuth.signOut();
  }
}
