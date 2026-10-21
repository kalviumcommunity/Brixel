import 'dart:async';

import 'package:brixel/features/auth/models/user_model.dart';
import 'package:brixel/features/auth/repositories/user_repository.dart';
import 'package:brixel/features/auth/screens/auth_state_gate.dart';
import 'package:brixel/features/auth/services/authentication_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthenticationState implements AuthenticationState {
  FakeAuthenticationState(this.userIds);

  final Stream<String?> userIds;

  @override
  Stream<String?> watchUserId() {
    return userIds;
  }
}

class FakeUserRepository implements UserRepository {
  FakeUserRepository({required this.profiles, this.error});

  final Map<String, UserModel?> profiles;
  final Object? error;

  @override
  Stream<UserModel?> watchUserProfile(String uid) {
    if (error != null) {
      return Stream<UserModel?>.error(error!);
    }

    return Stream.value(profiles[uid]);
  }
}

void main() {
  final createdAt = DateTime(2026, 10, 16);

  UserModel buildProfile({required String role}) {
    return UserModel(
      uid: 'user-1',
      email: 'user@example.com',
      displayName: 'Test User',
      role: role,
      assignedSiteIds: const ['site-jaipur-01'],
      createdAt: createdAt,
    );
  }

  Widget buildApp({
    required Stream<String?> authStream,
    Map<String, UserModel?> profiles = const {},
    Object? profileError,
  }) {
    return MaterialApp(
      home: AuthStateGate(
        authenticationState: FakeAuthenticationState(authStream),
        userRepository: FakeUserRepository(
          profiles: profiles,
          error: profileError,
        ),
        signedOutBuilder: (_) =>
            const Scaffold(body: Text('SIGNED OUT DESTINATION')),
        pendingBuilder: (_) =>
            const Scaffold(body: Text('PENDING DESTINATION')),
        supervisorBuilder: (_) =>
            const Scaffold(body: Text('SUPERVISOR DESTINATION')),
        managerBuilder: (_) =>
            const Scaffold(body: Text('MANAGER DESTINATION')),
      ),
    );
  }

  testWidgets('routes signed-out user to signed-out destination', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp(authStream: Stream.value(null)));

    await tester.pumpAndSettle();

    expect(find.text('SIGNED OUT DESTINATION'), findsOneWidget);

    expect(find.text('SUPERVISOR DESTINATION'), findsNothing);
  });

  testWidgets('routes pending user to pending destination', (tester) async {
    await tester.pumpWidget(
      buildApp(
        authStream: Stream.value('user-1'),
        profiles: {'user-1': buildProfile(role: 'pending')},
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('PENDING DESTINATION'), findsOneWidget);
  });

  testWidgets(
    'routes restored authenticated session directly to supervisor destination',
    (tester) async {
      await tester.pumpWidget(
        buildApp(
          authStream: Stream.value('user-1'),
          profiles: {'user-1': buildProfile(role: 'supervisor')},
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('SUPERVISOR DESTINATION'), findsOneWidget);

      expect(find.text('Welcome Back'), findsNothing);

      expect(find.text('MANAGER DESTINATION'), findsNothing);
    },
  );

  testWidgets('reacts to authentication changes while mounted', (tester) async {
    final controller = StreamController<String?>();

    try {
      await tester.pumpWidget(
        buildApp(
          authStream: controller.stream,
          profiles: {'user-1': buildProfile(role: 'supervisor')},
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('SIGNED OUT DESTINATION'), findsNothing);

      controller.add('user-1');
      await tester.pump();
      await tester.pump();

      expect(find.text('SUPERVISOR DESTINATION'), findsOneWidget);

      controller.add(null);
      await tester.pump();

      expect(find.text('SIGNED OUT DESTINATION'), findsOneWidget);
      expect(find.text('SUPERVISOR DESTINATION'), findsNothing);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      unawaited(controller.close());
    }
  });

  testWidgets('routes manager to manager destination', (tester) async {
    await tester.pumpWidget(
      buildApp(
        authStream: Stream.value('user-1'),
        profiles: {'user-1': buildProfile(role: 'manager')},
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('MANAGER DESTINATION'), findsOneWidget);

    expect(find.text('SUPERVISOR DESTINATION'), findsNothing);
  });

  testWidgets('missing profile does not grant application access', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(authStream: Stream.value('user-1'), profiles: const {}),
    );

    await tester.pumpAndSettle();

    expect(find.text('Account profile unavailable'), findsOneWidget);

    expect(find.text('SUPERVISOR DESTINATION'), findsNothing);

    expect(find.text('MANAGER DESTINATION'), findsNothing);
  });

  testWidgets('unknown role does not grant application access', (tester) async {
    await tester.pumpWidget(
      buildApp(
        authStream: Stream.value('user-1'),
        profiles: {'user-1': buildProfile(role: 'unexpected-role')},
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Access unavailable'), findsOneWidget);

    expect(find.text('SUPERVISOR DESTINATION'), findsNothing);

    expect(find.text('MANAGER DESTINATION'), findsNothing);
  });

  testWidgets('profile loading failure does not become empty access', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        authStream: Stream.value('user-1'),
        profileError: StateError('Firestore unavailable'),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Unable to load your access'), findsOneWidget);

    expect(find.text('SUPERVISOR DESTINATION'), findsNothing);
  });

  testWidgets('authentication error does not grant application access', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildApp(
        authStream: Stream<String?>.error(
          StateError('Authentication unavailable'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Unable to verify your account'), findsOneWidget);

    expect(find.text('SUPERVISOR DESTINATION'), findsNothing);
  });
}
