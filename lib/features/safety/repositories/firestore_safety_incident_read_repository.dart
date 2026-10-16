import 'package:brixel/core/services/firestore_database_service.dart';
import 'package:brixel/features/safety/models/incident_model.dart';
import 'package:brixel/features/safety/repositories/safety_incident_read_repository.dart';

class FirestoreSafetyIncidentReadRepository
    implements SafetyIncidentReadRepository {
  FirestoreSafetyIncidentReadRepository({
    FirestoreDatabaseService? databaseService,
  }) : _databaseService = databaseService ?? FirestoreDatabaseService();

  final FirestoreDatabaseService _databaseService;

  @override
  Future<List<IncidentModel>> fetchIncidentsForSite(String siteId) async {
    final normalizedSiteId = siteId.trim();

    if (normalizedSiteId.isEmpty) {
      throw ArgumentError(
        'Site ID cannot be empty when fetching safety incidents.',
      );
    }

    final snapshot = await _databaseService.incidentsCollection
        .where('siteId', isEqualTo: normalizedSiteId)
        .get();

    return snapshot.docs
        .map((document) => IncidentModel.fromMap(document.data(), document.id))
        .toList();
  }

  @override
  Stream<List<IncidentModel>> watchIncidentsForSite(String siteId) {
    final normalizedSiteId = siteId.trim();

    if (normalizedSiteId.isEmpty) {
      throw ArgumentError(
        'Site ID cannot be empty when watching safety incidents.',
      );
    }

    return _databaseService.incidentsCollection
        .where('siteId', isEqualTo: normalizedSiteId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => IncidentModel.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
