import 'package:brixel/core/services/firestore_database_service.dart';
import 'package:brixel/features/auth/models/user_model.dart';
import 'package:brixel/features/auth/repositories/user_repository.dart';

class FirestoreUserRepository implements UserRepository {
  FirestoreUserRepository({FirestoreDatabaseService? databaseService})
    : _databaseService = databaseService ?? FirestoreDatabaseService();

  final FirestoreDatabaseService _databaseService;

  @override
  Stream<UserModel?> watchUserProfile(String uid) {
    return _databaseService.streamUserProfile(uid);
  }
}
