import 'dart:async';

import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/auth/services/user_authentication.dart';
import 'package:brixel/features/auth/widgets/logout_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUserAuthentication implements UserAuthentication {
  int signOutCallCount = 0;
  Object? signOutError;
  Completer<void>? signOutCompleter;

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> signOut() async {
    signOutCallCount++;
    if (signOutError != null) throw signOutError!;
    await signOutCompleter?.future;
  }
}

void main() {
  Widget buildTestApp(
    UserAuthentication authService, {
    WidgetBuilder? destinationBuilder,
  }) {
    return MaterialApp(
      theme: buildBrixelTheme(),
      home: Scaffold(
        body: Column(
          children: [
            const Text('Authenticated content'),
            LogoutButton(
              authService: authService,
              destinationBuilder: destinationBuilder,
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('signs out once and clears authenticated routes', (
    WidgetTester tester,
  ) async {
    final auth = FakeUserAuthentication();

    await tester.pumpWidget(
      buildTestApp(
        auth,
        destinationBuilder: (_) =>
            const Scaffold(body: Text('Login destination')),
      ),
    );

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pumpAndSettle();

    expect(auth.signOutCallCount, 1);
    expect(find.text('Login destination'), findsOneWidget);
    expect(find.text('Authenticated content'), findsNothing);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Login destination'), findsOneWidget);
    expect(find.text('Authenticated content'), findsNothing);
  });

  testWidgets('shows safe error and stays on authenticated route on failure', (
    WidgetTester tester,
  ) async {
    final auth = FakeUserAuthentication()
      ..signOutError = Exception('private Firebase error details');

    await tester.pumpWidget(
      buildTestApp(
        auth,
        destinationBuilder: (_) =>
            const Scaffold(body: Text('Login destination')),
      ),
    );

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pump();

    expect(auth.signOutCallCount, 1);
    expect(find.text('Could not log out. Please try again.'), findsOneWidget);
    expect(find.text('private Firebase error details'), findsNothing);
    expect(find.text('Authenticated content'), findsOneWidget);
    expect(find.text('Login destination'), findsNothing);
  });

  testWidgets('disables repeated taps while sign out is pending', (
    WidgetTester tester,
  ) async {
    final auth = FakeUserAuthentication()..signOutCompleter = Completer<void>();

    await tester.pumpWidget(
      buildTestApp(
        auth,
        destinationBuilder: (_) =>
            const Scaffold(body: Text('Login destination')),
      ),
    );

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pump();
    expect(find.text('Logging out...'), findsOneWidget);

    await tester.tap(find.byKey(const Key('logoutButton')));
    await tester.pump();
    expect(auth.signOutCallCount, 1);

    auth.signOutCompleter!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Login destination'), findsOneWidget);
  });
}
