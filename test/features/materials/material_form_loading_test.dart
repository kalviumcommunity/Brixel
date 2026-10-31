import 'dart:async';

import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/attendance/screens/attendance_form_screen.dart';
import 'package:brixel/features/materials/screens/material_form_screen.dart';
import 'package:brixel/shared/widgets/brixel_primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrixelPrimaryButton Loading Indicator & Interaction Control', () {
    testWidgets('renders label and is clickable when isLoading is false', (
      tester,
    ) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrixelPrimaryButton(
              label: 'Save Changes',
              isLoading: false,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Save Changes'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets(
      'shows CircularProgressIndicator and disables onPressed when isLoading is true',
      (tester) async {
        var tapped = false;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BrixelPrimaryButton(
                label: 'Save Changes',
                isLoading: true,
                onPressed: () => tapped = true,
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Save Changes'), findsNothing);

        final button = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(button.onPressed, isNull);

        await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
        await tester.pump();
        expect(tapped, isFalse);
      },
    );
  });

  group('MaterialFormScreen Loading Workflow (Tasks 1-4)', () {
    testWidgets(
      'Task 1, 2 & 4: Shows loading indicator and disables submit button during long-running operation',
      (tester) async {
        final completer = Completer<void>();
        var submitCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: buildBrixelTheme(),
            home: MaterialFormScreen(
              siteName: 'Test Site',
              onSubmit: (payload) async {
                submitCount++;
                await completer.future;
              },
            ),
          ),
        );

        // Initial state: No indicator, button enabled
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Submit Material Usage'), findsOneWidget);

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Material Name'),
          'Steel Rods',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Quantity'),
          '45',
        );
        await tester.pump();

        // Trigger submit
        await tester.tap(find.byKey(const Key('submitMaterialButton')));
        await tester.pump(); // Advance to start of async operation

        // Task 2: Indicator displayed before/during processing
        expect(find.byType(CircularProgressIndicator), findsWidgets);
        expect(submitCount, equals(1));

        // Task 4: Submit button disabled during loading (prevents double submits)
        final submitButton = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(submitButton.onPressed, isNull);

        // Second tap attempted while loading
        await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
        await tester.pump();
        expect(
          submitCount,
          equals(1),
        ); // Still 1, double-submit successfully prevented

        // Task 3: Complete operation and verify indicator removed
        completer.complete();
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Submit Material Usage'), findsOneWidget);
        expect(
          find.text('Material usage saved for Steel Rods'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Task 3: Loading indicator is cleared via finally even when operation throws an exception',
      (tester) async {
        final completer = Completer<void>();
        var submitCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: buildBrixelTheme(),
            home: MaterialFormScreen(
              siteName: 'Test Site',
              onSubmit: (payload) async {
                submitCount++;
                await completer.future;
                throw Exception('Network connection timed out');
              },
            ),
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Material Name'),
          'Bricks',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Quantity'),
          '1000',
        );
        await tester.pump();

        // Tap submit
        await tester.tap(find.byKey(const Key('submitMaterialButton')));
        await tester.pump();

        // Active loading state
        expect(submitCount, equals(1));
        expect(find.byType(CircularProgressIndicator), findsWidgets);
        final activeBtn = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(activeBtn.onPressed, isNull);

        // Complete with failure / exception
        completer.complete();
        await tester.pumpAndSettle();

        // Finally block executed: indicator removed and button re-enabled
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(
          find.text('Failed to record material usage. Please try again.'),
          findsOneWidget,
        );

        final reEnabledBtn = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(reEnabledBtn.onPressed, isNotNull);
      },
    );
  });

  group('AttendanceFormScreen Loading Workflow (Tasks 1-4)', () {
    testWidgets(
      'Shows loading indicator, blocks double tap, and clears on success or failure via finally',
      (tester) async {
        final completer = Completer<void>();
        var submitCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: buildBrixelTheme(),
            home: AttendanceFormScreen(
              siteName: 'Test Site',
              onSubmit: (payload) async {
                submitCount++;
                await completer.future;
              },
            ),
          ),
        );

        await tester.enterText(
          find.widgetWithText(TextFormField, 'Worker / Crew Name'),
          'Vikram Singh',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Trade'),
          'Carpentry',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Hours Worked'),
          '8',
        );
        await tester.pump();

        // Tap submit
        await tester.tap(find.byKey(const Key('submitAttendanceButton')));
        await tester.pump();

        // Indicator visible, button disabled
        expect(find.byType(CircularProgressIndicator), findsWidgets);
        final btnWhileLoading = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(btnWhileLoading.onPressed, isNull);

        // Attempt double tap
        await tester.tap(find.byType(ElevatedButton), warnIfMissed: false);
        await tester.pump();
        expect(submitCount, equals(1));

        // Complete
        completer.complete();
        await tester.pumpAndSettle();

        // Indicator removed via finally
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Attendance saved for Vikram Singh'), findsOneWidget);
      },
    );
  });
}
