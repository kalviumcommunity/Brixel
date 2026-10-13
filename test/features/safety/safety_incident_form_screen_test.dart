import 'package:brixel/features/safety/screens/safety_incident_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('safety form renders and captures details', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SafetyIncidentFormScreen()),
    );

    expect(find.text('Safety Incident Report'), findsOneWidget);
    expect(find.text('Location / Site Area'), findsOneWidget);
    expect(find.text('Incident Type'), findsOneWidget);
    expect(find.text('Severity'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Location / Site Area'),
      'Level 2 slab',
    );
    await tester.pump();

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fall').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<String>).at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('High').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Description'),
      'Worker slipped near temporary stair edge.',
    );
    await tester.pump();

    expect(find.text('Level 2 slab'), findsOneWidget);
    expect(
      find.text('Worker slipped near temporary stair edge.'),
      findsOneWidget,
    );
  });

  testWidgets('safety location and description are required', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SafetyIncidentFormScreen()),
    );

    await tester.tap(find.text('Submit Incident'));
    await tester.pump();

    expect(
      find.text('Please enter the location or site area.'),
      findsOneWidget,
    );
    expect(find.text('Please describe the incident.'), findsOneWidget);
  });

  testWidgets('safety description requires at least five characters', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: SafetyIncidentFormScreen()),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Location / Site Area'),
      'Level 2 slab',
    );
    final descriptionField = find.widgetWithText(TextFormField, 'Description');

    await tester.enterText(descriptionField, 'Slip');
    await tester.tap(find.text('Submit Incident'));
    await tester.pump();

    expect(
      find.text('Description must be at least 5 characters.'),
      findsOneWidget,
    );

    await tester.enterText(descriptionField, 'Valid incident description');
    await tester.drag(find.byType(ListView), const Offset(0, -250));
    await tester.pump();
    await tester.tap(find.text('Submit Incident'));
    await tester.pump();

    expect(
      find.text('Safety incident reported for Level 2 slab'),
      findsOneWidget,
    );
  });
}
