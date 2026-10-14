import 'package:brixel/features/materials/models/material_model.dart';

abstract class MaterialUsageWriteRepository {
  Future<String> addUsage({
    required String activeSiteId,
    required MaterialTransactionModel usage,
  });
}
