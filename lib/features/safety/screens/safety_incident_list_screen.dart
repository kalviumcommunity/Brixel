import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/safety/models/incident_model.dart';
import 'package:brixel/features/safety/repositories/firestore_safety_incident_write_repository.dart';
import 'package:brixel/features/safety/repositories/safety_incident_write_repository.dart';
import 'package:brixel/features/safety/screens/safety_incident_form_screen.dart';
import 'package:brixel/features/sites/models/site.dart';
import 'package:brixel/shared/widgets/brixel_metric_card.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:flutter/material.dart';

enum IncidentFilter { all, reported, acknowledged, resolved }

class SafetyIncidentListScreen extends StatefulWidget {
  const SafetyIncidentListScreen({
    super.key,
    required this.site,
    this.repository,
    this.initialIncidents,
  });

  final Site site;
  final SafetyIncidentWriteRepository? repository;
  final List<IncidentModel>? initialIncidents;

  @override
  State<SafetyIncidentListScreen> createState() =>
      _SafetyIncidentListScreenState();
}

class _SafetyIncidentListScreenState extends State<SafetyIncidentListScreen> {
  late final SafetyIncidentWriteRepository _repository;
  late List<IncidentModel> _incidents;
  IncidentFilter _activeFilter = IncidentFilter.all;
  final Set<String> _updatingIds = {};

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? FirestoreSafetyIncidentWriteRepository();

    if (widget.initialIncidents != null) {
      _incidents = List.from(widget.initialIncidents!);
    } else {
      // Default initial records for the site demonstrating status progression
      final now = DateTime.now();
      _incidents = [
        IncidentModel(
          id: 'inc_${widget.site.id}_001',
          siteId: widget.site.id,
          incidentType: 'equipment_failure',
          severity: 'high',
          description:
              'Hydraulic oil leakage detected on Crane #2 hydraulic arm.',
          status: 'reported',
          reportedBy: 'usr_sup_101',
          createdAt: now.subtract(const Duration(hours: 3)),
        ),
        IncidentModel(
          id: 'inc_${widget.site.id}_002',
          siteId: widget.site.id,
          incidentType: 'hazard',
          severity: 'medium',
          description: 'Uncovered electrical trench near worker entry gate 3.',
          status: 'reported',
          reportedBy: 'usr_sup_102',
          createdAt: now.subtract(const Duration(hours: 5)),
        ),
        IncidentModel(
          id: 'inc_${widget.site.id}_003',
          siteId: widget.site.id,
          incidentType: 'injury',
          severity: 'critical',
          description:
              'Worker sustained wrist laceration during rebar cutting.',
          status: 'acknowledged',
          reportedBy: 'usr_sup_101',
          createdAt: now.subtract(const Duration(hours: 24)),
        ),
        IncidentModel(
          id: 'inc_${widget.site.id}_004',
          siteId: widget.site.id,
          incidentType: 'fall',
          severity: 'low',
          description:
              'Slip on wet scaffolding platform; safety harness arrested fall.',
          status: 'resolved',
          reportedBy: 'usr_sup_103',
          resolvedBy: 'usr_mgr_201',
          resolvedAt: now.subtract(const Duration(hours: 12)),
          createdAt: now.subtract(const Duration(days: 2)),
        ),
      ];
    }
  }

  int get _totalCount => _incidents.length;
  int get _reportedCount =>
      _incidents.where((i) => i.status == 'reported').length;
  int get _acknowledgedCount =>
      _incidents.where((i) => i.status == 'acknowledged').length;
  int get _resolvedCount =>
      _incidents.where((i) => i.status == 'resolved').length;

  List<IncidentModel> get _filteredIncidents {
    switch (_activeFilter) {
      case IncidentFilter.all:
        return _incidents;
      case IncidentFilter.reported:
        return _incidents.where((i) => i.status == 'reported').toList();
      case IncidentFilter.acknowledged:
        return _incidents.where((i) => i.status == 'acknowledged').toList();
      case IncidentFilter.resolved:
        return _incidents.where((i) => i.status == 'resolved').toList();
    }
  }

  Future<void> _updateStatus(IncidentModel incident, String newStatus) async {
    final incidentId = incident.id;
    setState(() {
      _updatingIds.add(incidentId);
    });

    try {
      // Precise Firestore update targeting document ID:
      // Modifies only status and resolution fields, preserving all other fields
      await _repository.updateIncidentStatus(
        incidentId: incidentId,
        status: newStatus,
        resolvedBy: newStatus == 'resolved' ? 'usr_sup_101' : null,
      );

      // Reflect update immediately in local state
      setState(() {
        final index = _incidents.indexWhere((i) => i.id == incidentId);
        if (index != -1) {
          final existing = _incidents[index];
          _incidents[index] = existing.copyWith(
            status: newStatus,
            resolvedBy: newStatus == 'resolved' ? 'usr_sup_101' : null,
            resolvedAt: newStatus == 'resolved' ? DateTime.now() : null,
          );
        }
      });

      if (!mounted) return;

      final label = newStatus[0].toUpperCase() + newStatus.substring(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Updated incident $incidentId status to $label'),
          backgroundColor: BrixelColors.success,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update incident: $e'),
          backgroundColor: BrixelColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _updatingIds.remove(incidentId);
        });
      }
    }
  }

  Color _severityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.deepPurple;
      case 'high':
        return BrixelColors.danger;
      case 'medium':
        return Colors.orange.shade800;
      case 'low':
      default:
        return Colors.teal;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
        return BrixelColors.success;
      case 'acknowledged':
        return Colors.blue.shade700;
      case 'reported':
      default:
        return Colors.orange.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final filtered = _filteredIncidents;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Safety Reports'),
            Text(
              widget.site.name,
              style: textTheme.bodySmall?.copyWith(
                color: BrixelColors.secondaryText,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            key: const Key('addIncidentButton'),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Report New Incident',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      SafetyIncidentFormScreen(siteName: widget.site.name),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Headcount / Metrics summary
            Row(
              children: [
                Expanded(
                  child: BrixelMetricCard(
                    title: 'Total Incidents',
                    value: '$_totalCount',
                    subtitle: 'Logged on site',
                    icon: Icons.shield_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BrixelMetricCard(
                    title: 'Active / Open',
                    value: '${_reportedCount + _acknowledgedCount}',
                    subtitle: 'Pending action',
                    icon: Icons.warning_amber_rounded,
                    accentColor: BrixelColors.danger,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: BrixelMetricCard(
                    title: 'Acknowledged',
                    value: '$_acknowledgedCount',
                    subtitle: 'In review',
                    icon: Icons.visibility_outlined,
                    accentColor: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: BrixelMetricCard(
                    title: 'Resolved',
                    value: '$_resolvedCount',
                    subtitle: 'Closed out',
                    icon: Icons.check_circle_outline,
                    accentColor: BrixelColors.success,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All ($_totalCount)', IncidentFilter.all),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Reported ($_reportedCount)',
                    IncidentFilter.reported,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Acknowledged ($_acknowledgedCount)',
                    IncidentFilter.acknowledged,
                  ),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                    'Resolved ($_resolvedCount)',
                    IncidentFilter.resolved,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Incidents List
            if (filtered.isEmpty)
              BrixelSectionCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: BrixelColors.success.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No incidents matching this filter',
                          style: textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Site conditions are clear and documented.',
                          style: textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final incident = filtered[index];
                  final isUpdating = _updatingIds.contains(incident.id);

                  return _buildIncidentCard(
                    context: context,
                    incident: incident,
                    isUpdating: isUpdating,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IncidentFilter filter) {
    final isSelected = _activeFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: BrixelColors.primarySoft,
      labelStyle: TextStyle(
        color: isSelected ? BrixelColors.primary : BrixelColors.secondaryText,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? BrixelColors.primary : BrixelColors.border,
      ),
      onSelected: (_) {
        setState(() {
          _activeFilter = filter;
        });
      },
    );
  }

  Widget _buildIncidentCard({
    required BuildContext context,
    required IncidentModel incident,
    required bool isUpdating,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final sevColor = _severityColor(incident.severity);
    final statColor = _statusColor(incident.status);

    return BrixelSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Severity & Type badges + Status chip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Wrap(
                spacing: 6,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: sevColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: sevColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      incident.severity.toUpperCase(),
                      style: TextStyle(
                        color: sevColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: BrixelColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: BrixelColors.border),
                    ),
                    child: Text(
                      incident.incidentType.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(
                        color: BrixelColors.primaryText,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                key: Key('statusBadge_${incident.id}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  incident.status[0].toUpperCase() +
                      incident.status.substring(1),
                  style: TextStyle(
                    color: statColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Document ID Badge (Carried explicitly from model)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Text(
              'Doc ID: ${incident.id}',
              key: Key('docId_${incident.id}'),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            incident.description,
            style: textTheme.bodyMedium?.copyWith(
              color: BrixelColors.primaryText,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Reporting metadata
          Row(
            children: [
              const Icon(
                Icons.person_outline,
                size: 14,
                color: BrixelColors.secondaryText,
              ),
              const SizedBox(width: 4),
              Text(
                'Reported by ${incident.reportedBy}',
                style: textTheme.bodySmall?.copyWith(
                  color: BrixelColors.secondaryText,
                ),
              ),
              if (incident.resolvedBy != null) ...[
                const SizedBox(width: 8),
                const Icon(
                  Icons.verified_outlined,
                  size: 14,
                  color: BrixelColors.success,
                ),
                const SizedBox(width: 4),
                Text(
                  'Resolved by ${incident.resolvedBy}',
                  style: textTheme.bodySmall?.copyWith(
                    color: BrixelColors.success,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: BrixelColors.border),
          const SizedBox(height: 10),

          // Interactive Action Buttons targeting this document ID
          if (isUpdating)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (incident.status == 'reported') ...[
                  OutlinedButton.icon(
                    key: Key('ack_${incident.id}'),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Acknowledge'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.blue.shade700,
                      side: BorderSide(color: Colors.blue.shade300),
                    ),
                    onPressed: () => _updateStatus(incident, 'acknowledged'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    key: Key('resolve_${incident.id}'),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Resolve'),
                    style: FilledButton.styleFrom(
                      backgroundColor: BrixelColors.success,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _updateStatus(incident, 'resolved'),
                  ),
                ] else if (incident.status == 'acknowledged') ...[
                  FilledButton.icon(
                    key: Key('resolve_${incident.id}'),
                    icon: const Icon(Icons.done_all, size: 16),
                    label: const Text('Mark Resolved'),
                    style: FilledButton.styleFrom(
                      backgroundColor: BrixelColors.success,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () => _updateStatus(incident, 'resolved'),
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: BrixelColors.success,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Resolved & Closed',
                        style: TextStyle(
                          color: BrixelColors.success,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      TextButton(
                        key: Key('reopen_${incident.id}'),
                        onPressed: () => _updateStatus(incident, 'reported'),
                        child: const Text('Reopen'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}
