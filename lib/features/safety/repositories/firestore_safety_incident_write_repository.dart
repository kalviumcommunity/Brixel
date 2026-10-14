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
}
