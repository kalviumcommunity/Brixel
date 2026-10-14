import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/shared/widgets/brixel_primary_button.dart';
import 'package:brixel/shared/widgets/brixel_worker_card.dart';
import 'package:flutter/material.dart';

/// Represents a single worker's attendance record in the daily roster.
class WorkerAttendanceItem {
  final String id;
  final String name;
  final String role;
  final String workerId;
  final String status;

  const WorkerAttendanceItem({
    required this.id,
    required this.name,
    required this.role,
    required this.workerId,
    this.status = 'Present',
  });

  bool get isPresent =>
      status.toLowerCase() == 'present' || status.toLowerCase() == 'on-site';

  WorkerAttendanceItem copyWith({String? status}) {
    return WorkerAttendanceItem(
      id: id,
      name: name,
      role: role,
      workerId: workerId,
      status: status ?? this.status,
    );
  }
}

/// Filter options for worker attendance list.
enum AttendanceFilter { all, present, absent }

/// Interactive attendance roster screen demonstrating basic state management.
///
/// Holds mutable local state:
/// - [_workers]: List of worker records whose status can be toggled.
/// - [_activeFilter]: Selected tab filter (All, Present, Absent).
/// - [_selectedDate]: Currently active reporting date.
class AttendanceTrackerScreen extends StatefulWidget {
  const AttendanceTrackerScreen({
    super.key,
    this.initialWorkers,
    this.initialDate,
    this.siteName,
  });

  final List<WorkerAttendanceItem>? initialWorkers;
  final DateTime? initialDate;
  final String? siteName;

  static List<WorkerAttendanceItem> defaultWorkers() => [
    const WorkerAttendanceItem(
      id: 'w-001',
      name: 'Ramesh Kumar',
      role: 'Mason',
      workerId: 'W-001',
      status: 'Present',
    ),
    const WorkerAttendanceItem(
      id: 'w-002',
      name: 'Suresh Yadav',
      role: 'Helper',
      workerId: 'W-002',
      status: 'Present',
    ),
    const WorkerAttendanceItem(
      id: 'w-003',
      name: 'Imran Shaikh',
      role: 'Electrician',
      workerId: 'W-003',
      status: 'Present',
    ),
    const WorkerAttendanceItem(
      id: 'w-004',
      name: 'Pooja Singh',
      role: 'Supervisor',
      workerId: 'W-004',
      status: 'Present',
    ),
    const WorkerAttendanceItem(
      id: 'w-005',
      name: 'Vikram Patel',
      role: 'Mason',
      workerId: 'W-005',
      status: 'Present',
    ),
  ];

  @override
  State<AttendanceTrackerScreen> createState() =>
      _AttendanceTrackerScreenState();
}

class _AttendanceTrackerScreenState extends State<AttendanceTrackerScreen> {
  // State variables
  late List<WorkerAttendanceItem> _workers;
  late DateTime _selectedDate;
  AttendanceFilter _activeFilter = AttendanceFilter.all;

  @override
  void initState() {
    super.initState();
    _workers = List<WorkerAttendanceItem>.from(
      widget.initialWorkers ?? AttendanceTrackerScreen.defaultWorkers(),
    );
    _selectedDate = widget.initialDate ?? DateTime(2026, 10, 6);
  }

  // Computed state properties
  int get _presentCount => _workers.where((w) => w.isPresent).length;
  int get _absentCount => _workers.where((w) => !w.isPresent).length;
  int get _totalCount => _workers.length;

  List<WorkerAttendanceItem> get _filteredWorkers {
    switch (_activeFilter) {
      case AttendanceFilter.present:
        return _workers.where((w) => w.isPresent).toList();
      case AttendanceFilter.absent:
        return _workers.where((w) => !w.isPresent).toList();
      case AttendanceFilter.all:
        return _workers;
    }
  }

  // State mutation methods with setState()
  void _toggleWorkerStatus(String workerId) {
    setState(() {
      final index = _workers.indexWhere((w) => w.workerId == workerId);
      if (index != -1) {
        final current = _workers[index];
        final nextStatus = current.isPresent ? 'Absent' : 'Present';
        _workers[index] = current.copyWith(status: nextStatus);
      }
    });
  }

  void _selectFilter(AttendanceFilter filter) {
    if (_activeFilter == filter) return;
    setState(() {
      _activeFilter = filter;
    });
  }

  void _previousDay() {
    setState(() {
      _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    });
  }

  void _nextDay() {
    setState(() {
      _selectedDate = _selectedDate.add(const Duration(days: 1));
    });
  }

  void _markAllPresent() {
    setState(() {
      _workers = _workers.map((w) => w.copyWith(status: 'Present')).toList();
    });
  }

  void _markAllAbsent() {
    setState(() {
      _workers = _workers.map((w) => w.copyWith(status: 'Absent')).toList();
    });
  }

  String _formatDate(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, ${date.day} $month ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayedWorkers = _filteredWorkers;

    return Scaffold(
      backgroundColor: BrixelColors.background,
      appBar: AppBar(
        title: Text(
          widget.siteName != null
              ? '${widget.siteName} Attendance'
              : 'Attendance Roster',
        ),
        actions: [
          IconButton(
            key: const Key('markAllPresentButton'),
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all present',
            onPressed: _markAllPresent,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date Switcher Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    key: const Key('previousDateButton'),
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _previousDay,
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _formatDate(_selectedDate),
                    key: const Key('currentDateText'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: BrixelColors.primaryText,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    key: const Key('nextDateButton'),
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _nextDay,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Headcount Summary Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: BrixelColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: BrixelColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricItem(
                      label: 'Total Crew',
                      value: '$_totalCount',
                      color: BrixelColors.primaryText,
                    ),
                    Container(height: 28, width: 1, color: BrixelColors.border),
                    _buildMetricItem(
                      label: 'Present',
                      value: '$_presentCount',
                      color: BrixelColors.success,
                    ),
                    Container(height: 28, width: 1, color: BrixelColors.border),
                    _buildMetricItem(
                      label: 'Absent',
                      value: '$_absentCount',
                      color: BrixelColors.danger,
                    ),
                  ],
                ),
              ),
            ),

            // Segmented Status Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  _buildFilterTab(
                    key: const Key('filterAllTab'),
                    label: 'All ($_totalCount)',
                    filter: AttendanceFilter.all,
                  ),
                  _buildFilterTab(
                    key: const Key('filterPresentTab'),
                    label: 'On-Site ($_presentCount)',
                    filter: AttendanceFilter.present,
                  ),
                  _buildFilterTab(
                    key: const Key('filterAbsentTab'),
                    label: 'Absent ($_absentCount)',
                    filter: AttendanceFilter.absent,
                  ),
                ],
              ),
            ),

            // Worker List
            Expanded(
              child: displayedWorkers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.group_off_outlined,
                            size: 48,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No workers in this category.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: BrixelColors.secondaryText,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
                      ),
                      itemCount: displayedWorkers.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final worker = displayedWorkers[index];
                        return BrixelWorkerCard(
                          key: Key('workerCard_${worker.workerId}'),
                          name: worker.name,
                          role: worker.role,
                          workerId: worker.workerId,
                          status: worker.status,
                          onTap: () => _toggleWorkerStatus(worker.workerId),
                        );
                      },
                    ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      key: const Key('markAllAbsentButton'),
                      icon: const Icon(Icons.clear, size: 18),
                      label: const Text('Mark All Absent'),
                      onPressed: _markAllAbsent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: BrixelPrimaryButton(
                      key: const Key('markAllPresentCta'),
                      label: 'Mark All Present',
                      icon: Icons.check,
                      onPressed: _markAllPresent,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: BrixelColors.secondaryText,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFilterTab({
    required Key key,
    required String label,
    required AttendanceFilter filter,
  }) {
    final isSelected = _activeFilter == filter;

    return Expanded(
      child: InkWell(
        key: key,
        borderRadius: BorderRadius.circular(8),
        onTap: () => _selectFilter(filter),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? BrixelColors.primary : Colors.transparent,
                width: 2.5,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? BrixelColors.primary
                  : BrixelColors.secondaryText,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
