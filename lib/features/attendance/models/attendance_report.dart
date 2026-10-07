class AttendanceReport {
  final String siteId;
  final int expectedWorkers;
  final int presentWorkers;
  final DateTime reportingDate;
  final DateTime recordedAt;

  const AttendanceReport({
    required this.siteId,
    required this.expectedWorkers,
    required this.presentWorkers,
    required this.reportingDate,
    required this.recordedAt,
  });

  int get absentWorkers => expectedWorkers - presentWorkers;
}