import 'package:cloud_firestore/cloud_firestore.dart';
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

  static Map<String, dynamic> buildUsagePayload(
    MaterialTransactionModel usage,
  ) {
    return usage.toMap()..['timestamp'] = FieldValue.serverTimestamp();
  }

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

    if (!usage.quantity.isFinite ||
        usage.quantity <= 0 ||
        usage.recordedBy.trim().isEmpty) {
      throw ArgumentError(
        'Usage requires a positive finite quantity and author.',
      );
    }
    final payload = buildUsagePayload(usage);
    return _databaseService.addMaterialTransaction(payload);
  }
}
