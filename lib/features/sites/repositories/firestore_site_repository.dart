import 'package:brixel/core/services/firestore_database_service.dart';
import 'package:brixel/features/sites/models/site_model.dart';
import 'package:brixel/features/sites/repositories/site_repository.dart';

class FirestoreSiteRepository implements SiteRepository {
  FirestoreSiteRepository({FirestoreDatabaseService? databaseService})
    : _databaseService = databaseService ?? FirestoreDatabaseService();

  final FirestoreDatabaseService _databaseService;

  @override
  Stream<List<SiteModel>> watchAssignedSites(List<String> siteIds) {
    return _databaseService.streamAssignedSites(siteIds);
  }
}
