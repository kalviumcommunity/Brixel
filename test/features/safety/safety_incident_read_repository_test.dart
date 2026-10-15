import 'package:brixel/features/safety/models/incident_model.dart';
import 'package:brixel/features/safety/repositories/safety_incident_read_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSafetyIncidentReadRepository implements SafetyIncidentReadRepository {
  FakeSafetyIncidentReadRepository({required this.incidents, this.error});

  final List<IncidentModel> incidents;
  final Object? error;

  @override
  Future<List<IncidentModel>> fetchIncidentsForSite(String siteId) async {
    if (siteId.trim().isEmpty) {
      throw ArgumentError(
        'Site ID cannot be empty when fetching safety incidents.',
      );
    }

    if (error != null) {
      throw error!;
    }

    return incidents.where((incident) => incident.siteId == siteId).toList();
  }
}

void main() {
  IncidentModel buildIncident({required String id, required String siteId}) {
    return IncidentModel(
      id: id,
      siteId: siteId,
      incidentType: 'hazard',
      severity: 'high',
      description: 'Loose cable near the work area.',
      status: 'reported',
      reportedBy: 'supervisor-01',
      createdAt: DateTime(2026, 10, 15),
    );
  }

  test('returns only incidents for the requested site', () async {
    final repository = FakeSafetyIncidentReadRepository(
      incidents: [
        buildIncident(id: 'incident-1', siteId: 'site-jaipur-01'),
        buildIncident(id: 'incident-2', siteId: 'site-kota-02'),
      ],
    );

    final result = await repository.fetchIncidentsForSite('site-jaipur-01');

    expect(result.length, 1);
    expect(result.first.id, 'incident-1');
    expect(result.first.siteId, 'site-jaipur-01');
  });

  test('returns empty list when no incidents match', () async {
    final repository = FakeSafetyIncidentReadRepository(
      incidents: [buildIncident(id: 'incident-1', siteId: 'site-kota-02')],
    );

    final result = await repository.fetchIncidentsForSite('site-jaipur-01');

    expect(result, isEmpty);
  });

  test('propagates fetch failure instead of returning empty list', () async {
    final repository = FakeSafetyIncidentReadRepository(
      incidents: const [],
      error: StateError('Firestore unavailable'),
    );

    await expectLater(
      repository.fetchIncidentsForSite('site-jaipur-01'),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects empty site id', () async {
    final repository = FakeSafetyIncidentReadRepository(incidents: const []);

    await expectLater(
      repository.fetchIncidentsForSite(''),
      throwsA(isA<ArgumentError>()),
    );
  });
}
