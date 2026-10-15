import 'package:brixel/features/safety/models/incident_model.dart';

abstract class SafetyIncidentWriteRepository {
  Future<String> addIncident({
    required String activeSiteId,
    required IncidentModel incident,
  });

  Future<void> updateIncidentStatus({
    required String incidentId,
    required String status,
    String? resolvedBy,
  });

  Future<void> updateIncidentFields({
    required String incidentId,
    required Map<String, dynamic> fields,
  });
}
