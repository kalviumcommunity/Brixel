import 'package:brixel/shared/widgets/brixel_metric_card.dart';
import 'package:brixel/shared/widgets/brixel_primary_button.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:brixel/shared/widgets/brixel_section_title.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrixelMetricCard', () {
    testWidgets('renders title, value, subtitle and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrixelMetricCard(
              title: 'Attendance',
              value: '56 / 62',
              subtitle: 'present today',
              icon: Icons.people_outline,
            ),
          ),
        ),
      );

      expect(find.text('Attendance'), findsOneWidget);
      expect(find.text('56 / 62'), findsOneWidget);
      expect(find.text('present today'), findsOneWidget);
      expect(find.byIcon(Icons.people_outline), findsOneWidget);
    });

    testWidgets('works with different metric values', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrixelMetricCard(
              title: 'Materials',
              value: '12',
              subtitle: 'low stock',
              icon: Icons.inventory_2_outlined,
            ),
          ),
        ),
      );

      expect(find.text('Materials'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('low stock'), findsOneWidget);
    });
  });

  group('BrixelSectionCard', () {
    testWidgets('renders the provided child content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BrixelSectionCard(child: Text('Section body'))),
        ),
      );

      expect(find.text('Section body'), findsOneWidget);
    });
  });

  group('BrixelPrimaryButton', () {
    testWidgets('renders label and optional icon', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrixelPrimaryButton(
              label: 'Add Material',
              icon: Icons.add,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.text('Add Material'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    testWidgets('triggers callback when tapped', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrixelPrimaryButton(
              label: 'Submit Report',
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Submit Report'));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('does not crash when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrixelPrimaryButton(
              label: 'Disabled Action',
              onPressed: null,
            ),
          ),
        ),
      );

      expect(find.text('Disabled Action'), findsOneWidget);
      await tester.tap(find.text('Disabled Action'));
      await tester.pump();
    });
  });

  group('BrixelSectionTitle', () {
    testWidgets('renders title and subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrixelSectionTitle(
              title: 'Materials',
              subtitle: 'Track material usage',
            ),
          ),
        ),
      );

      expect(find.text('Materials'), findsOneWidget);
      expect(find.text('Track material usage'), findsOneWidget);
    });

    testWidgets('renders title without subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: BrixelSectionTitle(title: 'Safety')),
        ),
      );

      expect(find.text('Safety'), findsOneWidget);
      expect(find.textContaining('Track'), findsNothing);
    });
  });
}
