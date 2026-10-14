import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/attendance/screens/attendance_tracker_screen.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AttendancePreviewApp());
}

class AttendancePreviewApp extends StatelessWidget {
  const AttendancePreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brixel Attendance',
      theme: buildBrixelTheme(),
      home: const AttendancePreviewScreen(),
    );
  }
}

class AttendancePreviewScreen extends StatelessWidget {
  const AttendancePreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AttendanceTrackerScreen();
  }
}
