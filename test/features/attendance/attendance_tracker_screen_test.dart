import 'package:brixel/features/attendance/screens/attendance_tracker_screen.dart';
import 'package:brixel/shared/widgets/brixel_worker_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildTestApp({
    List<WorkerAttendanceItem>? workers,
    DateTime? initialDate,
    String? siteName,
  }) {
    return MaterialApp(
      home: AttendanceTrackerScreen(
        initialWorkers: workers,
        initialDate: initialDate,
        siteName: siteName,
      ),
    );
  }

  Finder workerStatusChip(String status) {
    return find.descendant(
      of: find.byType(BrixelWorkerCard),
      matching: find.text(status),
    );
  }

  group('AttendanceTrackerScreen - Basic State Management', () {
    testWidgets('renders initial state with workers, counts, and date', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        buildTestApp(
          siteName: 'Jaipur Residential Project',
          initialDate: DateTime(2026, 10, 6),
        ),
      );

      // Verify site title and date header
      expect(
        find.text('Jaipur Residential Project Attendance'),
        findsOneWidget,
      );
      expect(find.text('Tue, 6 Oct 2026'), findsOneWidget);

      // Verify metric counters (5 workers initially present by default)
      expect(find.text('Total Crew'), findsOneWidget);
      expect(find.text('5'), findsNWidgets(2)); // Total 5 and Present 5
      expect(find.text('0'), findsOneWidget); // Absent 0

      // Verify filter tabs
      expect(find.text('All (5)'), findsOneWidget);
      expect(find.text('On-Site (5)'), findsOneWidget);
      expect(find.text('Absent (0)'), findsOneWidget);

      // Verify worker cards
      expect(find.text('Ramesh Kumar'), findsOneWidget);
      expect(find.text('Suresh Yadav'), findsOneWidget);
      expect(find.text('Imran Shaikh'), findsOneWidget);
      expect(find.text('Pooja Singh'), findsOneWidget);
      expect(find.text('Vikram Patel'), findsOneWidget);
    });

    testWidgets(
      'toggles worker status inside setState() and reflects changes immediately',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestApp());

        // Initially Ramesh Kumar is Present (all 5 cards have Present chips)
        expect(workerStatusChip('Present'), findsNWidgets(5));
        expect(workerStatusChip('Absent'), findsNothing);

        // Tap Ramesh Kumar's card to toggle status
        final rameshCard = find.byKey(const Key('workerCard_W-001'));
        expect(rameshCard, findsOneWidget);
        await tester.tap(rameshCard);
        await tester.pump();

        // Status chip on the card should immediately flip to Absent
        expect(workerStatusChip('Absent'), findsOneWidget);
        expect(workerStatusChip('Present'), findsNWidgets(4));

        // Metric counts should immediately reflect the change
        expect(find.text('On-Site (4)'), findsOneWidget);
        expect(find.text('Absent (1)'), findsOneWidget);

        // Tap again to toggle back to Present
        await tester.tap(rameshCard);
        await tester.pump();

        // Status should be restored to Present
        expect(workerStatusChip('Present'), findsNWidgets(5));
        expect(workerStatusChip('Absent'), findsNothing);
        expect(find.text('On-Site (5)'), findsOneWidget);
        expect(find.text('Absent (0)'), findsOneWidget);
      },
    );

    testWidgets(
      'updates active filter tab via setState() and filters worker list immediately',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestApp());

        // Toggle W-001 (Ramesh) to Absent
        await tester.tap(find.byKey(const Key('workerCard_W-001')));
        await tester.pump();

        // Tap "Absent (1)" filter tab
        await tester.tap(find.byKey(const Key('filterAbsentTab')));
        await tester.pump();

        // Only Ramesh Kumar should be visible
        expect(find.text('Ramesh Kumar'), findsOneWidget);
        expect(find.text('Suresh Yadav'), findsNothing);
        expect(find.text('Imran Shaikh'), findsNothing);

        // Tap "On-Site (4)" filter tab
        await tester.tap(find.byKey(const Key('filterPresentTab')));
        await tester.pump();

        // Ramesh should be hidden, remaining 4 workers shown
        expect(find.text('Ramesh Kumar'), findsNothing);
        expect(find.text('Suresh Yadav'), findsOneWidget);
        expect(find.text('Imran Shaikh'), findsOneWidget);
        expect(find.text('Pooja Singh'), findsOneWidget);
        expect(find.text('Vikram Patel'), findsOneWidget);

        // Tap "All (5)" filter tab
        await tester.tap(find.byKey(const Key('filterAllTab')));
        await tester.pump();

        // All 5 should be visible again
        expect(find.byType(BrixelWorkerCard), findsNWidgets(5));
      },
    );

    testWidgets(
      'shows empty state message when filtered category contains no workers',
      (tester) async {
        await tester.pumpWidget(buildTestApp());

        // Initially no workers are absent; tap Absent tab
        await tester.tap(find.byKey(const Key('filterAbsentTab')));
        await tester.pump();

        expect(find.text('No workers in this category.'), findsOneWidget);
        expect(find.byType(BrixelWorkerCard), findsNothing);
      },
    );

    testWidgets(
      'navigates reporting date using setState() and updates header immediately',
      (tester) async {
        await tester.pumpWidget(
          buildTestApp(initialDate: DateTime(2026, 10, 6)),
        );

        expect(find.text('Tue, 6 Oct 2026'), findsOneWidget);

        // Advance to next day
        await tester.tap(find.byKey(const Key('nextDateButton')));
        await tester.pump();
        expect(find.text('Wed, 7 Oct 2026'), findsOneWidget);

        // Go back two days
        await tester.tap(find.byKey(const Key('previousDateButton')));
        await tester.pump();
        expect(find.text('Tue, 6 Oct 2026'), findsOneWidget);

        await tester.tap(find.byKey(const Key('previousDateButton')));
        await tester.pump();
        expect(find.text('Mon, 5 Oct 2026'), findsOneWidget);
      },
    );

    testWidgets('bulk actions update all workers atomically via setState()', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildTestApp());

      // Mark All Absent
      await tester.tap(find.byKey(const Key('markAllAbsentButton')));
      await tester.pump();

      expect(find.text('Absent (5)'), findsOneWidget);
      expect(find.text('On-Site (0)'), findsOneWidget);
      expect(workerStatusChip('Absent'), findsNWidgets(5));

      // Mark All Present
      await tester.tap(find.byKey(const Key('markAllPresentCta')));
      await tester.pump();

      expect(find.text('Absent (0)'), findsOneWidget);
      expect(find.text('On-Site (5)'), findsOneWidget);
      expect(workerStatusChip('Present'), findsNWidgets(5));
    });

    testWidgets(
      'remains stable and consistent across repeated rapid interactions',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestApp());

        final w1 = find.byKey(const Key('workerCard_W-001'));
        final w2 = find.byKey(const Key('workerCard_W-002'));

        // Toggle back and forth multiple times
        for (var i = 0; i < 5; i++) {
          await tester.tap(w1);
          await tester.pump();
          await tester.tap(w2);
          await tester.pump();
        }

        // Both were toggled an odd number of times (5 times), so both should now be Absent
        expect(find.text('On-Site (3)'), findsOneWidget);
        expect(find.text('Absent (2)'), findsOneWidget);

        // Switching tabs should maintain this state cleanly
        await tester.tap(find.byKey(const Key('filterAbsentTab')));
        await tester.pump();
        expect(find.byType(BrixelWorkerCard), findsNWidgets(2));

        await tester.tap(find.byKey(const Key('filterPresentTab')));
        await tester.pump();
        expect(find.byType(BrixelWorkerCard), findsNWidgets(3));
      },
    );
  });
}
