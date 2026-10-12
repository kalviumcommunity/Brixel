import 'package:brixel/core/services/firestore_database_service.dart';
import 'package:brixel/features/auth/services/firebase_auth_service.dart';
import 'package:brixel/features/auth/services/user_registration.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserRegistrationService implements UserRegistration {
  UserRegistrationService({
    FirebaseAuthService? authService,
    FirestoreDatabaseService? databaseService,
  }) : _authService = authService ?? FirebaseAuthService(),
       _databaseService = databaseService ?? FirestoreDatabaseService();

  final FirebaseAuthService _authService;
  final FirestoreDatabaseService _databaseService;

  @override
  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final credential = await _authService.signUp(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw StateError(
        'Firebase Authentication did not return a user after sign-up.',
      );
    }

    await _databaseService.usersCollection.doc(user.uid).set({
      'uid': user.uid,
      'email': user.email ?? email.trim(),
      'displayName': displayName.trim(),
      'role': 'pending',
      'assignedSiteIds': <String>[],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
