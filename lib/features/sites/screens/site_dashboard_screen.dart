import 'package:brixel/features/sites/models/site.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:flutter/material.dart';

class SiteDashboardScreen extends StatelessWidget {
  const SiteDashboardScreen({super.key, required this.site});

  final Site site;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(site.name)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Site overview', style: textTheme.headlineSmall),
            const SizedBox(height: 12),
            BrixelSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.name,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined),
                      const SizedBox(width: 8),
                      Expanded(child: Text(site.location)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('Site ID: ${site.id}', style: textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Reporting modules', style: textTheme.headlineSmall),
            const SizedBox(height: 12),
            const _ReportingModuleCard(
              icon: Icons.groups_outlined,
              title: 'Attendance',
              description: 'Record and review aggregate workforce counts.',
            ),
            const SizedBox(height: 12),
            const _ReportingModuleCard(
              icon: Icons.inventory_2_outlined,
              title: 'Material usage',
              description: 'Record material quantities consumed at this site.',
            ),
            const SizedBox(height: 12),
            const _ReportingModuleCard(
              icon: Icons.health_and_safety_outlined,
              title: 'Safety reports',
              description: 'Record incidents or unsafe site conditions.',
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportingModuleCard extends StatelessWidget {
  const _ReportingModuleCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return BrixelSectionCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
