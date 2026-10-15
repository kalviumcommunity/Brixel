import 'package:brixel/core/services/firestore_database_service.dart';
import 'package:brixel/features/materials/models/material_model.dart';
import 'package:brixel/features/materials/repositories/material_usage_read_repository.dart';

class FirestoreMaterialUsageReadRepository
    implements MaterialUsageReadRepository {
  FirestoreMaterialUsageReadRepository({
    FirestoreDatabaseService? databaseService,
  }) : _databaseService = databaseService ?? FirestoreDatabaseService();

  final FirestoreDatabaseService _databaseService;

  @override
  Future<List<MaterialTransactionModel>> fetchUsageForSite(
    String siteId,
  ) async {
    final normalizedSiteId = siteId.trim();

    if (normalizedSiteId.isEmpty) {
      throw ArgumentError(
        'Site ID cannot be empty when fetching material usage.',
      );
    }

    final snapshot = await _databaseService.transactionsCollection
        .where('siteId', isEqualTo: normalizedSiteId)
        .where('type', isEqualTo: 'used')
        .get();

    return snapshot.docs
        .map(
          (document) =>
              MaterialTransactionModel.fromMap(document.data(), document.id),
        )
        .toList();
  }
}
