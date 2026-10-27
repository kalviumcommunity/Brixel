import 'package:brixel/features/sites/models/site_model.dart';

abstract class SiteRepository {
  Stream<List<SiteModel>> watchAllSites();
  Stream<List<SiteModel>> watchAssignedSites(List<String> siteIds);
  Stream<List<SiteModel>> watchSitesForSupervisor(String supervisorId);
}
