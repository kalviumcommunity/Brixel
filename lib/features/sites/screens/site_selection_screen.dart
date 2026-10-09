import 'package:brixel/features/sites/models/site.dart';
import 'package:brixel/features/navigation/screens/app_navigation_shell.dart';
import 'package:brixel/shared/widgets/brixel_primary_button.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:flutter/material.dart';

class SiteSelectionScreen extends StatelessWidget {
  const SiteSelectionScreen({super.key});

  // Temporary local data used only to verify LU 3.14 navigation.
  // A later integration task should replace this with approved assigned-site
  // data from the shared application data source.
  static const List<Site> _demoSites = [
    Site(
      id: 'site-jaipur-01',
      name: 'Jaipur Residential Project',
      location: 'Jaipur, Rajasthan',
    ),
    Site(
      id: 'site-ajmer-01',
      name: 'Ajmer Commercial Project',
      location: 'Ajmer, Rajasthan',
    ),
  ];

  void _openSite(BuildContext context, Site site) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return AppNavigationShell(site: site);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Brixel')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _demoSites.length + 1,
          separatorBuilder: (context, index) {
            return const SizedBox(height: 12);
          },
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select a site', style: textTheme.headlineSmall),
                    const SizedBox(height: 6),
                    const Text(
                      'Choose the construction site you want to report for.',
                    ),
                  ],
                ),
              );
            }

            final site = _demoSites[index - 1];

            return BrixelSectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    site.name,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 20),
                      const SizedBox(width: 6),
                      Expanded(child: Text(site.location)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  BrixelPrimaryButton(
                    label: 'Open site',
                    icon: Icons.arrow_forward,
                    onPressed: () {
                      _openSite(context, site);
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
