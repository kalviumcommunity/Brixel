import 'package:brixel/core/utils/site_scope_guard.dart';
import 'package:brixel/features/materials/models/material_model.dart';
import 'package:brixel/features/materials/repositories/material_usage_write_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMaterialUsageWriteRepository implements MaterialUsageWriteRepository {
  MaterialTransactionModel? lastUsage;
  String? lastActiveSiteId;

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

    lastActiveSiteId = activeSiteId;
    lastUsage = usage;

    return 'generated-document-id';
  }
}

void main() {
  MaterialTransactionModel buildUsage({
    String siteId = 'site-jaipur-01',
    String type = 'used',
  }) {
    return MaterialTransactionModel(
      id: '',
      materialId: 'mat-cement-01',
      siteId: siteId,
      type: type,
      quantity: 35,
      notes: 'Used for slab work',
      recordedBy: 'user-supervisor-01',
      timestamp: DateTime(2026, 10, 14),
    );
  }

  test('adds usage for the active site and returns a document id', () async {
    final repository = FakeMaterialUsageWriteRepository();
    final usage = buildUsage();

    final documentId = await repository.addUsage(
      activeSiteId: 'site-jaipur-01',
      usage: usage,
    );

    expect(documentId, 'generated-document-id');
    expect(repository.lastActiveSiteId, 'site-jaipur-01');
    expect(repository.lastUsage, same(usage));
  });

  test('rejects usage for a different construction site', () async {
    final repository = FakeMaterialUsageWriteRepository();

    expect(
      () => repository.addUsage(
        activeSiteId: 'site-jaipur-01',
        usage: buildUsage(siteId: 'site-kota-02'),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });

  test('rejects a non-usage transaction', () async {
    final repository = FakeMaterialUsageWriteRepository();

    expect(
      () => repository.addUsage(
        activeSiteId: 'site-jaipur-01',
        usage: buildUsage(type: 'received'),
      ),
      throwsA(isA<ArgumentError>()),
    );
  });
}
