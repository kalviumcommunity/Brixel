import 'package:brixel/features/materials/screens/material_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
}
