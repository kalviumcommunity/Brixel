import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/attendance/screens/attendance_form_screen.dart';
import 'package:brixel/features/materials/screens/material_form_screen.dart';
import 'package:brixel/features/safety/screens/safety_incident_form_screen.dart';
import 'package:brixel/shared/widgets/brixel_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceFormScreen validation', () {
    testWidgets(
      'shows a numeric field error and submits after valid hours are entered',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildBrixelTheme(),
            home: const AttendanceFormScreen(siteName: 'Jaipur Site'),
          ),
        );

        // Fill required text fields
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Worker / Crew Name'),
          'Ramesh Kumar',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Trade'),
          'Masonry',
        );

        // Invalid numeric input is rejected by the field validator.
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Hours Worked'),
          '12a',
        );
        await tester.pump();

        // Submit form
        await tester.tap(find.byType(BrixelPrimaryButton));
        await tester.pump();

        expect(find.text('Please enter a valid number.'), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);

        // Clear snackbar and demonstrate execution continuation with valid input
        ScaffoldMessenger.of(tester.element(find.byType(AttendanceFormScreen)))
            .clearSnackBars();
        await tester.pump();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Hours Worked'),
          '8.5',
        );
        await tester.pump();

        await tester.tap(find.byType(BrixelPrimaryButton));
        await tester.pump();

        expect(
          find.text('Attendance recorded locally for Ramesh Kumar'),
          findsOneWidget,
        );
        final successSnackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(successSnackBar.backgroundColor, BrixelColors.success);
      },
    );

    testWidgets('shows a field error when hours worked exceeds the limit', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildBrixelTheme(),
          home: const AttendanceFormScreen(),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Worker / Crew Name'),
        'Suresh Yadav',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Trade'),
        'Helper',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Hours Worked'),
        '28',
      );
      await tester.pump();

      await tester.tap(find.byType(BrixelPrimaryButton));
      await tester.pump();

      expect(
        find.text('Hours worked must be greater than 0 and at most 24.'),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('MaterialFormScreen validation', () {
    testWidgets(
      'shows a numeric field error and submits after valid quantity is entered',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildBrixelTheme(),
            home: const MaterialFormScreen(siteName: 'Ajmer Commercial Site'),
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Material Name'),
          'OPC Cement',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Quantity'),
          'not_a_number',
        );
        await tester.pump();

        await tester.tap(find.byType(BrixelPrimaryButton));
        await tester.pump();

        expect(find.text('Please enter a valid number.'), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);

        // Clear snackbar and correct the quantity
        ScaffoldMessenger.of(tester.element(find.byType(MaterialFormScreen)))
            .clearSnackBars();
        await tester.pump();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Quantity'),
          '50',
        );
        await tester.pump();

        await tester.tap(find.byType(BrixelPrimaryButton));
        await tester.pump();

        expect(
          find.text('Material usage recorded locally for OPC Cement'),
          findsOneWidget,
        );
        final successSnackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(successSnackBar.backgroundColor, BrixelColors.success);
      },
    );

    testWidgets('shows a field error when quantity is zero or negative', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildBrixelTheme(),
          home: const MaterialFormScreen(),
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Material Name'),
        'Sand',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Quantity'),
        '0',
      );
      await tester.pump();

      await tester.tap(find.byType(BrixelPrimaryButton));
      await tester.pump();

      expect(
        find.textContaining('Quantity must be greater than zero'),
        findsOneWidget,
      );
      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('SafetyIncidentFormScreen validation', () {
    testWidgets(
      'shows a description field error and accepts a valid description',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildBrixelTheme(),
            home: const SafetyIncidentFormScreen(),
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Location / Site Area'),
          'Tower B Level 3',
        );
        // Too short description (< 5 characters)
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Description'),
          'Slip',
        );
        await tester.pump();

        await tester.drag(find.byType(ListView), const Offset(0, -250));
        await tester.pump();

        await tester.tap(find.byType(BrixelPrimaryButton));
        await tester.pump();

        expect(
          find.textContaining('Description must be at least 5 characters.'),
          findsOneWidget,
        );
        expect(find.byType(SnackBar), findsNothing);

        // Clear snackbar and fix description
        ScaffoldMessenger.of(
          tester.element(find.byType(SafetyIncidentFormScreen)),
        ).clearSnackBars();
        await tester.pump();

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Description'),
          'Worker slipped on wet footing near water outlet.',
        );
        await tester.pump();

        await tester.tap(find.byType(BrixelPrimaryButton));
        await tester.pump();

        expect(
          find.text('Safety incident reported for Tower B Level 3'),
          findsOneWidget,
        );
        final successSnackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(successSnackBar.backgroundColor, BrixelColors.success);
      },
    );
  });
}
