import 'package:brixel/features/safety/models/incident_model.dart';
import 'package:brixel/features/safety/repositories/safety_incident_write_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class CapturingSafetyIncidentRepository
    implements SafetyIncidentWriteRepository {
  final Map<String, IncidentModel> storage = {};
  String? lastUpdatedId;
  Map<String, dynamic>? lastUpdatedFields;

  void seedIncident(IncidentModel incident) {
    storage[incident.id] = incident;
  }

  @override
  Future<String> addIncident({
    required String activeSiteId,
    required IncidentModel incident,
  }) async {
    storage[incident.id] = incident;
    return incident.id;
  }

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String status,
    String? resolvedBy,
  }) async {
    if (incidentId.trim().isEmpty) {
      throw ArgumentError('Incident document ID cannot be empty.');
    }
    const allowed = ['reported', 'acknowledged', 'resolved'];
    if (!allowed.contains(status)) {
      throw ArgumentError('Invalid status: $status');
    }

    final existing = storage[incidentId];
    if (existing == null) {
      throw StateError('Document not found with ID: $incidentId');
    }

    lastUpdatedId = incidentId;
    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': DateTime.now(),
    };
    if (status == 'resolved') {
      updates['resolvedAt'] = DateTime.now();
      if (resolvedBy != null && resolvedBy.trim().isNotEmpty) {
        updates['resolvedBy'] = resolvedBy.trim();
      }
    } else {
      updates['resolvedBy'] = null;
      updates['resolvedAt'] = null;
    }
    lastUpdatedFields = updates;

    // Simulate in-place Firestore update() merging:
    // only the passed fields change, all others remain untouched
    storage[incidentId] = existing.copyWith(
      status: status,
      resolvedBy: status == 'resolved' ? (resolvedBy ?? existing.resolvedBy) : null,
      resolvedAt: status == 'resolved' ? DateTime.now() : null,
    );
  }

  @override
  Future<void> updateIncidentFields({
    required String incidentId,
    required Map<String, dynamic> fields,
  }) async {
    if (incidentId.trim().isEmpty) {
      throw ArgumentError('Incident document ID cannot be empty.');
    }
    if (fields.isEmpty) {
      throw ArgumentError('Update fields payload cannot be empty.');
    }
    const immutable = {'id', 'siteId', 'createdAt', 'reportedBy'};
    for (final k in fields.keys) {
      if (immutable.contains(k)) {
        throw ArgumentError('Field "$k" is immutable and cannot be updated.');
      }
    }

    final existing = storage[incidentId];
    if (existing == null) {
      throw StateError('Document not found with ID: $incidentId');
    }

    lastUpdatedId = incidentId;
    lastUpdatedFields = Map<String, dynamic>.from(fields);

    // Apply partial updates
    storage[incidentId] = existing.copyWith(
      severity: fields['severity'] as String? ?? existing.severity,
      description: fields['description'] as String? ?? existing.description,
      status: fields['status'] as String? ?? existing.status,
    );
  }
}

void main() {
  group('Safety Incident Update - Record Identification & Partial Mutation', () {
    late CapturingSafetyIncidentRepository repository;
    final initialCreatedAt = DateTime(2026, 10, 10, 9, 30);

    setUp(() {
      repository = CapturingSafetyIncidentRepository();
      repository.seedIncident(
        IncidentModel(
          id: 'inc_metro_101',
          siteId: 'site_metro_line1',
          incidentType: 'hazard',
          severity: 'high',
          description: 'Exposed electrical wiring on scaffold level 2.',
          status: 'reported',
          reportedBy: 'usr_sup_101',
          createdAt: initialCreatedAt,
        ),
      );
      repository.seedIncident(
        IncidentModel(
          id: 'inc_metro_102',
          siteId: 'site_metro_line1',
          incidentType: 'equipment_failure',
          severity: 'critical',
          description: 'Crane hydraulic pressure drop.',
          status: 'reported',
          reportedBy: 'usr_sup_101',
          createdAt: initialCreatedAt,
        ),
      );
    });

    test('targets exact document by ID and mutates only status to acknowledged', () async {
      await repository.updateIncidentStatus(
        incidentId: 'inc_metro_101',
        status: 'acknowledged',
      );

      // Verify the right record was targeted
      expect(repository.lastUpdatedId, 'inc_metro_101');
      expect(repository.lastUpdatedFields!['status'], 'acknowledged');

      // Verify the targeted record updated
      final updated = repository.storage['inc_metro_101']!;
      expect(updated.status, 'acknowledged');

      // Confirm all original fields remain intact
      expect(updated.id, 'inc_metro_101');
      expect(updated.siteId, 'site_metro_line1');
      expect(updated.incidentType, 'hazard');
      expect(updated.severity, 'high');
      expect(updated.description, 'Exposed electrical wiring on scaffold level 2.');
      expect(updated.reportedBy, 'usr_sup_101');
      expect(updated.createdAt, initialCreatedAt);

      // Confirm untargeted record 102 was NOT modified
      final untouched = repository.storage['inc_metro_102']!;
      expect(untouched.status, 'reported');
    });

    test('resolving incident updates status and resolution fields leaving original fields intact', () async {
      await repository.updateIncidentStatus(
        incidentId: 'inc_metro_101',
        status: 'resolved',
        resolvedBy: 'usr_mgr_201',
      );

      expect(repository.lastUpdatedId, 'inc_metro_101');
      expect(repository.lastUpdatedFields!['status'], 'resolved');
      expect(repository.lastUpdatedFields!['resolvedBy'], 'usr_mgr_201');
      expect(repository.lastUpdatedFields!['resolvedAt'], isNotNull);

      final updated = repository.storage['inc_metro_101']!;
      expect(updated.status, 'resolved');
      expect(updated.resolvedBy, 'usr_mgr_201');
      expect(updated.description, 'Exposed electrical wiring on scaffold level 2.');
      expect(updated.reportedBy, 'usr_sup_101');
    });

    test('rejects empty document ID', () async {
      expect(
        () => repository.updateIncidentStatus(
          incidentId: '   ',
          status: 'acknowledged',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects invalid status', () async {
      expect(
        () => repository.updateIncidentStatus(
          incidentId: 'inc_metro_101',
          status: 'destroyed',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('partial field update mutates severity without wiping description or author', () async {
      await repository.updateIncidentFields(
        incidentId: 'inc_metro_101',
        fields: {'severity': 'critical'},
      );

      final updated = repository.storage['inc_metro_101']!;
      expect(updated.severity, 'critical');
      // Intact fields:
      expect(updated.description, 'Exposed electrical wiring on scaffold level 2.');
      expect(updated.reportedBy, 'usr_sup_101');
      expect(updated.status, 'reported');
    });

    test('rejects mutation of immutable system fields', () async {
      expect(
        () => repository.updateIncidentFields(
          incidentId: 'inc_metro_101',
          fields: {'siteId': 'site_other_999'},
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => repository.updateIncidentFields(
          incidentId: 'inc_metro_101',
          fields: {'reportedBy': 'impostor'},
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
