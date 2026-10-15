import 'package:brixel/features/materials/models/material_model.dart';
import 'package:brixel/features/materials/repositories/material_usage_read_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMaterialUsageReadRepository implements MaterialUsageReadRepository {
  FakeMaterialUsageReadRepository({required this.records, this.error});

  final List<MaterialTransactionModel> records;
  final Object? error;

  @override
  Future<List<MaterialTransactionModel>> fetchUsageForSite(
    String siteId,
  ) async {
    if (error != null) {
      throw error!;
    }

    return records
        .where((record) => record.siteId == siteId && record.type == 'used')
        .toList();
  }
}

void main() {
  MaterialTransactionModel buildUsage({
    required String id,
    required String siteId,
    String type = 'used',
  }) {
    return MaterialTransactionModel(
      id: id,
      materialId: 'mat-cement-01',
      siteId: siteId,
      type: type,
      quantity: 25,
      notes: 'Used for concrete work',
      recordedBy: 'supervisor-01',
      timestamp: DateTime(2026, 10, 15),
    );
  }

  test('returns only material usage for the requested site', () async {
    final repository = FakeMaterialUsageReadRepository(
      records: [
        buildUsage(id: 'tx-1', siteId: 'site-jaipur-01'),
        buildUsage(id: 'tx-2', siteId: 'site-kota-02'),
        buildUsage(id: 'tx-3', siteId: 'site-jaipur-01', type: 'received'),
      ],
    );

    final result = await repository.fetchUsageForSite('site-jaipur-01');

    expect(result.length, 1);
    expect(result.first.id, 'tx-1');
    expect(result.first.siteId, 'site-jaipur-01');
    expect(result.first.type, 'used');
  });

  test(
    'returns empty list when query succeeds with no matching data',
    () async {
      final repository = FakeMaterialUsageReadRepository(
        records: [buildUsage(id: 'tx-1', siteId: 'site-kota-02')],
      );

      final result = await repository.fetchUsageForSite('site-jaipur-01');

      expect(result, isEmpty);
    },
  );

  test(
    'propagates repository failure instead of returning empty data',
    () async {
      final repository = FakeMaterialUsageReadRepository(
        records: const [],
        error: StateError('Firestore unavailable'),
      );

      await expectLater(
        repository.fetchUsageForSite('site-jaipur-01'),
        throwsA(isA<StateError>()),
      );
    },
  );
}
