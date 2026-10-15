import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/safety/models/incident_model.dart';
import 'package:brixel/features/safety/repositories/safety_incident_write_repository.dart';
import 'package:brixel/features/safety/screens/safety_incident_list_screen.dart';
import 'package:brixel/features/sites/models/site.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockSafetyIncidentRepository implements SafetyIncidentWriteRepository {
  final List<String> updatedIncidentIds = [];
  final List<String> updatedStatuses = [];
  bool shouldThrowError = false;

  @override
  Future<String> addIncident({
    required String activeSiteId,
    required IncidentModel incident,
  }) async {
    return 'new-id';
  }

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String status,
    String? resolvedBy,
  }) async {
    if (shouldThrowError) {
      throw StateError('Network timeout during Firestore update');
    }
    updatedIncidentIds.add(incidentId);
    updatedStatuses.add(status);
  }

  @override
  Future<void> updateIncidentFields({
    required String incidentId,
    required Map<String, dynamic> fields,
  }) async {
    if (shouldThrowError) {
      throw StateError('Network timeout during Firestore update');
    }
    updatedIncidentIds.add(incidentId);
  }
}

void main() {
  const testSite = Site(
    id: 'site-jaipur-01',
    name: 'Jaipur Residential Project',
    location: 'Jaipur, Rajasthan',
  );

  final testIncidents = [
    IncidentModel(
      id: 'inc_001',
      siteId: 'site-jaipur-01',
      incidentType: 'equipment_failure',
      severity: 'high',
      description: 'Hydraulic leak on Crane #2.',
      status: 'reported',
      reportedBy: 'usr_sup_101',
      createdAt: DateTime(2026, 10, 14, 8, 0),
    ),
    IncidentModel(
      id: 'inc_002',
      siteId: 'site-jaipur-01',
      incidentType: 'hazard',
      severity: 'medium',
      description: 'Open electrical trench near Gate 3.',
      status: 'reported',
      reportedBy: 'usr_sup_102',
      createdAt: DateTime(2026, 10, 14, 9, 0),
    ),
    IncidentModel(
      id: 'inc_003',
      siteId: 'site-jaipur-01',
      incidentType: 'fall',
      severity: 'low',
      description: 'Slip on scaffold plank, harness caught.',
      status: 'resolved',
      reportedBy: 'usr_sup_103',
      resolvedBy: 'usr_mgr_201',
      resolvedAt: DateTime(2026, 10, 14, 11, 0),
      createdAt: DateTime(2026, 10, 14, 7, 0),
    ),
  ];

  Widget buildTestWidget({
    required SafetyIncidentWriteRepository repository,
    List<IncidentModel>? incidents,
  }) {
    return MaterialApp(
      theme: buildBrixelTheme(),
      home: SafetyIncidentListScreen(
        site: testSite,
        repository: repository,
        initialIncidents: incidents ?? testIncidents,
      ),
    );
  }

  testWidgets('renders incident list with explicit document IDs and metrics',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repository = MockSafetyIncidentRepository();
    await tester.pumpWidget(buildTestWidget(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('Safety Reports'), findsOneWidget);
    expect(find.text('Jaipur Residential Project'), findsOneWidget);

    // Verify Document IDs are visibly rendered
    expect(find.byKey(const Key('docId_inc_001')), findsOneWidget);
    expect(find.text('Doc ID: inc_001'), findsOneWidget);
    expect(find.text('Doc ID: inc_002'), findsOneWidget);
    expect(find.text('Doc ID: inc_003'), findsOneWidget);

    // Initial metrics
    expect(find.text('Total Incidents'), findsOneWidget);
    expect(find.text('3'), findsOneWidget); // total
  });

  testWidgets('acknowledging incident targets exact document ID and updates UI',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repository = MockSafetyIncidentRepository();
    await tester.pumpWidget(buildTestWidget(repository: repository));
    await tester.pumpAndSettle();

    // Tap Acknowledge on inc_001 specifically
    final ackButton = find.byKey(const Key('ack_inc_001'));
    expect(ackButton, findsOneWidget);
    await tester.tap(ackButton);
    await tester.pumpAndSettle();

    // Verify repository call targeted ONLY inc_001 with 'acknowledged'
    expect(repository.updatedIncidentIds, ['inc_001']);
    expect(repository.updatedStatuses, ['acknowledged']);

    // Verify UI badge for inc_001 updated immediately
    final statusBadge = find.byKey(const Key('statusBadge_inc_001'));
    expect(statusBadge, findsOneWidget);
    expect(find.descendant(of: statusBadge, matching: find.text('Acknowledged')),
        findsOneWidget);

    // Verify inc_002 is still 'Reported' (untouched!)
    final badge2 = find.byKey(const Key('statusBadge_inc_002'));
    expect(
        find.descendant(of: badge2, matching: find.text('Reported')), findsOneWidget);

    // Verify SnackBar confirmation
    expect(find.textContaining('Updated incident inc_001 status to Acknowledged'),
        findsOneWidget);
  });

  testWidgets('resolving incident updates status to resolved and updates summary metrics',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repository = MockSafetyIncidentRepository();
    await tester.pumpWidget(buildTestWidget(repository: repository));
    await tester.pumpAndSettle();

    // Resolve inc_002
    final resolveButton = find.byKey(const Key('resolve_inc_002'));
    expect(resolveButton, findsOneWidget);
    await tester.tap(resolveButton);
    await tester.pumpAndSettle();

    expect(repository.updatedIncidentIds, ['inc_002']);
    expect(repository.updatedStatuses, ['resolved']);

    // Badge updated
    final badge2 = find.byKey(const Key('statusBadge_inc_002'));
    expect(
        find.descendant(of: badge2, matching: find.text('Resolved')), findsOneWidget);

    // Resolved count should have incremented to 2
    expect(find.text('Resolved & Closed'), findsNWidgets(2));
  });

  testWidgets('filters incidents by status', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repository = MockSafetyIncidentRepository();
    await tester.pumpWidget(buildTestWidget(repository: repository));
    await tester.pumpAndSettle();

    // Filter by Resolved
    await tester.tap(find.text('Resolved (1)'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('docId_inc_003')), findsOneWidget);
    expect(find.byKey(const Key('docId_inc_001')), findsNothing);
    expect(find.byKey(const Key('docId_inc_002')), findsNothing);
  });

  testWidgets('displays error feedback when Firestore update fails',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final repository = MockSafetyIncidentRepository()..shouldThrowError = true;
    await tester.pumpWidget(buildTestWidget(repository: repository));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('ack_inc_001')));
    await tester.pumpAndSettle();

    // Status remains reported
    final statusBadge = find.byKey(const Key('statusBadge_inc_001'));
    expect(find.descendant(of: statusBadge, matching: find.text('Reported')),
        findsOneWidget);

    // Error SnackBar shown
    expect(find.textContaining('Failed to update incident:'), findsOneWidget);
  });
}
