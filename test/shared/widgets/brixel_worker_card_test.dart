import 'package:brixel/shared/widgets/brixel_worker_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BrixelWorkerCard', () {
    testWidgets('renders worker name, role, worker ID, and default status',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrixelWorkerCard(
              name: 'Ramesh Kumar',
              role: 'Mason',
              workerId: 'W-001',
            ),
          ),
        ),
      );

      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('W-001 • Mason'), findsOneWidget);
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('RK'), findsOneWidget); // initials
    });

    testWidgets('renders custom status and initials correctly',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BrixelWorkerCard(
              name: 'Imran Shaikh',
              role: 'Electrician',
              workerId: 'W-003',
              status: 'Absent',
            ),
          ),
        ),
      );

      expect(find.text('Imran Shaikh'), findsOneWidget);
      expect(find.text('W-003 • Electrician'), findsOneWidget);
      expect(find.text('Absent'), findsOneWidget);
      expect(find.text('IS'), findsOneWidget);
    });

    testWidgets('triggers onTap callback when pressed', (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BrixelWorkerCard(
              name: 'Suresh Yadav',
              role: 'Helper',
              workerId: 'W-002',
              onTap: () {
                tapped = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byType(BrixelWorkerCard));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('reusable with different workers in a list', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                BrixelWorkerCard(
                  name: 'Pooja Singh',
                  role: 'Supervisor',
                  workerId: 'W-004',
                  status: 'Present',
                ),
                BrixelWorkerCard(
                  name: 'Vikram Patel',
                  role: 'Mason',
                  workerId: 'W-005',
                  status: 'On-Site',
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Pooja Singh'), findsOneWidget);
      expect(find.text('W-004 • Supervisor'), findsOneWidget);
      expect(find.text('Vikram Patel'), findsOneWidget);
      expect(find.text('W-005 • Mason'), findsOneWidget);
      expect(find.text('Present'), findsOneWidget);
      expect(find.text('On-Site'), findsOneWidget);
    });
  });
}
