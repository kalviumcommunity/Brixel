import 'package:brixel/features/navigation/screens/app_navigation_shell.dart';
import 'package:brixel/features/sites/models/site_model.dart';
import 'package:brixel/features/sites/repositories/site_repository.dart';
import 'package:brixel/features/sites/screens/site_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSiteRepository implements SiteRepository {
  FakeSiteRepository(this.sites);

  final List<SiteModel> sites;
  List<String>? requestedSiteIds;
  String? requestedSupervisorId;
  bool allSitesRequested = false;

  @override
  Stream<List<SiteModel>> watchAllSites() {
    allSitesRequested = true;
    return Stream.value(sites);
  }

  @override
  Stream<List<SiteModel>> watchAssignedSites(List<String> siteIds) {
    requestedSiteIds = siteIds;
    return Stream.value(sites);
  }

  @override
  Stream<List<SiteModel>> watchSitesForSupervisor(String supervisorId) {
    requestedSupervisorId = supervisorId;
    return Stream.value(sites);
  }
}

void main() {
  testWidgets('loads assigned sites and opens the selected site context', (
    tester,
  ) async {
    final repository = FakeSiteRepository([
      SiteModel(
        id: 'site-assigned-42',
        name: 'Assigned Project',
        location: 'Jaipur, Rajasthan',
        status: 'active',
        expectedHeadcount: 20,
        createdAt: DateTime(2026, 10, 16),
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: SiteSelectionScreen(
          userRole: 'supervisor',
          assignedSiteIds: const ['site-assigned-42'],
          siteRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.requestedSiteIds, ['site-assigned-42']);
    expect(repository.allSitesRequested, isFalse);
    expect(find.text('Assigned Project'), findsOneWidget);
    expect(find.text('Jaipur, Rajasthan'), findsOneWidget);
    expect(find.text('site-jaipur-01'), findsNothing);

    await tester.tap(find.text('Open site'));
    await tester.pumpAndSettle();

    final shell = tester.widget<AppNavigationShell>(
      find.byType(AppNavigationShell),
    );
    expect(shell.site.id, 'site-assigned-42');
    expect(shell.site.name, 'Assigned Project');
  });

  testWidgets('managers load all sites even without site assignments', (
    tester,
  ) async {
    final repository = FakeSiteRepository([
      SiteModel(
        id: 'site-unassigned',
        name: 'Unassigned Project',
        location: 'Jaipur, Rajasthan',
        status: 'active',
        expectedHeadcount: 20,
        createdAt: DateTime(2026, 10, 16),
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: SiteSelectionScreen(
          userRole: 'manager',
          siteRepository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.allSitesRequested, isTrue);
    expect(find.text('Unassigned Project'), findsOneWidget);
  });

  testWidgets('does not fabricate sites when the account has no assignments', (
    tester,
  ) async {
    final repository = FakeSiteRepository([]);

    await tester.pumpWidget(
      MaterialApp(home: SiteSelectionScreen(siteRepository: repository)),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No sites are currently assigned to your account.'),
      findsOneWidget,
    );
    expect(repository.requestedSiteIds, isNull);
    expect(repository.requestedSupervisorId, isNull);
    expect(find.text('Jaipur Residential Project'), findsNothing);
  });
}
