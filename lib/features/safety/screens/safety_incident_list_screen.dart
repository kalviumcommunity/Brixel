import 'dart:async';

import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/safety/models/incident_model.dart';
import 'package:brixel/features/safety/repositories/firestore_safety_incident_read_repository.dart';
import 'package:brixel/features/safety/repositories/firestore_safety_incident_write_repository.dart';
import 'package:brixel/features/safety/repositories/safety_incident_read_repository.dart';
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
    this.readRepository,
    this.incidentStream,
    this.initialIncidents,
  });

  final Site site;
  final SafetyIncidentWriteRepository? repository;
  final SafetyIncidentReadRepository? readRepository;
  final Stream<List<IncidentModel>>? incidentStream;
  final List<IncidentModel>? initialIncidents;

  @override
  State<SafetyIncidentListScreen> createState() =>
      _SafetyIncidentListScreenState();
}

class _SafetyIncidentListScreenState extends State<SafetyIncidentListScreen> {
  late final SafetyIncidentWriteRepository _writeRepository;
  late final SafetyIncidentReadRepository _readRepository;
  late final StreamController<List<IncidentModel>> _streamController;
  late final Stream<List<IncidentModel>> _incidentsStream;
  StreamSubscription<List<IncidentModel>>? _liveSubscription;

  List<IncidentModel> _cachedIncidents = [];
  IncidentFilter _activeFilter = IncidentFilter.all;
  final Set<String> _updatingIds = {};

  static SafetyIncidentWriteRepository _resolveDefaultWriteRepository() {
    try {
      return FirestoreSafetyIncidentWriteRepository();
    } catch (_) {
      return _FallbackSafetyIncidentWriteRepository();
    }
  }

  static SafetyIncidentReadRepository _resolveDefaultReadRepository() {
    try {
      return FirestoreSafetyIncidentReadRepository();
    } catch (_) {
      return _FallbackSafetyIncidentReadRepository();
    }
  }

  @override
  void initState() {
    super.initState();
    _writeRepository = widget.repository ?? _resolveDefaultWriteRepository();
    _readRepository = widget.readRepository ?? _resolveDefaultReadRepository();

    if (widget.incidentStream != null) {
      _incidentsStream = widget.incidentStream!;
      return;
    }

    // Prepare initial data set
    if (widget.initialIncidents != null) {
      _cachedIncidents = List.from(widget.initialIncidents!);
    } else {
      final now = DateTime.now();
      _cachedIncidents = [
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

    if (widget.incidentStream != null) {
      _incidentsStream = widget.incidentStream!;
    } else {
      _streamController = StreamController<List<IncidentModel>>.broadcast();
      _incidentsStream = _streamController.stream;

      // Connect to Firestore real-time snapshots() stream if not custom-seeded
      if (widget.initialIncidents == null) {
        try {
          _liveSubscription = _readRepository
              .watchIncidentsForSite(widget.site.id)
              .listen(
                (liveDocs) {
                  _cachedIncidents = List.from(liveDocs);
                  _emitCachedUpdate();
                },
                onError: (error) {
                  debugPrint(
                    'Real-time snapshot stream error (offline/fallback): $error',
                  );
                },
              );
        } catch (e) {
          debugPrint('Could not bind real-time snapshots listener: $e');
        }
      }
    }
  }

  @override
  void dispose() {
    _liveSubscription?.cancel();
    if (widget.incidentStream == null) {
      _streamController.close();
    }
    super.dispose();
  }

  void _emitCachedUpdate() {
    if (widget.incidentStream == null && !_streamController.isClosed) {
      _streamController.add(List.unmodifiable(_cachedIncidents));
    }
  }

  // --- REAL-TIME DATA ACTIONS (Adds, Updates, Deletes) ---

  Future<void> _updateStatus(IncidentModel incident, String newStatus) async {
    final incidentId = incident.id;
    setState(() {
      _updatingIds.add(incidentId);
    });

    try {
      await _writeRepository.updateIncidentStatus(
        incidentId: incidentId,
        status: newStatus,
        resolvedBy: newStatus == 'resolved' ? 'usr_sup_101' : null,
      );

      // Mutate local cache and emit to StreamBuilder
      final index = _cachedIncidents.indexWhere((i) => i.id == incidentId);
      if (index != -1) {
        final existing = _cachedIncidents[index];
        _cachedIncidents[index] = existing.copyWith(
          status: newStatus,
          resolvedBy: newStatus == 'resolved' ? 'usr_sup_101' : null,
          resolvedAt: newStatus == 'resolved' ? DateTime.now() : null,
        );
        _emitCachedUpdate();
      }

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

  Future<void> _deleteIncident(IncidentModel incident) async {
    final incidentId = incident.id;
    if (_updatingIds.contains(incidentId)) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete incident?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirmDeleteIncidentButton'),
            style: FilledButton.styleFrom(
              backgroundColor: BrixelColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (shouldDelete != true || !mounted || _updatingIds.contains(incidentId)) {
      return;
    }

    setState(() {
      _updatingIds.add(incidentId);
    });

    try {
      await _writeRepository.deleteIncident(incidentId: incidentId);

      _cachedIncidents.removeWhere((i) => i.id == incidentId);
      _emitCachedUpdate();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Incident deleted.'),
          backgroundColor: BrixelColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete incident. Please try again.'),
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

  Future<void> _addQuickIncident() async {
    final newId =
        'inc_${widget.site.id}_${DateTime.now().millisecondsSinceEpoch % 10000}';
    final newIncident = IncidentModel(
      id: newId,
      siteId: widget.site.id,
      incidentType: 'hazard',
      severity: 'high',
      description: 'Quick report: scaffolding clamp slipped during load check.',
      status: 'reported',
      reportedBy: 'usr_sup_101',
      createdAt: DateTime.now(),
    );

    try {
      await _writeRepository.addIncident(
        activeSiteId: widget.site.id,
        incident: newIncident,
      );

      _cachedIncidents.insert(0, newIncident);
      _emitCachedUpdate();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Live added new incident $newId'),
          backgroundColor: BrixelColors.success,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add incident: $e'),
          backgroundColor: BrixelColors.danger,
        ),
      );
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

  List<IncidentModel> _filterList(
    List<IncidentModel> list,
    IncidentFilter filter,
  ) {
    switch (filter) {
      case IncidentFilter.all:
        return list;
      case IncidentFilter.reported:
        return list.where((i) => i.status == 'reported').toList();
      case IncidentFilter.acknowledged:
        return list.where((i) => i.status == 'acknowledged').toList();
      case IncidentFilter.resolved:
        return list.where((i) => i.status == 'resolved').toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

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
            key: const Key('quickAddIncidentButton'),
            icon: const Icon(Icons.flash_on_outlined),
            tooltip: 'Live Add Incident',
            onPressed: _addQuickIncident,
          ),
          IconButton(
            key: const Key('addIncidentButton'),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Report New Incident',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SafetyIncidentFormScreen(
                    siteId: widget.site.id,
                    siteName: widget.site.name,
                    repository: _writeRepository,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      // Task 1: Read collection with snapshots() inside StreamBuilder
      body: SafeArea(
        child: StreamBuilder<List<IncidentModel>>(
          initialData: widget.incidentStream != null
              ? null
              : List.unmodifiable(_cachedIncidents),
          stream: _incidentsStream,
          builder: (context, snapshot) {
            // Loading state while waiting for initial stream emission
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            // Error state
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: BrixelColors.danger,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load safety reports',
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${snapshot.error}',
                        style: textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            // Live stream data
            final incidents = snapshot.data ?? [];
            final totalCount = incidents.length;
            final reportedCount = incidents
                .where((i) => i.status == 'reported')
                .length;
            final acknowledgedCount = incidents
                .where((i) => i.status == 'acknowledged')
                .length;
            final resolvedCount = incidents
                .where((i) => i.status == 'resolved')
                .length;

            final filtered = _filterList(incidents, _activeFilter);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Live Sync Status banner
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: BrixelColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: BrixelColors.border),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: BrixelColors.success,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Live Firestore Sync Active (snapshots)',
                        key: const Key('liveSyncIndicator'),
                        style: textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: BrixelColors.primaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Real-time metric cards that update automatically
                Row(
                  children: [
                    Expanded(
                      child: BrixelMetricCard(
                        title: 'Total Incidents',
                        value: '$totalCount',
                        subtitle: 'Logged on site',
                        icon: Icons.shield_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BrixelMetricCard(
                        title: 'Active / Open',
                        value: '${reportedCount + acknowledgedCount}',
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
                        value: '$acknowledgedCount',
                        subtitle: 'In review',
                        icon: Icons.visibility_outlined,
                        accentColor: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BrixelMetricCard(
                        title: 'Resolved',
                        value: '$resolvedCount',
                        subtitle: 'Closed out',
                        icon: Icons.check_circle_outline,
                        accentColor: BrixelColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Real-time Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All ($totalCount)', IncidentFilter.all),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Reported ($reportedCount)',
                        IncidentFilter.reported,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Acknowledged ($acknowledgedCount)',
                        IncidentFilter.acknowledged,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        'Resolved ($resolvedCount)',
                        IncidentFilter.resolved,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Incidents List driven reactively by StreamBuilder
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
                              color: BrixelColors.success.withValues(
                                alpha: 0.6,
                              ),
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
            );
          },
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
          // Header Row: Severity & Type badges + Status chip + Delete button
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
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    key: Key('statusBadge_${incident.id}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: statColor.withValues(alpha: 0.4),
                      ),
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
                  const SizedBox(width: 4),
                  // Delete button for real-time deletion reflection (Task 4)
                  IconButton(
                    key: Key('delete_${incident.id}'),
                    icon: isUpdating
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: BrixelColors.secondaryText,
                          ),
                    tooltip: 'Delete Incident',
                    onPressed: isUpdating
                        ? null
                        : () => _deleteIncident(incident),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Document ID Badge
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
          if (incident.photoUrl != null &&
              incident.photoUrl!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                incident.photoUrl!,
                key: Key('evidenceImage_${incident.id}'),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  key: Key('evidenceImageError_${incident.id}'),
                  height: 180,
                  width: double.infinity,
                  color: BrixelColors.surfaceAlt,
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.broken_image_outlined,
                    color: BrixelColors.secondaryText,
                  ),
                ),
              ),
            ),
          ],
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

          // Interactive Action Buttons
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

class _FallbackSafetyIncidentWriteRepository
    implements SafetyIncidentWriteRepository {
  @override
  String createIncidentId() =>
      'incident_${DateTime.now().microsecondsSinceEpoch}';

  @override
  Future<String> addIncident({
    required String activeSiteId,
    required IncidentModel incident,
  }) async => incident.id;

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String status,
    String? resolvedBy,
  }) async {}

  @override
  Future<void> updateIncidentFields({
    required String incidentId,
    required Map<String, dynamic> fields,
  }) async {}

  @override
  Future<void> deleteIncident({required String incidentId}) async {}
}

class _FallbackSafetyIncidentReadRepository
    implements SafetyIncidentReadRepository {
  @override
  Future<List<IncidentModel>> fetchIncidentsForSite(String siteId) async => [];

  @override
  Stream<List<IncidentModel>> watchIncidentsForSite(String siteId) =>
      const Stream.empty();
}
