import 'package:brixel/features/materials/models/material_model.dart';
import 'package:brixel/features/materials/repositories/firestore_material_usage_write_repository.dart';
import 'package:brixel/features/safety/models/incident_model.dart';
import 'package:brixel/features/safety/repositories/firestore_safety_incident_write_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('incident create payload uses a server-generated createdAt value', () {
    final incident = IncidentModel(
      id: 'incident-test',
      siteId: 'site-test',
      incidentType: 'hazard',
      severity: 'high',
      description: 'Loose cable near work area.',
      status: 'reported',
      reportedBy: 'supervisor-test',
      createdAt: DateTime(2000),
    );

    final payload = FirestoreSafetyIncidentWriteRepository.buildCreatePayload(
      incident,
    );

    expect(payload['createdAt'], isA<FieldValue>());
    expect(payload['createdAt'], isNot(isA<Timestamp>()));
    expect(payload['photoUrl'], isNull);
  });

  test(
    'material usage payload uses a server-generated transaction timestamp',
    () {
      final usage = MaterialTransactionModel(
        id: '',
        materialId: 'material-test',
        siteId: 'site-test',
        type: 'used',
        quantity: 3,
        recordedBy: 'supervisor-test',
        timestamp: DateTime(2000),
      );

      final payload = FirestoreMaterialUsageWriteRepository.buildUsagePayload(
        usage,
      );

      expect(payload['timestamp'], isA<FieldValue>());
      expect(payload['timestamp'], isNot(isA<Timestamp>()));
    },
  );
}
