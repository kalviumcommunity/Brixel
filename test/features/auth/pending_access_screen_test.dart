import 'dart:async';

import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/auth/models/user_model.dart';
import 'package:brixel/features/auth/repositories/user_repository.dart';
import 'package:brixel/features/auth/screens/auth_state_gate.dart';
import 'package:brixel/features/auth/screens/pending_access_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'auth_state_gate_test.dart'
    show FakeSessionAuthentication, TestSiteRepository;

import 'package:brixel/features/sites/screens/site_selection_screen.dart';

UserModel profile(String role, {String email = 'person@example.com'}) =>
    UserModel(
      uid: 'user-1',
      email: email,
      displayName: 'Person',
      role: role,
      assignedSiteIds: ['test-site'],
      createdAt: DateTime(2026),
    );

class Profiles implements UserRepository {
  final controller = StreamController<UserModel?>();
  int reads = 0;
  @override
  Stream<UserModel?> watchUserProfile(String uid) {
    reads++;
    return controller.stream;
  }
}

void main() {
  testWidgets('explains success, identity, approval and next steps', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBrixelTheme(),
        home: PendingAccessScreen(profile: profile('pending')),
      ),
    );
    expect(find.text('Account created successfully'), findsOneWidget);
    expect(find.text('Your Brixel account is ready'), findsOneWidget);
    expect(find.text('Access approval is pending'), findsOneWidget);
    expect(
      find.textContaining("You're signed in successfully."),
      findsOneWidget,
    );
    expect(find.text('person@example.com'), findsOneWidget);
    expect(find.text('What happens next'), findsOneWidget);
    expect(find.byKey(const Key('logoutButton')), findsOneWidget);
    expect(find.text('Refresh'), findsNothing);
  });
  testWidgets('omits empty account information', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PendingAccessScreen(profile: profile('pending', email: '')),
      ),
    );
    expect(find.text('Signed in as'), findsNothing);
  });
  for (final width in [320.0, 360.0, 390.0, 412.0]) {
    testWidgets('fits $width with large text and reachable logout', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 640);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildBrixelTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: PendingAccessScreen(
            profile: profile(
              'pending',
              email: 'very.long.account.address.for.testing@example.com',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('logoutButton')));
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('logoutButton')).hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
  for (final role in ['supervisor', 'manager']) {
    testWidgets('streamed pending to $role opens sites without new login', (
      tester,
    ) async {
      final auth = FakeSessionAuthentication(
        StreamController<String?>.broadcast(),
      );
      final profiles = Profiles();
      await tester.pumpWidget(
        MaterialApp(
          home: AuthStateGate(
            authenticationState: auth,
            userAuthentication: auth,
            userRepository: profiles,
            siteRepository: TestSiteRepository(),
          ),
        ),
      );
      auth.userIds.add('user-1');
      await tester.pump();
      await tester.pump();
      profiles.controller.add(profile('pending'));
      await tester.pumpAndSettle();
      expect(find.byType(PendingAccessScreen), findsOneWidget);
      expect(find.text('person@example.com'), findsOneWidget);
      profiles.controller.add(profile(role));
      await tester.pumpAndSettle();
      expect(find.byType(PendingAccessScreen), findsNothing);
      expect(find.byType(SiteSelectionScreen), findsOneWidget);
      expect(profiles.reads, 1);
      expect(auth.signInCallCount, 0);
      await tester.pumpWidget(const SizedBox());
      unawaited(profiles.controller.close());
      unawaited(auth.userIds.close());
    });
  }
  testWidgets('pending logout returns through the auth stream', (tester) async {
    final auth = FakeSessionAuthentication(
      StreamController<String?>.broadcast(),
    );
    final profiles = Profiles();
    await tester.pumpWidget(
      MaterialApp(
        home: AuthStateGate(
          authenticationState: auth,
          userAuthentication: auth,
          userRepository: profiles,
        ),
      ),
    );
    auth.userIds.add('user-1');
    await tester.pump();
    await tester.pump();
    profiles.controller.add(profile('pending'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('logoutButton')));
    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();
    expect(auth.signOutCallCount, 1);
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(find.byType(PendingAccessScreen), findsNothing);
    await tester.pumpWidget(const SizedBox());
    unawaited(profiles.controller.close());
    unawaited(auth.userIds.close());
  });
}
