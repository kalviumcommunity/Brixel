import 'package:brixel/core/utils/site_scope_guard.dart';
import 'package:brixel/features/safety/models/incident_model.dart';
import 'package:brixel/features/safety/repositories/safety_incident_write_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSafetyIncidentWriteRepository
    implements SafetyIncidentWriteRepository {
  IncidentModel? lastIncident;
  String? lastActiveSiteId;

  @override
  String createIncidentId() => 'generated-incident-id';

  @override
  Future<String> addIncident({
    required String activeSiteId,
    required IncidentModel incident,
  }) async {
    SiteScopeGuard.validate(
      activeSiteId: activeSiteId,
      recordSiteId: incident.siteId,
    );

    if (incident.reportedBy.trim().isEmpty) {
      throw ArgumentError(
        'Safety incident must include the reporting user ID.',
      );
    }

    if (incident.status != 'reported') {
      throw ArgumentError(
        'New safety incidents must start with status "reported".',
      );
    }

    lastActiveSiteId = activeSiteId;
    lastIncident = incident;

    return 'generated-incident-id';
  }

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
  IncidentModel buildIncident({
    String siteId = 'site-jaipur-01',
    String reportedBy = 'user-supervisor-01',
    String status = 'reported',
  }) {
    return IncidentModel(
      id: '',
      siteId: siteId,
      incidentType: 'hazard',
      severity: 'high',
      description: 'Loose electrical cable near the work area.',
      status: status,
      reportedBy: reportedBy,
      createdAt: DateTime(2026, 10, 14),
    );
  }

  test('adds incident for the active site', () async {
    final repository = FakeSafetyIncidentWriteRepository();
    final incident = buildIncident();

    final documentId = await repository.addIncident(
      activeSiteId: 'site-jaipur-01',
      incident: incident,
    );

    expect(documentId, 'generated-incident-id');
    expect(repository.lastActiveSiteId, 'site-jaipur-01');
    expect(repository.lastIncident, same(incident));
  });

  test('rejects incident belonging to another site', () async {
    final repository = FakeSafetyIncidentWriteRepository();

    expect(
      () => repository.addIncident(
        activeSiteId: 'site-jaipur-01',
        incident: buildIncident(siteId: 'site-kota-02'),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects incident without reporting user id', () async {
    final repository = FakeSafetyIncidentWriteRepository();

    expect(
      () => repository.addIncident(
        activeSiteId: 'site-jaipur-01',
        incident: buildIncident(reportedBy: ''),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects incident that starts as resolved', () async {
    final repository = FakeSafetyIncidentWriteRepository();

    expect(
      () => repository.addIncident(
        activeSiteId: 'site-jaipur-01',
        incident: buildIncident(status: 'resolved'),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
