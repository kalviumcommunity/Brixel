import 'package:brixel/features/attendance/models/attendance_report.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores the attendance report fields and calculates absences', () {
    final reportingDate = DateTime(2026, 10, 6);
    final recordedAt = DateTime(2026, 10, 7, 9, 30);
    final report = AttendanceReport(
      siteId: 'site-001',
      expectedWorkers: 50,
      presentWorkers: 43,
      reportingDate: reportingDate,
      recordedAt: recordedAt,
    );

    expect(report.siteId, 'site-001');
    expect(report.expectedWorkers, 50);
    expect(report.presentWorkers, 43);
    expect(report.reportingDate, reportingDate);
    expect(report.recordedAt, recordedAt);
    expect(report.reportingDate, isNot(report.recordedAt));
    expect(report.absentWorkers, 7);
  });
}
