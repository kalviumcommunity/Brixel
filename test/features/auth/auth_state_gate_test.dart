import 'package:brixel/features/sites/models/site_model.dart';
import 'package:brixel/features/sites/repositories/site_repository.dart';

import 'dart:async';

import 'package:brixel/features/auth/models/user_model.dart';
import 'package:brixel/features/auth/repositories/user_repository.dart';
import 'package:brixel/features/auth/screens/auth_state_gate.dart';
import 'package:brixel/features/auth/screens/login_screen.dart';
import 'package:brixel/features/auth/services/authentication_state.dart';
import 'package:brixel/features/auth/services/user_authentication.dart';
import 'package:brixel/features/navigation/screens/app_navigation_shell.dart';
import 'package:brixel/features/sites/screens/site_selection_screen.dart';
import 'package:brixel/main.dart';
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
  int watchCount = 0;

  @override
  Stream<UserModel?> watchUserProfile(String uid) {
    watchCount++;
    if (error != null) {
      return Stream<UserModel?>.error(error!);
    }

    return Stream.value(profiles[uid]);
  }
}

class FakeSessionAuthentication
    implements AuthenticationState, UserAuthentication {
  FakeSessionAuthentication(this.userIds);

  final StreamController<String?> userIds;
  String? userId;
  int signInCallCount = 0;
  int signOutCallCount = 0;

  @override
  Stream<String?> watchUserId() => userIds.stream;

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCallCount++;
    userId = 'user-1';
    userIds.add(userId);
  }

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    userId = null;
    userIds.add(userId);
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

  testWidgets('rebuilds keep the active profile subscription', (tester) async {
    final auth = StreamController<String?>.broadcast();
    addTearDown(auth.close);
    final repository = FakeUserRepository(
      profiles: {'user-1': buildProfile(role: 'pending')},
    );
    late StateSetter rebuild;
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return AuthStateGate(
              authenticationState: FakeAuthenticationState(auth.stream),
              userRepository: repository,
              pendingBuilder: (_) => const Text('PENDING'),
            );
          },
        ),
      ),
    );
    auth.add('user-1');
    await tester.pumpAndSettle();
    expect(repository.watchCount, 1);
    rebuild(() {});
    await tester.pumpAndSettle();
    expect(repository.watchCount, 1);
    expect(find.text('PENDING'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('switching accounts never retains the previous role', (
    tester,
  ) async {
    final auth = StreamController<String?>(sync: true);
    addTearDown(auth.close);
    await tester.pumpWidget(
      buildApp(
        authStream: auth.stream,
        profiles: {'user-1': buildProfile(role: 'manager')},
      ),
    );
    auth.add('user-1');
    await tester.pumpAndSettle();
    expect(find.text('MANAGER DESTINATION'), findsOneWidget);
    auth.add('missing-profile-user');
    await tester.pump();
    expect(find.text('MANAGER DESTINATION'), findsNothing);
    await tester.pumpAndSettle();
    expect(find.text('Account profile unavailable'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

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
          profiles: {
            'user-1': buildProfile(role: 'supervisor')
                .copyWith(assignedSiteIds: ['test-site']),
          },
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
          profiles: {
            'user-1': buildProfile(role: 'supervisor')
                .copyWith(assignedSiteIds: ['test-site']),
          },
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

  testWidgets(
    'manager without assignments can select sites through manager repository',
    (tester) async {
      final sites = TestSiteRepository();
      await tester.pumpWidget(
        MaterialApp(
          home: AuthStateGate(
            authenticationState: FakeAuthenticationState(
              Stream.value('user-1'),
            ),
            userRepository: FakeUserRepository(
              profiles: {
                'user-1': buildProfile(role: 'manager')
                    .copyWith(assignedSiteIds: []),
              },
            ),
            siteRepository: sites,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(sites.allSitesCalls, 1);
      expect(find.text('Test site'), findsOneWidget);
      expect(
        find.text('No sites assigned. Contact your manager.'),
        findsNothing,
      );
    },
  );

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

  testWidgets(
    'logout removes pushed protected routes from the session navigator',
    (tester) async {
      final auth = StreamController<String?>();
      addTearDown(auth.close);
      await tester.pumpWidget(
        MaterialApp(
          home: AuthStateGate(
            authenticationState: FakeAuthenticationState(auth.stream),
            userRepository: FakeUserRepository(
              profiles: {'user-1': buildProfile(role: 'supervisor')},
            ),
            siteRepository: TestSiteRepository(),
            signedOutBuilder: (_) => const Scaffold(body: Text('SIGNED OUT')),
          ),
        ),
      );
      auth.add('user-1');
      await tester.pumpAndSettle();
      final context = tester.element(find.byType(SiteSelectionScreen));
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Text('PROTECTED REPORT')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('PROTECTED REPORT'), findsOneWidget);
      auth.add(null);
      await tester.pumpAndSettle();
      expect(find.text('PROTECTED REPORT'), findsNothing);
      expect(find.text('SIGNED OUT'), findsOneWidget);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('PROTECTED REPORT'), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'protected named route follows auth state through login and logout',
    (tester) async {
      final auth = FakeSessionAuthentication(
        StreamController<String?>.broadcast(sync: true),
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await auth.userIds.close();
      });

      final repository = FakeUserRepository(
        profiles: {
          'user-1': buildProfile(role: 'supervisor')
              .copyWith(assignedSiteIds: ['test-site']),
        },
      );

      Widget buildGate(BuildContext context) {
        return AuthStateGate(
          authenticationState: auth,
          userRepository: repository,
          userAuthentication: auth,
          siteRepository: TestSiteRepository(),
          supervisorBuilder: (_) => SiteSelectionScreen(
            authService: auth,
            sites: TestSiteRepository().watchAssignedSites(['test-site']),
          ),
          signedOutBuilder: (_) =>
              LoginScreen(authService: auth, navigateAfterSignIn: false),
        );
      }

      await tester.pumpWidget(
        MyApp(
          home: Builder(builder: buildGate),
          authStateGateBuilder: buildGate,
        ),
      );
      await tester.pump();
      auth.userIds.add(null);
      await tester.pumpAndSettle();

      Navigator.of(tester.element(find.byType(AuthStateGate)))
          .pushNamed('/sites');
      await tester.pump();
      auth.userIds.add(null);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SiteSelectionScreen), findsNothing);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'validPass123',
      );
      await tester.tap(find.byKey(const Key('loginButton')));
      await tester.pumpAndSettle();

      expect(auth.signInCallCount, 1);
      expect(find.byType(SiteSelectionScreen), findsOneWidget);

      await tester.tap(find.text('Open site').last);
      await tester.pumpAndSettle();
      expect(find.byType(AppNavigationShell), findsOneWidget);

      await tester.tap(find.text('More'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('logoutButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Log out'));
      await tester.pumpAndSettle();

      expect(auth.signOutCallCount, 1);
      expect(auth.userId, isNull);
      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SiteSelectionScreen), findsNothing);
      expect(find.byType(AppNavigationShell), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(SiteSelectionScreen), findsNothing);
      expect(find.byType(AppNavigationShell), findsNothing);
    },
  );
}

class TestSiteRepository implements SiteRepository {
  int allSitesCalls = 0;
  @override
  Stream<List<SiteModel>> watchAllSites() {
    allSitesCalls++;
    return watchAssignedSites([]);
  }

  @override
  Stream<List<SiteModel>> watchAssignedSites(List<String> ids) => Stream.value([
    SiteModel(
      id: 'test-site',
      name: 'Test site',
      location: 'Jaipur',
      status: 'active',
      expectedHeadcount: 0,
      createdAt: DateTime(2026),
    ),
  ]);
  @override
  Stream<List<SiteModel>> watchSitesForSupervisor(String id) =>
      watchAssignedSites([]);
}
