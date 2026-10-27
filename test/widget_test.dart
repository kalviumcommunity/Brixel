import 'package:brixel/features/sites/screens/site_selection_screen.dart';
import 'package:brixel/features/sites/models/site_model.dart';
import 'package:brixel/features/sites/repositories/site_repository.dart';
import 'package:brixel/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSiteRepository implements SiteRepository {
  @override
  Stream<List<SiteModel>> watchAssignedSites(List<String> siteIds) {
    return watchAllSites();
  }

  @override
  Stream<List<SiteModel>> watchAllSites() {
    return watchSitesForSupervisor('');
  }

  @override
  Stream<List<SiteModel>> watchSitesForSupervisor(String supervisorId) {
    return Stream.value([
      SiteModel(
        id: 'site-jaipur-01',
        name: 'Jaipur Residential Project',
        location: 'Jaipur, Rajasthan',
        status: 'active',
        expectedHeadcount: 20,
        createdAt: DateTime(2026, 10, 16),
      ),
      SiteModel(
        id: 'site-ajmer-01',
        name: 'Ajmer Commercial Project',
        location: 'Ajmer, Rajasthan',
        status: 'active',
        expectedHeadcount: 15,
        createdAt: DateTime(2026, 10, 16),
      ),
    ]);
  }
}

void main() {
  testWidgets('selected site is preserved across bottom navigation', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MyApp(
        home: SiteSelectionScreen(
          userRole: 'manager',
          siteRepository: FakeSiteRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Select a site'), findsOneWidget);
    expect(find.text('Jaipur Residential Project'), findsOneWidget);
    expect(find.text('Ajmer Commercial Project'), findsOneWidget);

    // Open the first site.
    await tester.tap(find.text('Open site').first);
    await tester.pumpAndSettle();

    expect(find.text('Site overview'), findsOneWidget);
    expect(find.text('Jaipur Residential Project'), findsWidgets);

    // Open Attendance from the bottom navigation bar.
    final attendanceTab = find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text('Attendance'),
    );

    expect(attendanceTab, findsOneWidget);

    await tester.tap(attendanceTab);
    await tester.pumpAndSettle();

    expect(find.text('Jaipur Residential Project'), findsOneWidget);
    expect(
      find.textContaining(
        'Attendance reporting for Jaipur Residential Project',
      ),
      findsOneWidget,
    );

    // Return to site selection.
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Select a site'), findsOneWidget);

    // Open the second site.
    await tester.tap(find.text('Open site').last);
    await tester.pumpAndSettle();

    final safetyTab = find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text('Safety'),
    );

    expect(safetyTab, findsOneWidget);

    await tester.tap(safetyTab);
    await tester.pumpAndSettle();

    expect(find.text('Safety Reports'), findsOneWidget);
    expect(find.text('Ajmer Commercial Project'), findsOneWidget);

    final moreTab = find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text('More'),
    );
    await tester.tap(moreTab);
    await tester.pumpAndSettle();

    expect(find.text('Log out'), findsOneWidget);
    expect(find.textContaining('will appear here later'), findsNothing);
  });
}
