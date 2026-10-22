import 'dart:async';

import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/safety/models/incident_model.dart';
import 'package:brixel/features/safety/repositories/safety_incident_read_repository.dart';
import 'package:brixel/features/safety/repositories/safety_incident_write_repository.dart';
import 'package:brixel/features/safety/screens/safety_incident_list_screen.dart';
import 'package:brixel/features/sites/models/site.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestWriteRepository implements SafetyIncidentWriteRepository {
  final List<String> addedIds = [];
  final List<String> updatedIds = [];
  final List<String> deletedIds = [];

  @override
  String createIncidentId() => 'new-incident-id';

  @override
  Future<String> addIncident({
    required String activeSiteId,
    required IncidentModel incident,
  }) async {
    addedIds.add(incident.id);
    return incident.id;
  }

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String status,
    String? resolvedBy,
  }) async {
    updatedIds.add(incidentId);
  }

  @override
  Future<void> updateIncidentFields({
    required String incidentId,
    required Map<String, dynamic> fields,
  }) async {
    updatedIds.add(incidentId);
  }

  @override
  Future<void> deleteIncident({required String incidentId}) async {
    deletedIds.add(incidentId);
  }
}

class TestReadRepository implements SafetyIncidentReadRepository {
  TestReadRepository(this.incidentStream);

  final Stream<List<IncidentModel>> incidentStream;

  @override
  Future<List<IncidentModel>> fetchIncidentsForSite(String siteId) async => [];

  @override
  Stream<List<IncidentModel>> watchIncidentsForSite(String siteId) =>
      incidentStream;
}

void main() {
  const testSite = Site(
    id: 'site-metro-line1',
    name: 'Metro Line 1 - Station Pier 4',
    location: 'Madhapur, Hyderabad',
  );

  IncidentModel makeIncident({
    required String id,
    String type = 'hazard',
    String severity = 'high',
    String description = 'Test hazard',
    String status = 'reported',
  }) {
    return IncidentModel(
      id: id,
      siteId: testSite.id,
      incidentType: type,
      severity: severity,
      description: description,
      status: status,
      reportedBy: 'usr_sup_101',
      createdAt: DateTime(2026, 10, 16, 9, 0),
    );
  }

  group(
    'SafetyIncidentListScreen - Real-Time StreamBuilder Synchronization',
    () {
      late StreamController<List<IncidentModel>> streamController;
      late TestWriteRepository writeRepository;

      setUp(() {
        streamController = StreamController<List<IncidentModel>>.broadcast();
        writeRepository = TestWriteRepository();
      });

      tearDown(() {
        streamController.close();
      });

      Widget createWidget({Stream<List<IncidentModel>>? stream}) {
        return MaterialApp(
          theme: buildBrixelTheme(),
          home: SafetyIncidentListScreen(
            site: testSite,
            repository: writeRepository,
            incidentStream: stream ?? streamController.stream,
          ),
        );
      }

      testWidgets(
        'shows loading indicator while StreamBuilder is waiting for stream emission',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1600);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          // Pump widget with a fresh stream that hasn't emitted yet
          await tester.pumpWidget(createWidget());
          await tester.pump();

          // Verify CircularProgressIndicator is rendered during waiting state
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
        },
      );

      testWidgets(
        'renders emitted incident records and updates live sync indicator automatically',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1600);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(createWidget());
          await tester.pump();

          final initialIncidents = [
            makeIncident(id: 'inc_101', description: 'Hydraulic leak on crane'),
            makeIncident(
              id: 'inc_102',
              description: 'Missing barrier near shaft',
            ),
          ];

          // Emit data through stream
          streamController.add(initialIncidents);
          await tester.pumpAndSettle();

          // Verify records appear without manual refresh
          expect(
            find.text('Live Firestore Sync Active (snapshots)'),
            findsOneWidget,
          );
          expect(find.text('Doc ID: inc_101'), findsOneWidget);
          expect(find.text('Hydraulic leak on crane'), findsOneWidget);
          expect(find.text('Doc ID: inc_102'), findsOneWidget);
          expect(find.text('Missing barrier near shaft'), findsOneWidget);
          expect(find.text('Total Incidents'), findsOneWidget);
          expect(
            find.text('2'),
            findsNWidgets(2),
          ); // Total count: 2, Active/Open count: 2
        },
      );

      testWidgets(
        'Task 3: Newly added record in stream appears in UI automatically without refresh',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1600);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(createWidget());
          await tester.pump();

          final list = [
            makeIncident(id: 'inc_101', description: 'Existing item 1'),
          ];
          streamController.add(list);
          await tester.pumpAndSettle();

          expect(find.text('Doc ID: inc_101'), findsOneWidget);
          expect(find.text('Doc ID: inc_102_new'), findsNothing);
          expect(
            find.text('1'),
            findsNWidgets(2),
          ); // Total count: 1, Active count: 1

          // Simulate real-time addition pushed by Firestore from another client/driver
          final updatedListWithAdd = [
            makeIncident(
              id: 'inc_102_new',
              description: 'New incoming incident from field',
            ),
            makeIncident(id: 'inc_101', description: 'Existing item 1'),
          ];
          streamController.add(updatedListWithAdd);
          await tester.pumpAndSettle();

          // Confirm newly added record appeared immediately with NO manual refresh
          expect(find.text('Doc ID: inc_102_new'), findsOneWidget);
          expect(find.text('New incoming incident from field'), findsOneWidget);
          expect(find.text('2'), findsNWidgets(2)); // Total count: 2, Active: 2
        },
      );

      testWidgets(
        'Task 4: Updated record in stream updates status badge and metrics automatically',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1600);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(createWidget());
          await tester.pump();

          final list = [makeIncident(id: 'inc_101', status: 'reported')];
          streamController.add(list);
          await tester.pumpAndSettle();

          final badgeBefore = find.byKey(const Key('statusBadge_inc_101'));
          expect(
            find.descendant(of: badgeBefore, matching: find.text('Reported')),
            findsOneWidget,
          );

          // Simulate real-time update emission (e.g. supervisor marks as acknowledged/resolved)
          final updatedList = [makeIncident(id: 'inc_101', status: 'resolved')];
          streamController.add(updatedList);
          await tester.pumpAndSettle();

          // UI re-renders with new value with no refresh button pressed
          final badgeAfter = find.byKey(const Key('statusBadge_inc_101'));
          expect(
            find.descendant(of: badgeAfter, matching: find.text('Resolved')),
            findsOneWidget,
          );
          expect(find.text('Resolved & Closed'), findsOneWidget);
        },
      );

      testWidgets(
        'Task 4: Deleted record in stream is removed from UI automatically without refresh',
        (tester) async {
          tester.view.physicalSize = const Size(800, 1600);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() => tester.view.resetPhysicalSize());

          await tester.pumpWidget(createWidget());
          await tester.pump();

          final list = [
            makeIncident(id: 'inc_101', description: 'To be kept'),
            makeIncident(id: 'inc_102', description: 'To be removed'),
          ];
          streamController.add(list);
          await tester.pumpAndSettle();

          expect(find.text('Doc ID: inc_101'), findsOneWidget);
          expect(find.text('Doc ID: inc_102'), findsOneWidget);

          // Simulate deletion in Firestore -> stream emits list with inc_102 removed
          final listAfterDelete = [
            makeIncident(id: 'inc_101', description: 'To be kept'),
          ];
          streamController.add(listAfterDelete);
          await tester.pumpAndSettle();

          // inc_102 removed immediately
          expect(find.text('Doc ID: inc_101'), findsOneWidget);
          expect(find.text('Doc ID: inc_102'), findsNothing);
          expect(find.text('1'), findsNWidgets(2)); // Total: 1
        },
      );

      testWidgets('empty stream snapshot clears all cached incidents', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          MaterialApp(
            theme: buildBrixelTheme(),
            home: SafetyIncidentListScreen(
              site: testSite,
              repository: writeRepository,
              readRepository: TestReadRepository(streamController.stream),
            ),
          ),
        );
        await tester.pump();
        streamController.add([makeIncident(id: 'inc_101')]);
        await tester.pumpAndSettle();

        streamController.add([]);
        await tester.pumpAndSettle();

        expect(find.text('Doc ID: inc_101'), findsNothing);
        expect(find.text('No incidents matching this filter'), findsOneWidget);
        expect(find.text('0'), findsNWidgets(4));
      });

      testWidgets('shows error state when stream emits an error', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createWidget());
        await tester.pump();

        streamController.addError('Connection lost to Firestore cluster');
        await tester.pumpAndSettle();

        expect(find.text('Failed to load safety reports'), findsOneWidget);
        expect(
          find.textContaining('Connection lost to Firestore cluster'),
          findsOneWidget,
        );
      });
    },
  );
}
