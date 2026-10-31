import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/safety/models/incident_model.dart';
import 'package:brixel/features/safety/repositories/safety_incident_write_repository.dart';
import 'package:brixel/features/safety/screens/safety_incident_list_screen.dart';
import 'package:brixel/features/sites/models/site.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockSafetyRepository implements SafetyIncidentWriteRepository {
  @override
  String createIncidentId() => 'new-id';

  @override
  Future<String> addIncident({
    required String activeSiteId,
    required IncidentModel incident,
  }) async => 'new-id';

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String status,
    String? resolvedBy,
  }) async {}

  @override
  Future<void> updateIncidentFields({
    required String incidentId,
    required Map<String, dynamic> fields,
  }) async {}

  @override
  Future<void> deleteIncident({required String incidentId}) async {}
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
      createdAt: DateTime(2026, 10, 14, 7, 0),
    ),
  ];

  Widget buildTestWidget({List<IncidentModel>? incidents}) {
    return MaterialApp(
      theme: buildBrixelTheme(),
      home: SafetyIncidentListScreen(
        currentUserId: 'test-supervisor',
        site: testSite,
        repository: _MockSafetyRepository(),
        initialIncidents: incidents ?? testIncidents,
      ),
    );
  }

  group('SafetyIncidentListScreen - Search & Filtering Tests', () {
    testWidgets(
      'Task 1: Search field renders with appropriate placeholder and icons',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        final searchFieldFinder = find.byKey(const Key('incidentSearchField'));
        expect(searchFieldFinder, findsOneWidget);
        expect(
          find.text('Search incidents by type, description, or ID...'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Task 2 & 3: Re-filters list live as user types matching description or type',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Initially all 3 incidents are visible
        expect(find.byKey(const Key('docId_inc_001')), findsOneWidget);
        expect(find.byKey(const Key('docId_inc_002')), findsOneWidget);
        expect(find.byKey(const Key('docId_inc_003')), findsOneWidget);

        // Search for 'Crane' (matches inc_001)
        await tester.enterText(
          find.byKey(const Key('incidentSearchField')),
          'Crane',
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('docId_inc_001')), findsOneWidget);
        expect(find.byKey(const Key('docId_inc_002')), findsNothing);
        expect(find.byKey(const Key('docId_inc_003')), findsNothing);

        // Search for 'trench' (matches inc_002 case-insensitively)
        await tester.enterText(
          find.byKey(const Key('incidentSearchField')),
          'trench',
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('docId_inc_001')), findsNothing);
        expect(find.byKey(const Key('docId_inc_002')), findsOneWidget);
        expect(find.byKey(const Key('docId_inc_003')), findsNothing);

        // Search by incidentType 'fall' (matches inc_003)
        await tester.enterText(
          find.byKey(const Key('incidentSearchField')),
          'fall',
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('docId_inc_001')), findsNothing);
        expect(find.byKey(const Key('docId_inc_002')), findsNothing);
        expect(find.byKey(const Key('docId_inc_003')), findsOneWidget);
      },
    );

    testWidgets(
      'Task 3: Shows "no matches" message and clear button when search is empty',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('incidentSearchField')),
          'NonExistentTermXYZ',
        );
        await tester.pumpAndSettle();

        // Incidents hidden
        expect(find.byKey(const Key('docId_inc_001')), findsNothing);
        expect(find.byKey(const Key('docId_inc_002')), findsNothing);
        expect(find.byKey(const Key('docId_inc_003')), findsNothing);

        // No matches empty message rendered
        expect(find.text('No matching incidents found'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(BrixelSectionCard),
            matching: find.textContaining('NonExistentTermXYZ'),
          ),
          findsOneWidget,
        );

        // Tap clear search button
        final clearButton = find.byKey(const Key('clearSearchButton'));
        expect(clearButton, findsOneWidget);
        await tester.tap(clearButton);
        await tester.pumpAndSettle();

        // All records restored
        expect(find.byKey(const Key('docId_inc_001')), findsOneWidget);
        expect(find.byKey(const Key('docId_inc_002')), findsOneWidget);
        expect(find.byKey(const Key('docId_inc_003')), findsOneWidget);
      },
    );

    testWidgets(
      'Task 4: Combines text search with Firestore category filter chips',
      (tester) async {
        tester.view.physicalSize = const Size(800, 1600);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(buildTestWidget());
        await tester.pumpAndSettle();

        // Tap 'Reported (2)' filter chip
        await tester.tap(find.text('Reported (2)'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('docId_inc_001')), findsOneWidget);
        expect(find.byKey(const Key('docId_inc_002')), findsOneWidget);
        expect(find.byKey(const Key('docId_inc_003')), findsNothing);

        // Now search for 'leak' (matches reported inc_001)
        await tester.enterText(
          find.byKey(const Key('incidentSearchField')),
          'leak',
        );
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('docId_inc_001')), findsOneWidget);
        expect(find.byKey(const Key('docId_inc_002')), findsNothing);

        // Tap 'Resolved (1)' chip while 'leak' is still typed
        // Since inc_003 is resolved but does NOT have 'leak', it should show empty state
        await tester.tap(find.text('Resolved (1)'));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('docId_inc_001')), findsNothing);
        expect(find.byKey(const Key('docId_inc_002')), findsNothing);
        expect(find.byKey(const Key('docId_inc_003')), findsNothing);
        expect(find.text('No matching incidents found'), findsOneWidget);
      },
    );
  });
}
