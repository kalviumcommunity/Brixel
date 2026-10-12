import 'package:brixel/features/attendance/screens/attendance_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
