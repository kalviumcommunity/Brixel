import 'package:brixel/features/materials/models/material_model.dart';

abstract class MaterialUsageReadRepository {
  Future<List<MaterialTransactionModel>> fetchUsageForSite(String siteId);
}
