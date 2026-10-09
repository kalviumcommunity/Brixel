import 'package:brixel/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('selected site is preserved across bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('Select a site'), findsOneWidget);
    expect(find.text('Jaipur Residential Project'), findsOneWidget);
    expect(find.text('Ajmer Commercial Project'), findsOneWidget);

    // Open the first site.
    await tester.tap(find.text('Open site').first);
    await tester.pumpAndSettle();

    expect(find.text('Site overview'), findsOneWidget);
    expect(find.text('Jaipur Residential Project'), findsWidgets);

    // Open Attendance from the bottom navigation bar.
    final attendanceTab = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Attendance'),
    );

    expect(attendanceTab, findsOneWidget);

    await tester.tap(attendanceTab);
    await tester.pumpAndSettle();

    expect(find.text('Jaipur Residential Project'), findsOneWidget);
    expect(
      find.textContaining(
        'Attendance reporting for Jaipur Residential Project',
      ),
      findsOneWidget,
    );

    // Return to site selection.
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Select a site'), findsOneWidget);

    // Open the second site.
    await tester.tap(find.text('Open site').last);
    await tester.pumpAndSettle();

    final safetyTab = find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Safety'),
    );

    expect(safetyTab, findsOneWidget);

    await tester.tap(safetyTab);
    await tester.pumpAndSettle();

    expect(find.text('Ajmer Commercial Project'), findsOneWidget);
    expect(
      find.textContaining('Safety reporting for Ajmer Commercial Project'),
      findsOneWidget,
    );
  });
}
