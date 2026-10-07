import '../repositories/attendance_repository.dart';

class AttendanceService {
  final AttendanceRepository repository;

  AttendanceService(this.repository);

  Future<void> submitAttendance() async {
    await repository.saveAttendance();
  }
}