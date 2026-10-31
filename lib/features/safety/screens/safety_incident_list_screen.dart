import 'package:brixel/features/auth/services/firebase_auth_service.dart';

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
    this.currentUserId,
  });

  final Site site;
  final String? currentUserId;
  final SafetyIncidentWriteRepository? repository;
  final SafetyIncidentReadRepository? readRepository;
  final Stream<List<IncidentModel>>? incidentStream;
  final List<IncidentModel>? initialIncidents;

  @override
  State<SafetyIncidentListScreen> createState() =>
      _SafetyIncidentListScreenState();
}

class _SafetyIncidentListScreenState extends State<SafetyIncidentListScreen> {
  late final SafetyIncidentWriteRepository _writeRepository =
      widget.repository ?? FirestoreSafetyIncidentWriteRepository();
  late final SafetyIncidentReadRepository _readRepository =
      widget.readRepository ?? FirestoreSafetyIncidentReadRepository();
  late final StreamController<List<IncidentModel>> _streamController;
  late final Stream<List<IncidentModel>> _incidentsStream;
  StreamSubscription<List<IncidentModel>>? _liveSubscription;

  List<IncidentModel> _cachedIncidents = [];
  IncidentFilter _activeFilter = IncidentFilter.all;
  final Set<String> _updatingIds = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    if (widget.incidentStream != null) {
      _incidentsStream = widget.incidentStream!;
      return;
    }

    _streamController = StreamController<List<IncidentModel>>();
    _incidentsStream = _streamController.stream;
    if (widget.initialIncidents != null) {
      _cachedIncidents = List.from(widget.initialIncidents!);
      _emitCachedUpdate();
    } else {
      _watchLiveIncidents();
    }
  }

  void _watchLiveIncidents() {
    try {
      _liveSubscription = _readRepository
          .watchIncidentsForSite(widget.site.id)
          .listen(
            (records) {
              _cachedIncidents = List.from(records);
              _emitCachedUpdate();
            },
            onError: (Object error, StackTrace stack) {
              _streamController.addError(error, stack);
            },
          );
    } catch (error, stack) {
      _streamController.addError(error, stack);
    }
  }

  Future<void> _retryLoad() async {
    await _liveSubscription?.cancel();
    if (!mounted) return;
    _watchLiveIncidents();
  }

  @override
  void dispose() {
    _searchController.dispose();
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
      final resolver = newStatus == 'resolved'
          ? (widget.currentUserId ?? FirebaseAuthService().currentUser?.uid)
          : null;
      if (newStatus == 'resolved' && (resolver == null || resolver.isEmpty)) {
        throw StateError('Account unavailable.');
      }
      await _writeRepository.updateIncidentStatus(
        incidentId: incidentId,
        status: newStatus,
        resolvedBy: resolver,
      );

      // Mutate local cache and emit to StreamBuilder
      final index = _cachedIncidents.indexWhere((i) => i.id == incidentId);
      if (index != -1) {
        final existing = _cachedIncidents[index];
        _cachedIncidents[index] = existing.copyWith(
          status: newStatus,
          resolvedBy: resolver,
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
          content: Text(
            'Could not update the safety incident. Please try again.',
          ),
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

  Future<void> _confirmDeleteIncident(IncidentModel incident) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete safety incident?'),
          content: Text(
            'Are you sure you want to delete incident ${incident.id}? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              key: const Key('cancelDeleteButton'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirmDeleteButton'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await _deleteIncident(incident);
  }

  Future<void> _deleteIncident(IncidentModel incident) async {
    final incidentId = incident.id;
    if (_updatingIds.contains(incidentId)) return;

    if (!mounted || _updatingIds.contains(incidentId)) {
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
        SnackBar(
          content: Text(
            'Could not delete the safety incident. Please try again.',
          ),
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

  List<IncidentModel> _filterList(
    List<IncidentModel> list,
    IncidentFilter filter, [
    String query = '',
  ]) {
    final q = query.trim().toLowerCase();
    return list.where((incident) {
      final matchesFilter = switch (filter) {
        IncidentFilter.all => true,
        IncidentFilter.reported => incident.status == 'reported',
        IncidentFilter.acknowledged => incident.status == 'acknowledged',
        IncidentFilter.resolved => incident.status == 'resolved',
      };
      if (!matchesFilter) return false;

      if (q.isEmpty) return true;

      return incident.description.toLowerCase().contains(q) ||
          incident.incidentType.toLowerCase().contains(q) ||
          incident.id.toLowerCase().contains(q) ||
          incident.severity.toLowerCase().contains(q);
    }).toList();
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
          initialData: widget.initialIncidents,
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
                        'Please check your connection and try again.',
                        style: textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      if (widget.incidentStream == null &&
                          widget.initialIncidents == null)
                        TextButton(
                          onPressed: _retryLoad,
                          child: const Text('Retry'),
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

            final filtered = _filterList(
              incidents,
              _activeFilter,
              _searchQuery,
            );

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
                        'Site safety reports',
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

                // Task 1, 2, 3 & 4: Real-time Live Search Input Field
                TextField(
                  key: const Key('incidentSearchField'),
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search incidents by type, description, or ID...',
                    hintStyle: textTheme.bodyMedium?.copyWith(
                      color: BrixelColors.secondaryText,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: BrixelColors.secondaryText,
                    ),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            key: const Key('clearSearchButton'),
                            icon: const Icon(
                              Icons.clear,
                              color: BrixelColors.secondaryText,
                            ),
                            tooltip: 'Clear search',
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: BrixelColors.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: BrixelColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: BrixelColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(
                        color: BrixelColors.primary,
                        width: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

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
                      padding: const EdgeInsets.symmetric(
                        vertical: 24,
                        horizontal: 16,
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off_outlined
                                  : Icons.check_circle_outline,
                              size: 48,
                              color: _searchQuery.isNotEmpty
                                  ? BrixelColors.secondaryText.withValues(
                                      alpha: 0.6,
                                    )
                                  : BrixelColors.success.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No matching incidents found'
                                  : 'No incidents matching this filter',
                              style: textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No records match "$_searchQuery". Try checking your spelling or selecting another filter.'
                                  : 'Site conditions are clear and documented.',
                              style: textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                            if (_searchQuery.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                key: const Key('emptyStateClearButton'),
                                icon: const Icon(Icons.clear, size: 16),
                                label: const Text('Clear Search'),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              ),
                            ],
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
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
                        : () => _confirmDeleteIncident(incident),
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
          Wrap(
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
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
