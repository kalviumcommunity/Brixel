import 'package:brixel/features/safety/models/incident_model.dart';

abstract class SafetyIncidentReadRepository {
  Future<List<IncidentModel>> fetchIncidentsForSite(String siteId);
  Stream<List<IncidentModel>> watchIncidentsForSite(String siteId);
}
