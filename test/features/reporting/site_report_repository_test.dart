import 'package:brixel/core/services/firestore_database_service.dart';
import 'package:brixel/features/reporting/repositories/site_report_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

class _Firestore extends Fake implements FirebaseFirestore {}

class _Database extends FirestoreDatabaseService {
  _Database() : super(firestore: _Firestore());
  final attendanceWrites = <Map<String, dynamic>>[];
  final usageWrites = <Map<String, dynamic>>[];
  Object? failure;
  @override
  Future<void> addAttendanceReport(Map<String, dynamic> payload) async {
    if (failure != null) throw failure!;
    attendanceWrites.add(payload);
  }

  @override
  Future<String> addMaterialTransaction(Map<String, dynamic> payload) async {
    if (failure != null) throw failure!;
    usageWrites.add(payload);
    return 'saved-report';
  }
}

void main() {
  test('attendance writes active site, verified author and server audit timestamps', () async {
    final database = _Database();
    final reports = SiteReportRepository(
      database: database,
      userId: () => 'signed-in-user',
    );
    await reports.saveAttendance('jaipur', {
      'workerName': 'Crew A',
      'trade': 'Masonry',
      'status': 'Present',
      'hoursWorked': 8,
      'siteId': 'wrong-site',
      'recordedBy': 'spoofed-user',
    });
    final payload = database.attendanceWrites.single;
    expect(payload['siteId'], 'jaipur');
    expect(payload['recordedBy'], 'signed-in-user');
    expect(payload['status'], 'present');
    expect(payload['date'], SiteReportRepository.dateKey(DateTime.now()));
    expect(payload['createdAt'], isA<FieldValue>());
    expect(payload['updatedAt'], isA<FieldValue>());
  });
  test(
    'usage retains reporting fields through the existing write repository',
    () async {
      final database = _Database();
      await SiteReportRepository(
        database: database,
        userId: () => 'signed-in-user',
      ).saveMaterial('ajmer', {
        'materialName': 'Cement',
        'quantity': 12,
        'unit': 'bags',
        'notes': 'Slab pour',
      });
      final payload = database.usageWrites.single;
      expect(payload['siteId'], 'ajmer');
      expect(payload['recordedBy'], 'signed-in-user');
      expect(payload['materialName'], 'Cement');
      expect(payload['unit'], 'bags');
      expect(payload['type'], 'used');
      expect(payload['timestamp'], isA<FieldValue>());
    },
  );
  test(
    'invalid identity, absent hours and persistence failure propagate',
    () async {
      final database = _Database();
      final anonymous = SiteReportRepository(
        database: database,
        userId: () => '',
      );
      final reports = SiteReportRepository(
        database: database,
        userId: () => 'supervisor',
      );
      final data = {
        'workerName': 'Crew A',
        'trade': 'Masonry',
        'status': 'Absent',
        'hoursWorked': 8,
      };
      await expectLater(
        anonymous.saveAttendance('jaipur', data),
        throwsStateError,
      );
      await expectLater(reports.saveAttendance('', data), throwsArgumentError);
      await expectLater(
        reports.saveAttendance('jaipur', data),
        throwsArgumentError,
      );
      database.failure = StateError('Unavailable');
      await expectLater(
        reports.saveAttendance('jaipur', {...data, 'hoursWorked': 0}),
        throwsStateError,
      );
      expect(database.attendanceWrites, isEmpty);
    },
  );
}
