import 'package:brixel/features/auth/models/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores the supplied profile fields', () {
    const profile = UserProfile(
      id: 'user-001',
      name: 'Demo Supervisor',
      email: 'supervisor@example.com',
      role: 'supervisor',
    );

    expect(profile.id, 'user-001');
    expect(profile.name, 'Demo Supervisor');
    expect(profile.email, 'supervisor@example.com');
    expect(profile.role, 'supervisor');
  });
}
