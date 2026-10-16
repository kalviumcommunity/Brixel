import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/auth/screens/login_screen.dart';
import 'package:brixel/features/auth/screens/sign_up_screen.dart';
import 'package:brixel/features/auth/services/user_authentication.dart';
import 'package:brixel/features/auth/services/user_registration.dart';
import 'package:brixel/features/sites/screens/site_selection_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUserAuthentication implements UserAuthentication {
  int callCount = 0;
  String? submittedEmail;
  String? submittedPassword;
  Object? errorToThrow;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signIn({required String email, required String password}) async {
    callCount++;
    submittedEmail = email;
    submittedPassword = password;

    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }
}

void main() {
  Widget buildTestApp(UserAuthentication authService) {
    return MaterialApp(
      theme: buildBrixelTheme(),
      home: LoginScreen(authService: authService),
    );
  }

  group('LoginScreen Form Validation', () {
    testWidgets(
      'shows validation errors for empty fields and does not sign in',
      (WidgetTester tester) async {
        final auth = FakeUserAuthentication();

        await tester.pumpWidget(buildTestApp(auth));

        await tester.tap(find.byKey(const Key('loginButton')));

        await tester.pump();

        expect(find.text('Enter your email'), findsOneWidget);

        expect(find.text('Enter your password'), findsOneWidget);

        expect(auth.callCount, 0);
      },
    );

    testWidgets('validates email format and password length', (
      WidgetTester tester,
    ) async {
      final auth = FakeUserAuthentication();

      await tester.pumpWidget(buildTestApp(auth));

      final emailField = find.widgetWithText(TextFormField, 'Email');

      final passwordField = find.widgetWithText(TextFormField, 'Password');

      await tester.enterText(emailField, 'notanemail');

      await tester.enterText(passwordField, '123');

      await tester.pump();

      await tester.tap(find.byKey(const Key('loginButton')));

      await tester.pump();

      expect(find.text('Enter a valid email address'), findsOneWidget);

      expect(
        find.text('Password must contain at least 6 characters'),
        findsOneWidget,
      );

      expect(auth.callCount, 0);
    });
  });

  group('LoginScreen Invalid Attempt Error Handling', () {
    testWidgets(
      'handles wrong-password and invalid-credential with safe message',
      (WidgetTester tester) async {
        final auth = FakeUserAuthentication()
          ..errorToThrow = FirebaseAuthException(code: 'wrong-password');

        await tester.pumpWidget(buildTestApp(auth));

        final emailField = find.widgetWithText(TextFormField, 'Email');

        final passwordField = find.widgetWithText(TextFormField, 'Password');

        await tester.enterText(emailField, 'arjun@brixel.app');

        await tester.enterText(passwordField, 'wrongPass123');

        await tester.pump();

        await tester.tap(find.byKey(const Key('loginButton')));

        await tester.pump();

        expect(find.text('Incorrect email or password.'), findsOneWidget);

        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));

        expect(snackBar.backgroundColor, BrixelColors.danger);

        expect(auth.callCount, 1);
      },
    );

    testWidgets('handles user-not-found code with combined safe message', (
      WidgetTester tester,
    ) async {
      final auth = FakeUserAuthentication()
        ..errorToThrow = FirebaseAuthException(code: 'user-not-found');

      await tester.pumpWidget(buildTestApp(auth));

      final emailField = find.widgetWithText(TextFormField, 'Email');

      final passwordField = find.widgetWithText(TextFormField, 'Password');

      await tester.enterText(emailField, 'unknown@brixel.app');

      await tester.enterText(passwordField, 'secretPass123');

      await tester.pump();

      await tester.tap(find.byKey(const Key('loginButton')));

      await tester.pump();

      expect(find.text('Incorrect email or password.'), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));

      expect(snackBar.backgroundColor, BrixelColors.danger);
    });

    testWidgets('handles too-many-requests code with rate-limit message', (
      WidgetTester tester,
    ) async {
      final auth = FakeUserAuthentication()
        ..errorToThrow = FirebaseAuthException(code: 'too-many-requests');

      await tester.pumpWidget(buildTestApp(auth));

      final emailField = find.widgetWithText(TextFormField, 'Email');

      final passwordField = find.widgetWithText(TextFormField, 'Password');

      await tester.enterText(emailField, 'arjun@brixel.app');

      await tester.enterText(passwordField, 'secretPass123');

      await tester.pump();

      await tester.tap(find.byKey(const Key('loginButton')));

      await tester.pump();

      expect(find.text('Too many attempts. Try again later.'), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));

      expect(snackBar.backgroundColor, BrixelColors.danger);
    });

    testWidgets('handles generic exceptions with fallback message', (
      WidgetTester tester,
    ) async {
      final auth = FakeUserAuthentication()
        ..errorToThrow = Exception('Network error');

      await tester.pumpWidget(buildTestApp(auth));

      final emailField = find.widgetWithText(TextFormField, 'Email');

      final passwordField = find.widgetWithText(TextFormField, 'Password');

      await tester.enterText(emailField, 'arjun@brixel.app');

      await tester.enterText(passwordField, 'secretPass123');

      await tester.pump();

      await tester.tap(find.byKey(const Key('loginButton')));

      await tester.pump();

      expect(find.text('Login failed. Please try again.'), findsOneWidget);

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));

      expect(snackBar.backgroundColor, BrixelColors.danger);
    });
  });

  group('LoginScreen Success & Navigation', () {
    testWidgets(
      'redirects on success using pushReplacement to SiteSelectionScreen',
      (WidgetTester tester) async {
        final auth = FakeUserAuthentication();

        await tester.pumpWidget(buildTestApp(auth));

        final emailField = find.widgetWithText(TextFormField, 'Email');

        final passwordField = find.widgetWithText(TextFormField, 'Password');

        await tester.enterText(emailField, 'meera@brixel.app');

        await tester.enterText(passwordField, 'validPass123');

        await tester.pump();

        await tester.tap(find.byKey(const Key('loginButton')));

        await tester.pumpAndSettle();

        expect(auth.callCount, 1);

        expect(auth.submittedEmail, 'meera@brixel.app');

        expect(auth.submittedPassword, 'validPass123');

        expect(find.byType(SiteSelectionScreen), findsOneWidget);

        expect(find.byType(LoginScreen), findsNothing);

        expect(find.text('Select a site'), findsOneWidget);
      },
    );

    testWidgets('navigates to SignUpScreen from link', (
      WidgetTester tester,
    ) async {
      final auth = FakeUserAuthentication();

      await tester.pumpWidget(
        MaterialApp(
          theme: buildBrixelTheme(),
          home: LoginScreen(
            authService: auth,
            signUpScreenBuilder: (_) =>
                SignUpScreen(registrationService: _FakeUserRegistration()),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('goToSignUpButton')));

      await tester.pumpAndSettle();

      expect(find.byType(SignUpScreen), findsOneWidget);

      expect(find.text('Join Brixel'), findsOneWidget);
    });

    testWidgets('can defer successful login routing to auth state gate', (
      WidgetTester tester,
    ) async {
      final auth = FakeUserAuthentication();

      await tester.pumpWidget(
        MaterialApp(
          theme: buildBrixelTheme(),
          home: LoginScreen(authService: auth, navigateAfterSignIn: false),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'meera@brixel.app',
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Password'),
        'validPass123',
      );

      await tester.tap(find.byKey(const Key('loginButton')));

      await tester.pumpAndSettle();

      expect(auth.callCount, 1);

      expect(find.byType(LoginScreen), findsOneWidget);

      expect(find.byType(SiteSelectionScreen), findsNothing);
    });
  });
}

class _FakeUserRegistration implements UserRegistration {
  @override
  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {}
}
