import 'package:brixel/core/services/firestore_database_service.dart';
import 'package:brixel/core/utils/site_scope_guard.dart';
import 'package:brixel/features/materials/models/material_model.dart';
import 'package:brixel/features/materials/repositories/material_usage_write_repository.dart';

class FirestoreMaterialUsageWriteRepository
    implements MaterialUsageWriteRepository {
  FirestoreMaterialUsageWriteRepository({
    FirestoreDatabaseService? databaseService,
  }) : _databaseService = databaseService ?? FirestoreDatabaseService();

  final FirestoreDatabaseService _databaseService;

  @override
  Future<String> addUsage({
    required String activeSiteId,
    required MaterialTransactionModel usage,
  }) async {
    SiteScopeGuard.validate(
      activeSiteId: activeSiteId,
      recordSiteId: usage.siteId,
    );

    if (usage.type != 'used') {
      throw ArgumentError(
        'Material usage writes must use transaction type "used".',
      );
    }

    final document = await _databaseService.transactionsCollection.add(
      usage.toMap(),
    );

    return document.id;
  }
}
