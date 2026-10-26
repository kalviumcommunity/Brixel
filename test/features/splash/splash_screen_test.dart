import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/splash/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestDestination extends StatelessWidget {
  const TestDestination({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('TEST DESTINATION')));
  }
}

void main() {
  Widget buildTestApp({
    Duration displayDuration = const Duration(milliseconds: 500),
  }) {
    return MaterialApp(
      theme: buildBrixelTheme(),
      home: SplashScreen(
        displayDuration: displayDuration,
        destinationBuilder: (_) => const TestDestination(),
      ),
    );
  }

  testWidgets('shows Brixel branding immediately', (tester) async {
    await tester.pumpWidget(buildTestApp());

    expect(find.byKey(const Key('splashLogo')), findsOneWidget);

    expect(find.byKey(const Key('splashTitle')), findsOneWidget);

    expect(find.text('Brixel'), findsOneWidget);

    expect(
      find.text('Construction site reporting, kept current.'),
      findsOneWidget,
    );

    expect(find.byKey(const Key('splashProgress')), findsOneWidget);

    expect(find.text('TEST DESTINATION'), findsNothing);
  });

  testWidgets('does not navigate before display duration completes', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(displayDuration: const Duration(seconds: 2)),
    );

    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(SplashScreen), findsOneWidget);

    expect(find.text('TEST DESTINATION'), findsNothing);
  });

  testWidgets('navigates to destination after display duration', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(displayDuration: const Duration(milliseconds: 100)),
    );

    await tester.pump(const Duration(milliseconds: 100));

    await tester.pumpAndSettle();

    expect(find.text('TEST DESTINATION'), findsOneWidget);

    expect(find.byType(SplashScreen), findsNothing);
  });

  testWidgets('cancels startup timer when splash screen is disposed', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestApp(displayDuration: const Duration(seconds: 2)),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('REPLACED SCREEN'))),
    );

    await tester.pump(const Duration(seconds: 3));

    expect(find.text('REPLACED SCREEN'), findsOneWidget);

    expect(find.text('TEST DESTINATION'), findsNothing);

    expect(tester.takeException(), isNull);
  });
}
