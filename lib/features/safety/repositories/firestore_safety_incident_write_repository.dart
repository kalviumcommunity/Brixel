import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:brixel/core/services/firestore_database_service.dart';
import 'package:brixel/core/utils/site_scope_guard.dart';
import 'package:brixel/features/safety/models/incident_model.dart';
import 'package:brixel/features/safety/repositories/safety_incident_write_repository.dart';

class FirestoreSafetyIncidentWriteRepository
    implements SafetyIncidentWriteRepository {
  FirestoreSafetyIncidentWriteRepository({
    FirestoreDatabaseService? databaseService,
  }) : _databaseService = databaseService ?? FirestoreDatabaseService();

  final FirestoreDatabaseService _databaseService;

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

    final document = await _databaseService.incidentsCollection.add(
      incident.toMap(),
    );

    return document.id;
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

    const allowedStatuses = ['reported', 'acknowledged', 'resolved'];
    if (!allowedStatuses.contains(status)) {
      throw ArgumentError(
        'Invalid status "$status". Allowed statuses: ${allowedStatuses.join(', ')}.',
      );
    }

    final updates = <String, dynamic>{
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (status == 'resolved') {
      updates['resolvedAt'] = FieldValue.serverTimestamp();
      if (resolvedBy != null && resolvedBy.trim().isNotEmpty) {
        updates['resolvedBy'] = resolvedBy.trim();
      }
    } else {
      updates['resolvedBy'] = null;
      updates['resolvedAt'] = null;
    }

    try {
      await _databaseService.incidentsCollection
          .doc(incidentId)
          .update(updates)
          .timeout(const Duration(seconds: 2));
    } on FirebaseException catch (e) {
      debugPrint('Firestore update FirebaseException: ${e.code} - ${e.message}');
    } on TimeoutException {
      debugPrint('Firestore update timed out: proceeding with local update.');
    }
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

    const immutableFields = {'id', 'siteId', 'createdAt', 'reportedBy'};
    for (final key in fields.keys) {
      if (immutableFields.contains(key)) {
        throw ArgumentError('Field "$key" is immutable and cannot be updated.');
      }
    }

    final payload = Map<String, dynamic>.from(fields);
    payload['updatedAt'] = FieldValue.serverTimestamp();

    try {
      await _databaseService.incidentsCollection
          .doc(incidentId)
          .update(payload)
          .timeout(const Duration(seconds: 2));
    } on FirebaseException catch (e) {
      debugPrint('Firestore update FirebaseException: ${e.code} - ${e.message}');
    } on TimeoutException {
      debugPrint('Firestore update timed out: proceeding with local update.');
    }
  }
}
