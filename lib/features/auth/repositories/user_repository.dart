import 'package:brixel/features/auth/models/user_model.dart';

abstract class UserRepository {
  Stream<UserModel?> watchUserProfile(String uid);
  Stream<List<UserModel>> watchPendingUsers();
  Future<void> approveUser(
    String uid, {
    String role = 'supervisor',
    List<String> assignedSiteIds = const [],
  });
  Future<void> rejectUser(String uid);
}
