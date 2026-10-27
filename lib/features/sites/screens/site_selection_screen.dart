import 'package:brixel/features/auth/services/user_authentication.dart';
import 'package:brixel/features/navigation/screens/app_navigation_shell.dart';
import 'package:brixel/features/sites/models/site.dart';
import 'package:brixel/features/sites/models/site_model.dart';
import 'package:brixel/features/sites/repositories/firestore_site_repository.dart';
import 'package:brixel/features/sites/repositories/site_repository.dart';
import 'package:brixel/shared/widgets/brixel_primary_button.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:flutter/material.dart';

class SiteSelectionScreen extends StatelessWidget {
  const SiteSelectionScreen({
    super.key,
    this.authService,
    this.userRole,
    this.assignedSiteIds = const [],
    this.siteRepository,
  });

  final UserAuthentication? authService;
  final String? userRole;
  final List<String> assignedSiteIds;
  final SiteRepository? siteRepository;

  Stream<List<SiteModel>> _watchSites() {
    if (userRole == 'manager') {
      return (siteRepository ?? FirestoreSiteRepository()).watchAllSites();
    }

    if (assignedSiteIds.isEmpty) {
      return Stream.value(const <SiteModel>[]);
    }

    final repository = siteRepository ?? FirestoreSiteRepository();
    return repository.watchAssignedSites(assignedSiteIds);
  }

  void _openSite(BuildContext context, Site site) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return AppNavigationShell(site: site, authService: authService);
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
        child: StreamBuilder<List<SiteModel>>(
          stream: _watchSites(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Could not load your assigned sites. Please try again.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final sites = snapshot.data ?? const <SiteModel>[];
            if (sites.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'No sites are currently assigned to your account.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sites.length + 1,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
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

                final siteModel = sites[index - 1];
                final site = Site(
                  id: siteModel.id,
                  name: siteModel.name,
                  location: siteModel.location,
                );

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
                        onPressed: () => _openSite(context, site),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
