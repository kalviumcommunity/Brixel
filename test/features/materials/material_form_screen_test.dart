import 'package:brixel/features/materials/screens/material_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('material fields use numeric and multiline input settings', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MaterialFormScreen()));

    final quantityField = tester.widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Quantity'),
        matching: find.byType(EditableText),
      ),
    );
    final notesField = tester.widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Notes (optional)'),
        matching: find.byType(EditableText),
      ),
    );

    expect(
      quantityField.keyboardType,
      const TextInputType.numberWithOptions(decimal: true),
    );
    expect(quantityField.textInputAction, TextInputAction.next);
    expect(notesField.keyboardType, TextInputType.multiline);
    expect(notesField.textInputAction, TextInputAction.newline);
    expect(notesField.maxLines, 5);
  });

  testWidgets('material form renders expected fields and accepts notes', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MaterialFormScreen()));

    expect(find.text('Material Usage Report'), findsOneWidget);
    expect(find.text('Material Name'), findsOneWidget);
    expect(find.text('Quantity'), findsOneWidget);
    expect(find.text('Unit'), findsOneWidget);
    expect(find.text('Notes (optional)'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Material Name'),
      'Cement',
    );
    await tester.pump();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantity'),
      '18',
    );
    await tester.pump();

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('bags').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Notes (optional)'),
      'Used for slab work',
    );
    await tester.pump();

    expect(find.text('Cement'), findsOneWidget);
    expect(find.text('Used for slab work'), findsOneWidget);
  });

  testWidgets('material name and quantity are required', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MaterialFormScreen()));

    await tester.tap(find.text('Submit Material Usage'));
    await tester.pump();

    expect(find.text('Please enter the material name.'), findsOneWidget);
    expect(find.text('Please enter the quantity.'), findsOneWidget);
  });

  testWidgets('quantity must be numeric and greater than zero', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MaterialFormScreen()));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Material Name'),
      'Cement',
    );

    final quantityField = find.widgetWithText(TextFormField, 'Quantity');
    for (final entry in {
      'abc': 'Please enter a valid number.',
      '0': 'Quantity must be greater than zero.',
      '-1': 'Quantity must be greater than zero.',
    }.entries) {
      await tester.enterText(quantityField, entry.key);
      await tester.tap(find.text('Submit Material Usage'));
      await tester.pump();
      expect(find.text(entry.value), findsOneWidget);
    }

    await tester.enterText(quantityField, '35');
    await tester.tap(find.text('Submit Material Usage'));
    await tester.pump();

    expect(
      find.text('Material usage saving is not configured for this app.'),
      findsOneWidget,
    );
  });

  testWidgets('material notes are optional', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: MaterialFormScreen()));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Material Name'),
      'Cement',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Quantity'),
      '35',
    );

    await tester.tap(find.text('Submit Material Usage'));
    await tester.pump();

    expect(
      find.text('Material usage saving is not configured for this app.'),
      findsOneWidget,
    );
  });
}
