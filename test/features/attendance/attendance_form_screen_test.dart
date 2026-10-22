import 'package:brixel/features/attendance/screens/attendance_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('attendance fields use appropriate keyboard actions', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AttendanceFormScreen()));

    final workerField = tester.widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Worker / Crew Name'),
        matching: find.byType(EditableText),
      ),
    );
    final tradeField = tester.widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Trade'),
        matching: find.byType(EditableText),
      ),
    );
    final hoursField = tester.widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Hours Worked'),
        matching: find.byType(EditableText),
      ),
    );

    expect(workerField.textInputAction, TextInputAction.next);
    expect(tradeField.textInputAction, TextInputAction.next);
    expect(
      hoursField.keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    expect(hoursField.textInputAction, TextInputAction.done);
    expect(hoursField.onSubmitted, isNotNull);
  });

  testWidgets('attendance form renders and can submit', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AttendanceFormScreen()));

    expect(find.text('Attendance Report'), findsOneWidget);
    expect(find.text('Worker / Crew Name'), findsOneWidget);
    expect(find.text('Trade'), findsOneWidget);
    expect(find.text('Attendance Status'), findsOneWidget);
    expect(find.text('Hours Worked'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Worker / Crew Name'),
      'Mason Crew',
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Trade'),
      'Masonry',
    );
    await tester.pump();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Present').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Hours Worked'),
      '8.5',
    );
    await tester.pump();

    await tester.tap(find.text('Submit Attendance'));
    await tester.pump();

    expect(find.text('Submit Attendance'), findsOneWidget);
  });

  testWidgets('attendance requires worker name, trade, and hours', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AttendanceFormScreen()));

    await tester.tap(find.text('Submit Attendance'));
    await tester.pump();

    expect(find.text('Please enter a worker or crew name.'), findsOneWidget);
    expect(find.text('Please enter the trade.'), findsOneWidget);
    expect(find.text('Please enter hours worked.'), findsOneWidget);
  });

  testWidgets('attendance hours must be numeric and within the allowed range', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AttendanceFormScreen()));

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Worker / Crew Name'),
      'Mason Crew',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Trade'),
      'Masonry',
    );

    final hoursField = find.widgetWithText(TextFormField, 'Hours Worked');
    for (final entry in {
      'abc': 'Please enter a valid number.',
      '0': 'Hours worked must be greater than 0 and at most 24.',
      '-1': 'Hours worked must be greater than 0 and at most 24.',
      '25': 'Hours worked must be greater than 0 and at most 24.',
    }.entries) {
      await tester.enterText(hoursField, entry.key);
      await tester.tap(find.text('Submit Attendance'));
      await tester.pump();
      expect(find.text(entry.value), findsOneWidget);
    }

    await tester.enterText(hoursField, '8');
    await tester.tap(find.text('Submit Attendance'));
    await tester.pump();

    expect(
      find.text('Attendance recorded locally for Mason Crew'),
      findsOneWidget,
    );
  });
}
