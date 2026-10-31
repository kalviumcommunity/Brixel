import 'package:brixel/features/reporting/repositories/site_report_repository.dart';
import 'package:brixel/features/sites/models/site.dart';
import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:flutter/material.dart';

class SiteReportListScreen extends StatefulWidget {
  const SiteReportListScreen({
    super.key,
    required this.site,
    required this.materials,
    this.records,
  });
  final Site site;
  final bool materials;
  final Stream<List<Map<String, dynamic>>>? records;
  @override
  State<SiteReportListScreen> createState() => _SiteReportListScreenState();
}

class _SiteReportListScreenState extends State<SiteReportListScreen> {
  late Stream<List<Map<String, dynamic>>> _records;
  String _query = '';
  String _status = 'All';
  DateTime _date = DateTime.now();
  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    _records =
        widget.records ??
        SiteReportRepository().watch(
          widget.site.id,
          widget.materials ? 'material_transactions' : 'attendance',
        );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.materials ? 'Material usage' : 'Attendance'),
    ),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  widget.site.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (!widget.materials)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () => setState(
                          () => _date = _date.subtract(const Duration(days: 1)),
                        ),
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Text(SiteReportRepository.dateKey(_date)),
                      IconButton(
                        onPressed: () => setState(
                          () => _date = _date.add(const Duration(days: 1)),
                        ),
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                TextField(
                  onChanged: (value) =>
                      setState(() => _query = value.toLowerCase()),
                  decoration: InputDecoration(
                    hintText: widget.materials
                        ? 'Search materials'
                        : 'Search worker or trade',
                    prefixIcon: const Icon(Icons.search),
                  ),
                ),
                if (!widget.materials)
                  Wrap(
                    spacing: 8,
                    children: ['All', 'Present', 'Absent']
                        .map(
                          (status) => ChoiceChip(
                            label: Text(status),
                            selected: _status == status,
                            onSelected: (_) => setState(() => _status = status),
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _records,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Could not load reports.'),
                        TextButton(
                          onPressed: () => setState(_connect),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final records = snapshot.data!
                    .where(
                      (row) =>
                          row['siteId'] == widget.site.id &&
                          (widget.materials ||
                              row['date'] ==
                                  SiteReportRepository.dateKey(_date)) &&
                          (widget.materials ||
                              _status == 'All' ||
                              row['status'] == _status.toLowerCase()) &&
                          '${row['materialName']} ${row['workerName']} ${row['trade']}'
                              .toLowerCase()
                              .contains(_query) &&
                          (!widget.materials || row['type'] == 'used'),
                    )
                    .toList();
                if (records.isEmpty) {
                  return const Center(
                    child: Text('No reports match this selection.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: records.length,
                  separatorBuilder: (_, index) =>
                      const Divider(color: BrixelColors.border),
                  itemBuilder: (context, index) {
                    final row = records[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: BrixelColors.primarySoft,
                        child: Icon(
                          widget.materials
                              ? Icons.inventory_2_outlined
                              : Icons.person_outline,
                          color: BrixelColors.primary,
                        ),
                      ),
                      title: Text(
                        '${row[widget.materials ? 'materialName' : 'workerName'] ?? 'Report'}',
                      ),
                      subtitle: Text(
                        widget.materials
                            ? '${row['quantity']} ${row['unit'] ?? ''}\n${row['notes'] ?? ''}'
                            : '${row['trade']} • ${row['hoursWorked']} hours',
                      ),
                      trailing: widget.materials
                          ? null
                          : Text(
                              '${row['status']}',
                              style: const TextStyle(
                                color: BrixelColors.success,
                              ),
                            ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
