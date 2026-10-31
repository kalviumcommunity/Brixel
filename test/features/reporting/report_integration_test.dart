import 'package:brixel/features/navigation/screens/app_navigation_shell.dart';
import 'package:brixel/features/safety/models/incident_model.dart';
import 'package:brixel/features/safety/screens/safety_incident_list_screen.dart';

import 'dart:async';

import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/attendance/screens/attendance_form_screen.dart';
import 'package:brixel/features/materials/screens/material_form_screen.dart';
import 'package:brixel/features/reporting/repositories/site_report_repository.dart';
import 'package:brixel/features/reporting/screens/site_report_list_screen.dart';
import 'package:brixel/features/sites/models/site.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('main tabs fit common phone widths', (tester) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [320.0, 360.0, 390.0, 412.0]) {
      tester.view.physicalSize = Size(width, 740);
      await tester.pumpWidget(
        MaterialApp(
          theme: buildBrixelTheme(),
          home: const AppNavigationShell(
            site: Site(
              id: 'jaipur',
              name: 'Jaipur Residential Project',
              location: 'Jaipur, Rajasthan',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final label in [
        'Attendance',
        'Materials',
        'Safety',
        'More',
        'Home',
      ]) {
        await tester.tap(
          find.descendant(
            of: find.byType(BottomNavigationBar),
            matching: find.text(label),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '$label at $width');
      }
    }
  });

  testWidgets('safety cards fit a narrow phone with long audit identifiers', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 740);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBrixelTheme(),
        home: SafetyIncidentListScreen(
          site: const Site(
            id: 'jaipur',
            name: 'Jaipur Residential Project',
            location: '',
          ),
          initialIncidents: [
            IncidentModel(
              id: 'incident-12345678901234567890',
              siteId: 'jaipur',
              incidentType: 'equipment_failure',
              severity: 'high',
              description: 'Equipment issue on the third floor',
              status: 'reported',
              reportedBy: 'firebase-user-with-a-long-identifier',
              createdAt: DateTime(2026),
            ),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Equipment issue on the third floor'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('non-finite attendance never reaches persistence', (
    tester,
  ) async {
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: AttendanceFormScreen(
          onSubmit: (_) async {
            calls++;
          },
        ),
      ),
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Worker / Crew Name'),
      'Crew A',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Trade'),
      'Masonry',
    );
    for (final value in ['NaN', 'Infinity', '-Infinity']) {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Hours Worked'),
        value,
      );
      await tester.tap(find.text('Submit Attendance'));
      await tester.pump();
      expect(find.text('Please enter a valid number.'), findsOneWidget);
    }
    expect(calls, 0);
  });

  testWidgets('unconfigured material form fails truthfully and can retry', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MaterialFormScreen()));
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Material Name'),
      'Cement',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Quantity'), '5');
    await tester.tap(find.text('Submit Material Usage'));
    await tester.pumpAndSettle();
    expect(
      find.text('Failed to record material usage. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('saved for'), findsNothing);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('usage stream excludes other sites and supports live search', (
    tester,
  ) async {
    final records = StreamController<List<Map<String, dynamic>>>();
    addTearDown(records.close);
    await tester.pumpWidget(
      MaterialApp(
        theme: buildBrixelTheme(),
        home: SiteReportListScreen(
          site: const Site(id: 'jaipur', name: 'Jaipur', location: ''),
          materials: true,
          records: records.stream,
        ),
      ),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    records.add([
      {
        'siteId': 'jaipur',
        'type': 'used',
        'materialName': 'Cement',
        'quantity': 5,
        'unit': 'bags',
      },
      {
        'siteId': 'jaipur',
        'type': 'used',
        'materialName': 'Sand',
        'quantity': 2,
        'unit': 'tons',
      },
      {
        'siteId': 'other',
        'type': 'used',
        'materialName': 'Steel',
        'quantity': 9,
      },
    ]);
    await tester.pumpAndSettle();
    expect(find.text('Cement'), findsOneWidget);
    expect(find.text('Steel'), findsNothing);
    await tester.enterText(find.byType(TextField), 'sand');
    await tester.pump();
    expect(find.text('Sand'), findsOneWidget);
    expect(find.text('Cement'), findsNothing);
    records.addError(StateError('private Firebase detail'));
    await tester.pumpAndSettle();
    expect(find.text('Could not load reports.'), findsOneWidget);
    expect(find.textContaining('private Firebase detail'), findsNothing);
  });

  testWidgets('attendance history filters selected date and status', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SiteReportListScreen(
          site: const Site(id: 'jaipur', name: 'Jaipur', location: ''),
          materials: false,
          records: Stream.value([
            {
              'siteId': 'jaipur',
              'date': SiteReportRepository.dateKey(DateTime.now()),
              'workerName': 'Worker A',
              'trade': 'Mason',
              'hoursWorked': 8,
              'status': 'present',
            },
            {
              'siteId': 'jaipur',
              'date': SiteReportRepository.dateKey(DateTime.now()),
              'workerName': 'Worker B',
              'trade': 'Mason',
              'hoursWorked': 0,
              'status': 'absent',
            },
            {
              'siteId': 'jaipur',
              'date': '2000-01-01',
              'workerName': 'Old report',
              'status': 'present',
            },
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Old report'), findsNothing);
    await tester.tap(find.text('Absent'));
    await tester.pumpAndSettle();
    expect(find.text('Worker B'), findsOneWidget);
    expect(find.text('Worker A'), findsNothing);
  });
}
