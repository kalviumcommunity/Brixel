import 'package:brixel/features/attendance/models/attendance_model.dart';
import 'package:brixel/features/safety/models/incident_model.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const StatefulWidgetsDemoApp());
}

class StatefulWidgetsDemoApp extends StatelessWidget {
  const StatefulWidgetsDemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brixel Reporting Preview',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF426B4A)),
        useMaterial3: true,
      ),
      home: const StatefulReportingPreview(),
    );
  }
}

class StatefulReportingPreview extends StatefulWidget {
  const StatefulReportingPreview({super.key});

  @override
  State<StatefulReportingPreview> createState() =>
      _StatefulReportingPreviewState();
}

class _StatefulReportingPreviewState extends State<StatefulReportingPreview> {
  static const List<String> _severityOptions = [
    'low',
    'medium',
    'high',
    'critical',
  ];

  final List<AttendanceRecordModel> _attendanceRecords = [];
  late IncidentModel _incident = IncidentModel(
    id: 'preview-incident',
    siteId: 'preview-site',
    incidentType: 'hazard',
    severity: 'low',
    description: 'Preview safety incident',
    status: 'reported',
    reportedBy: 'preview-user',
    createdAt: DateTime.now(),
  );
  int _nextWorkerNumber = 1;

  int get _presentWorkers =>
      _attendanceRecords.where((record) => record.status == 'present').length;

  void _incrementWorkers() {
    setState(() {
      final workerNumber = _nextWorkerNumber++;
      final recordedAt = DateTime.now();
      _attendanceRecords.add(
        AttendanceRecordModel(
          id: 'preview-attendance-$workerNumber',
          siteId: 'preview-site',
          workerName: 'Worker $workerNumber',
          trade: 'General Laborer',
          status: 'present',
          hoursWorked: 8,
          date: recordedAt.toIso8601String().split('T').first,
          recordedBy: 'preview-user',
          createdAt: recordedAt,
        ),
      );
    });
  }

  void _decrementWorkers() {
    if (_attendanceRecords.isEmpty) return;

    setState(_attendanceRecords.removeLast);
  }

  void _selectSeverity(String severity) {
    if (severity == _incident.severity) return;

    setState(() {
      _incident = _incident.copyWith(severity: severity);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Brixel Reporting Preview')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance Preview',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text(
                            'Present Workers: $_presentWorkers',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton.filledTonal(
                              tooltip: 'Decrease present workers',
                              onPressed: _attendanceRecords.isEmpty
                                  ? null
                                  : _decrementWorkers,
                              icon: const Icon(Icons.remove),
                            ),
                            const SizedBox(width: 20),
                            IconButton.filledTonal(
                              tooltip: 'Increase present workers',
                              onPressed: _incrementWorkers,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safety Severity Preview',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          children: [
                            for (final severity in _severityOptions)
                              ChoiceChip(
                                label: Text(_capitalize(severity)),
                                selected: severity == _incident.severity,
                                onSelected: (_) => _selectSeverity(severity),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Selected severity: ${_capitalize(_incident.severity)}',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _capitalize(String value) =>
      '${value[0].toUpperCase()}${value.substring(1)}';
}
