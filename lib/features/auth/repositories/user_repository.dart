import 'package:brixel/features/auth/models/user_model.dart';

abstract class UserRepository {
  Stream<UserModel?> watchUserProfile(String uid);
}
