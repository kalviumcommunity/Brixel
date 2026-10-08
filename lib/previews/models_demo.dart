import 'package:brixel/features/attendance/models/attendance_report.dart';
import 'package:brixel/features/auth/models/user_profile.dart';
import 'package:brixel/features/materials/models/material_usage.dart';
import 'package:brixel/features/safety/models/safety_incident.dart';
import 'package:brixel/features/sites/models/site.dart';
import 'package:flutter/foundation.dart';

void main() {
  final user = UserProfile(
    id: 'user-001',
    name: 'Demo Supervisor',
    email: 'supervisor@example.com',
    role: 'supervisor',
  );
  final site = Site(
    id: 'site-001',
    name: 'Jaipur Tower Project',
    location: 'Jaipur',
  );
  final attendance = AttendanceReport(
    siteId: site.id,
    expectedWorkers: 50,
    presentWorkers: 43,
    reportingDate: DateTime(2026, 10, 6),
    recordedAt: DateTime(2026, 10, 7, 9, 30),
  );
  final materialUsage = MaterialUsage(
    siteId: site.id,
    materialName: 'Cement',
    quantity: 35,
    unit: 'bags',
    reportingDate: DateTime(2026, 10, 6),
    recordedAt: DateTime(2026, 10, 7, 10),
  );
  final safetyIncident = SafetyIncident(
    siteId: site.id,
    description: 'Loose electrical cable near work area',
    location: 'Floor 2',
    severity: 'Medium',
    occurredAt: DateTime(2026, 10, 6, 14),
    recordedAt: DateTime(2026, 10, 6, 14, 20),
  );

  debugPrint('User: ${user.name} (${user.role})');
  debugPrint('Site: ${site.name}, ${site.location}');
  debugPrint(
    'Attendance: ${attendance.presentWorkers}/${attendance.expectedWorkers} '
    'present, ${attendance.absentWorkers} absent',
  );
  debugPrint(
    'Material used: ${materialUsage.quantity} ${materialUsage.unit} '
    'of ${materialUsage.materialName}',
  );
  debugPrint(
    'Safety incident: ${safetyIncident.description} '
    '(${safetyIncident.severity})',
  );
}
