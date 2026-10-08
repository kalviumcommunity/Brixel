import 'package:brixel/features/materials/models/material_usage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores material quantity and unit separately', () {
    final reportingDate = DateTime(2026, 10, 6);
    final recordedAt = DateTime(2026, 10, 7, 10);
    final usage = MaterialUsage(
      siteId: 'site-001',
      materialName: 'Cement',
      quantity: 35,
      unit: 'bags',
      reportingDate: reportingDate,
      recordedAt: recordedAt,
    );

    expect(usage.siteId, 'site-001');
    expect(usage.materialName, 'Cement');
    expect(usage.quantity, 35);
    expect(usage.unit, 'bags');
    expect(usage.reportingDate, reportingDate);
    expect(usage.recordedAt, recordedAt);
    expect(usage.reportingDate, isNot(usage.recordedAt));
  });
}
