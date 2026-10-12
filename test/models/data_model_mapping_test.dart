import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:brixel/features/attendance/models/attendance_model.dart';
import 'package:brixel/features/materials/models/material_model.dart';
import 'package:brixel/features/safety/models/incident_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AttendanceRecordModel mapping', () {
    test('maps attendance model to Firestore-compatible map', () {
      final createdAt = DateTime(2026, 10, 12, 9, 30);
      final updatedAt = DateTime(2026, 10, 12, 10, 0);
      final model = AttendanceRecordModel(
        id: 'attendance-001',
        siteId: 'site-001',
        workerName: 'Ramesh Kumar',
        trade: 'Mason',
        status: 'present',
        hoursWorked: 8.0,
        date: '2026-10-12',
        recordedBy: 'supervisor-001',
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final map = model.toMap();

      expect(map['siteId'], 'site-001');
      expect(map['workerName'], 'Ramesh Kumar');
      expect(map['trade'], 'Mason');
      expect(map['status'], 'present');
      expect(map['hoursWorked'], 8.0);
      expect(map['date'], '2026-10-12');
      expect(map['recordedBy'], 'supervisor-001');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['updatedAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate(), createdAt);
      expect((map['updatedAt'] as Timestamp).toDate(), updatedAt);
    });

    test('creates attendance model from Firestore-compatible map', () {
      final createdAt = DateTime(2026, 10, 12, 9, 30);
      final updatedAt = DateTime(2026, 10, 12, 10, 0);
      final map = <String, dynamic>{
        'siteId': 'site-001',
        'workerName': 'Ramesh Kumar',
        'trade': 'Mason',
        'status': 'present',
        'hoursWorked': 8,
        'date': '2026-10-12',
        'recordedBy': 'supervisor-001',
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
      };

      final model = AttendanceRecordModel.fromMap(map, 'attendance-001');

      expect(model.id, 'attendance-001');
      expect(model.siteId, 'site-001');
      expect(model.workerName, 'Ramesh Kumar');
      expect(model.trade, 'Mason');
      expect(model.status, 'present');
      expect(model.hoursWorked, 8.0);
      expect(model.date, '2026-10-12');
      expect(model.recordedBy, 'supervisor-001');
      expect(model.createdAt, createdAt);
      expect(model.updatedAt, updatedAt);
    });

    test('attendance model survives round trip mapping', () {
      final original = AttendanceRecordModel(
        id: 'attendance-001',
        siteId: 'site-001',
        workerName: 'Ramesh Kumar',
        trade: 'Mason',
        status: 'present',
        hoursWorked: 8.0,
        date: '2026-10-12',
        recordedBy: 'supervisor-001',
        createdAt: DateTime(2026, 10, 12, 9, 30),
        updatedAt: DateTime(2026, 10, 12, 10, 0),
      );

      final roundTrip = AttendanceRecordModel.fromMap(
        original.toMap(),
        original.id,
      );

      expect(roundTrip.id, original.id);
      expect(roundTrip.siteId, original.siteId);
      expect(roundTrip.workerName, original.workerName);
      expect(roundTrip.trade, original.trade);
      expect(roundTrip.status, original.status);
      expect(roundTrip.hoursWorked, original.hoursWorked);
      expect(roundTrip.date, original.date);
      expect(roundTrip.recordedBy, original.recordedBy);
      expect(roundTrip.createdAt, original.createdAt);
      expect(roundTrip.updatedAt, original.updatedAt);
    });
  });

  group('MaterialTransactionModel mapping', () {
    test('maps material transaction model to Firestore-compatible map', () {
      final timestamp = DateTime(2026, 10, 12, 11, 0);
      final model = MaterialTransactionModel(
        id: 'transaction-001',
        materialId: 'cement-001',
        siteId: 'site-001',
        type: 'used',
        quantity: 35.0,
        notes: 'Used for foundation work',
        recordedBy: 'supervisor-001',
        timestamp: timestamp,
      );

      final map = model.toMap();

      expect(map['materialId'], 'cement-001');
      expect(map['siteId'], 'site-001');
      expect(map['type'], 'used');
      expect(map['quantity'], 35.0);
      expect(map['notes'], 'Used for foundation work');
      expect(map['recordedBy'], 'supervisor-001');
      expect(map['timestamp'], isA<Timestamp>());
      expect((map['timestamp'] as Timestamp).toDate(), timestamp);
    });

    test(
      'creates material transaction model from Firestore-compatible map',
      () {
        final timestamp = DateTime(2026, 10, 12, 11, 0);
        final map = <String, dynamic>{
          'materialId': 'cement-001',
          'siteId': 'site-001',
          'type': 'used',
          'quantity': 35,
          'notes': null,
          'recordedBy': 'supervisor-001',
          'timestamp': Timestamp.fromDate(timestamp),
        };

        final model = MaterialTransactionModel.fromMap(map, 'transaction-001');

        expect(model.id, 'transaction-001');
        expect(model.materialId, 'cement-001');
        expect(model.siteId, 'site-001');
        expect(model.type, 'used');
        expect(model.quantity, 35.0);
        expect(model.notes, isNull);
        expect(model.recordedBy, 'supervisor-001');
        expect(model.timestamp, timestamp);
      },
    );

    test('material transaction survives mapping round trip', () {
      final original = MaterialTransactionModel(
        id: 'transaction-001',
        materialId: 'cement-001',
        siteId: 'site-001',
        type: 'used',
        quantity: 35.0,
        notes: 'Used for foundation work',
        recordedBy: 'supervisor-001',
        timestamp: DateTime(2026, 10, 12, 11, 0),
      );

      final roundTrip = MaterialTransactionModel.fromMap(
        original.toMap(),
        original.id,
      );

      expect(roundTrip.id, original.id);
      expect(roundTrip.materialId, original.materialId);
      expect(roundTrip.siteId, original.siteId);
      expect(roundTrip.type, original.type);
      expect(roundTrip.quantity, original.quantity);
      expect(roundTrip.notes, original.notes);
      expect(roundTrip.recordedBy, original.recordedBy);
      expect(roundTrip.timestamp, original.timestamp);
    });
  });

  group('IncidentModel mapping', () {
    test('maps incident model to Firestore-compatible map', () {
      final createdAt = DateTime(2026, 10, 12, 12, 30);
      final resolvedAt = DateTime(2026, 10, 12, 14, 15);
      final model = IncidentModel(
        id: 'incident-001',
        siteId: 'site-001',
        incidentType: 'equipment_failure',
        severity: 'high',
        description: 'Loose electrical cable near work area',
        photoUrl: null,
        status: 'reported',
        reportedBy: 'supervisor-001',
        resolvedBy: 'manager-001',
        createdAt: createdAt,
        resolvedAt: resolvedAt,
      );

      final map = model.toMap();

      expect(map['siteId'], 'site-001');
      expect(map['incidentType'], 'equipment_failure');
      expect(map['severity'], 'high');
      expect(map['description'], 'Loose electrical cable near work area');
      expect(map['photoUrl'], isNull);
      expect(map['status'], 'reported');
      expect(map['reportedBy'], 'supervisor-001');
      expect(map['resolvedBy'], 'manager-001');
      expect(map['createdAt'], isA<Timestamp>());
      expect(map['resolvedAt'], isA<Timestamp>());
      expect((map['createdAt'] as Timestamp).toDate(), createdAt);
      expect((map['resolvedAt'] as Timestamp).toDate(), resolvedAt);
    });

    test('creates incident model from Firestore-compatible map with nullable fields', () {
      final createdAt = DateTime(2026, 10, 12, 12, 30);
      final map = <String, dynamic>{
        'siteId': 'site-001',
        'incidentType': 'equipment_failure',
        'severity': 'high',
        'description': 'Loose electrical cable near work area',
        'photoUrl': null,
        'status': 'reported',
        'reportedBy': 'supervisor-001',
        'resolvedBy': null,
        'createdAt': Timestamp.fromDate(createdAt),
        'resolvedAt': null,
      };

      final model = IncidentModel.fromMap(map, 'incident-001');

      expect(model.id, 'incident-001');
      expect(model.siteId, 'site-001');
      expect(model.incidentType, 'equipment_failure');
      expect(model.severity, 'high');
      expect(model.description, 'Loose electrical cable near work area');
      expect(model.photoUrl, isNull);
      expect(model.status, 'reported');
      expect(model.reportedBy, 'supervisor-001');
      expect(model.resolvedBy, isNull);
      expect(model.createdAt, createdAt);
      expect(model.resolvedAt, isNull);
    });

    test('incident model survives mapping round trip', () {
      final original = IncidentModel(
        id: 'incident-001',
        siteId: 'site-001',
        incidentType: 'equipment_failure',
        severity: 'high',
        description: 'Loose electrical cable near work area',
        photoUrl: null,
        status: 'reported',
        reportedBy: 'supervisor-001',
        resolvedBy: null,
        createdAt: DateTime(2026, 10, 12, 12, 30),
        resolvedAt: null,
      );

      final roundTrip = IncidentModel.fromMap(original.toMap(), original.id);

      expect(roundTrip.id, original.id);
      expect(roundTrip.siteId, original.siteId);
      expect(roundTrip.incidentType, original.incidentType);
      expect(roundTrip.severity, original.severity);
      expect(roundTrip.description, original.description);
      expect(roundTrip.photoUrl, original.photoUrl);
      expect(roundTrip.status, original.status);
      expect(roundTrip.reportedBy, original.reportedBy);
      expect(roundTrip.resolvedBy, original.resolvedBy);
      expect(roundTrip.createdAt, original.createdAt);
      expect(roundTrip.resolvedAt, original.resolvedAt);
    });
  });
}
