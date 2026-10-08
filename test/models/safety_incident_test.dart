import 'package:brixel/features/safety/models/safety_incident.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores incident details and separate event and record times', () {
    final occurredAt = DateTime(2026, 10, 6, 14);
    final recordedAt = DateTime(2026, 10, 6, 14, 20);
    final incident = SafetyIncident(
      siteId: 'site-001',
      description: 'Loose electrical cable near work area',
      location: 'Floor 2',
      severity: 'Medium',
      occurredAt: occurredAt,
      recordedAt: recordedAt,
    );

    expect(incident.siteId, 'site-001');
    expect(incident.description, 'Loose electrical cable near work area');
    expect(incident.location, 'Floor 2');
    expect(incident.severity, 'Medium');
    expect(incident.occurredAt, occurredAt);
    expect(incident.recordedAt, recordedAt);
    expect(incident.occurredAt, isNot(incident.recordedAt));
  });
}
