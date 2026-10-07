import 'package:brixel/features/attendance/repositories/attendance_repository.dart';
import 'package:brixel/features/attendance/services/attendance_service.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAttendanceRepository implements AttendanceRepository {
  final List<String> events;

  FakeAttendanceRepository(this.events);

  @override
  Future<void> saveAttendance() async {
    events.add('repository started');

    await Future.delayed(const Duration(milliseconds: 50));

    events.add('repository finished');
  }
}

void main() {
  test('submitAttendance waits for repository operation to finish', () async {
    final events = <String>[];

    final repository = FakeAttendanceRepository(events);
    final service = AttendanceService(repository);

    events.add('service started');

    await service.submitAttendance();

    events.add('service finished');

    expect(events, [
      'service started',
      'repository started',
      'repository finished',
      'service finished',
    ]);
  });
}
