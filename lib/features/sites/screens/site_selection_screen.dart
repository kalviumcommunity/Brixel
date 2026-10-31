import 'package:brixel/features/auth/models/user_model.dart';
import 'package:brixel/features/sites/models/site_model.dart';
import 'package:brixel/features/sites/repositories/site_repository.dart';
import 'package:brixel/features/sites/repositories/firestore_site_repository.dart';
import 'package:brixel/features/auth/services/user_authentication.dart';
import 'package:brixel/features/auth/widgets/logout_button.dart';
import 'package:brixel/features/navigation/screens/app_navigation_shell.dart';
import 'package:brixel/features/sites/models/site.dart';
import 'package:brixel/shared/widgets/brixel_primary_button.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:flutter/material.dart';

class SiteSelectionScreen extends StatefulWidget {
  const SiteSelectionScreen({
    super.key,
    this.authService,
    this.profile,
    this.repository,
    this.sites,
  });

  final UserAuthentication? authService;
  final UserModel? profile;
  final SiteRepository? repository;
  final Stream<List<SiteModel>>? sites;

  @override
  State<SiteSelectionScreen> createState() => _SiteSelectionScreenState();
}

class _SiteSelectionScreenState extends State<SiteSelectionScreen> {
  late Stream<List<SiteModel>> _sites;
  @override
  void initState() {
    super.initState();
    _connect();
  }

  void _connect() {
    if (widget.sites == null && widget.profile?.role == 'manager') {
      _sites = (widget.repository ?? FirestoreSiteRepository()).watchAllSites();
      return;
    }
    _sites =
        widget.sites ??
        (widget.profile == null || widget.profile!.assignedSiteIds.isEmpty
            ? Stream.value(<SiteModel>[])
            : (widget.repository ?? FirestoreSiteRepository())
                  .watchAssignedSites(widget.profile!.assignedSiteIds));
  }

  void _openSite(BuildContext context, Site site) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          return AppNavigationShell(
            site: site,
            authService: widget.authService,
            profile: widget.profile,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brixel'),
        actions: [
          if (widget.profile != null)
            LogoutButton(authService: widget.authService),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<List<SiteModel>>(
          stream: _sites,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Could not load your sites.'),
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
            final availableSites = snapshot.data!;
            if (availableSites.isEmpty) {
              return const Center(
                child: Text('No sites assigned. Contact your manager.'),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: availableSites.length + 1,
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

                final model = availableSites[index - 1];
                final site = Site(
                  id: model.id,
                  name: model.name,
                  location: model.location,
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
                        onPressed: () {
                          _openSite(context, site);
                        },
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
