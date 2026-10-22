import 'package:brixel/features/auth/screens/sign_up_screen.dart';
import 'package:brixel/features/auth/services/user_registration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUserRegistration implements UserRegistration {
  int callCount = 0;

  String? submittedDisplayName;
  String? submittedEmail;
  String? submittedPassword;

  Object? errorToThrow;

  @override
  Future<void> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    callCount++;

    submittedDisplayName = displayName;
    submittedEmail = email;
    submittedPassword = password;

    if (errorToThrow != null) {
      throw errorToThrow!;
    }
  }
}

void main() {
  Widget buildTestApp(UserRegistration registration) {
    return MaterialApp(home: SignUpScreen(registrationService: registration));
  }

  testWidgets('signup uses email keyboard and obscures password fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildTestApp(FakeUserRegistration()));

    final fields = tester.widgetList<EditableText>(find.byType(EditableText));
    final fieldList = fields.toList();

    expect(fieldList[1].keyboardType, TextInputType.emailAddress);
    expect(fieldList[1].textInputAction, TextInputAction.next);
    expect(fieldList[2].obscureText, isTrue);
    expect(fieldList[2].textInputAction, TextInputAction.next);
    expect(fieldList[3].obscureText, isTrue);
    expect(fieldList[3].textInputAction, TextInputAction.done);
    expect(fieldList[3].onSubmitted, isNotNull);
  });

  testWidgets('shows validation errors and does not register invalid input', (
    WidgetTester tester,
  ) async {
    final registration = FakeUserRegistration();

    await tester.pumpWidget(buildTestApp(registration));

    await tester.tap(find.byKey(const Key('createAccountButton')));
    await tester.pump();

    expect(find.text('Enter your full name'), findsOneWidget);
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter a password'), findsOneWidget);

    expect(registration.callCount, 0);
  });

  testWidgets('rejects mismatched passwords', (WidgetTester tester) async {
    final registration = FakeUserRegistration();

    await tester.pumpWidget(buildTestApp(registration));

    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'Nimra Mittal');
    await tester.enterText(fields.at(1), 'nimra@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'different123');

    await tester.tap(find.byKey(const Key('createAccountButton')));
    await tester.pump();

    expect(find.text('Passwords do not match'), findsOneWidget);
    expect(registration.callCount, 0);
  });

  testWidgets('submits valid signup details through registration service', (
    WidgetTester tester,
  ) async {
    final registration = FakeUserRegistration();

    await tester.pumpWidget(buildTestApp(registration));

    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'Nimra Mittal');
    await tester.enterText(fields.at(1), 'nimra@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'password123');

    await tester.tap(find.byKey(const Key('createAccountButton')));
    await tester.pumpAndSettle();

    expect(registration.callCount, 1);
    expect(registration.submittedDisplayName, 'Nimra Mittal');
    expect(registration.submittedEmail, 'nimra@example.com');
    expect(registration.submittedPassword, 'password123');

    expect(
      find.text('Account created. Access will be available after approval.'),
      findsOneWidget,
    );
  });

  testWidgets('shows feedback when registration fails', (
    WidgetTester tester,
  ) async {
    final registration = FakeUserRegistration()
      ..errorToThrow = Exception('registration failed');

    await tester.pumpWidget(buildTestApp(registration));

    final fields = find.byType(TextFormField);

    await tester.enterText(fields.at(0), 'Nimra Mittal');
    await tester.enterText(fields.at(1), 'nimra@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'password123');

    await tester.tap(find.byKey(const Key('createAccountButton')));
    await tester.pumpAndSettle();

    expect(registration.callCount, 1);

    expect(find.textContaining('Unable to create account'), findsOneWidget);
  });
}
