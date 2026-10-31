import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/reporting/repositories/site_report_repository.dart';
import 'package:brixel/features/reporting/screens/site_report_list_screen.dart';
import 'package:brixel/features/safety/screens/safety_incident_list_screen.dart';
import 'package:brixel/features/sites/models/site.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:flutter/material.dart';

class SiteDashboardScreen extends StatelessWidget {
  const SiteDashboardScreen({
    super.key,
    required this.site,
    this.displayName,
    this.reports,
  });
  final Site site;
  final String? displayName;
  final SiteReportRepository? reports;

  void _open(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Good morning,\n${displayName?.trim().isNotEmpty == true ? displayName : 'Welcome'}!',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              const CircleAvatar(
                backgroundColor: BrixelColors.primarySoft,
                child: Icon(Icons.engineering, color: BrixelColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(
                Icons.location_on,
                size: 18,
                color: BrixelColors.primary,
              ),
              const SizedBox(width: 6),
              Expanded(child: Text(site.name)),
              const Icon(Icons.keyboard_arrow_down, size: 18),
            ],
          ),
          const SizedBox(height: 24),
          Text('Site overview', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: width,
                    child: _DashboardCard(
                      title: 'Attendance',
                      icon: Icons.groups_outlined,
                      records: reports?.watch(site.id, 'attendance'),
                      describe: (rows) {
                        final today = rows
                            .where(
                              (r) =>
                                  r['date'] ==
                                  SiteReportRepository.dateKey(DateTime.now()),
                            )
                            .toList();
                        return today.isEmpty
                            ? 'No report today'
                            : '${today.where((r) => r['status'] == 'present').length} / ${today.length} present';
                      },
                      onTap: () => _open(
                        context,
                        SiteReportListScreen(site: site, materials: false),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _DashboardCard(
                      title: 'Materials',
                      icon: Icons.inventory_2_outlined,
                      records: reports?.watch(site.id, 'material_transactions'),
                      describe: (rows) =>
                          '${rows.where((r) => r['type'] == 'used').length} usage reports',
                      onTap: () => _open(
                        context,
                        SiteReportListScreen(site: site, materials: true),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _DashboardCard(
                      title: 'Safety',
                      icon: Icons.warning_amber_rounded,
                      records: reports?.watch(site.id, 'incidents'),
                      describe: (rows) =>
                          '${rows.where((r) => r['status'] != 'resolved').length} open incidents',
                      onTap: () =>
                          _open(context, SafetyIncidentListScreen(site: site)),
                    ),
                  ),
                  SizedBox(
                    width: width,
                    child: _DashboardCard(
                      title: 'Reports',
                      icon: Icons.description_outlined,
                      onTap: () =>
                          _open(context, SafetyIncidentListScreen(site: site)),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          BrixelSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active site',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(site.name),
                const SizedBox(height: 4),
                Text(site.location),
                const SizedBox(height: 12),
                const Text('Keep everyone in sync with current site reports.'),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _DashboardCard extends StatelessWidget {
  const _DashboardCard({
    required this.title,
    required this.icon,
    required this.onTap,
    this.records,
    this.describe,
  });
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  final Stream<List<Map<String, dynamic>>>? records;
  final String Function(List<Map<String, dynamic>>)? describe;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: BrixelSectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: BrixelColors.primarySoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: BrixelColors.primary),
          ),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          if (records == null)
            const Text('View reports')
          else
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: records,
              builder: (context, snapshot) {
                if (snapshot.hasError) return const Text('Unavailable');
                if (!snapshot.hasData) return const Text('Loading…');
                return Text(describe!(snapshot.data!));
              },
            ),
        ],
      ),
    ),
  );
}
