import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/attendance/screens/attendance_form_screen.dart';
import 'package:brixel/features/materials/screens/material_form_screen.dart';
import 'package:brixel/features/navigation/screens/app_navigation_shell.dart';
import 'package:brixel/features/safety/screens/safety_incident_form_screen.dart';
import 'package:brixel/features/sites/models/site.dart';
import 'package:brixel/features/sites/screens/site_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testSite = Site(
    id: 'site-metro-line1',
    name: 'Metro Line 1 - Station Pier 4',
    location: 'Madhapur, Hyderabad',
  );

  Widget createTestWidget({int initialIndex = 0}) {
    return MaterialApp(
      theme: buildBrixelTheme(),
      home: AppNavigationShell(
        site: testSite,
        initialIndex: initialIndex,
      ),
    );
  }

  Finder findNavTab(String label) {
    return find.descendant(
      of: find.byType(BottomNavigationBar),
      matching: find.text(label),
    );
  }

  group('Bottom Navigation Shell - Tasks 1, 2, 3 & 4 Verification', () {
    testWidgets('Task 1: Implements a BottomNavigationBar with primary screen items',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify BottomNavigationBar exists
      final navBarFinder = find.byType(BottomNavigationBar);
      expect(navBarFinder, findsOneWidget);

      final BottomNavigationBar navBar =
          tester.widget<BottomNavigationBar>(navBarFinder);

      // Verify fixed type for multi-tab display
      expect(navBar.type, equals(BottomNavigationBarType.fixed));

      // Verify 5 primary destinations are present
      expect(navBar.items.length, equals(5));
      expect(navBar.items[0].label, equals('Home'));
      expect(navBar.items[1].label, equals('Attendance'));
      expect(navBar.items[2].label, equals('Materials'));
      expect(navBar.items[3].label, equals('Safety'));
      expect(navBar.items[4].label, equals('More'));
    });

    testWidgets('Task 2 & 3: Switches between screens and tracks selected tab index',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initial state: Home dashboard (index 0)
      BottomNavigationBar navBar =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(navBar.currentIndex, equals(0));
      expect(find.byType(SiteDashboardScreen), findsOneWidget);

      // Switch to Attendance tab (index 1)
      await tester.tap(findNavTab('Attendance'));
      await tester.pumpAndSettle();

      navBar =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(navBar.currentIndex, equals(1));
      expect(find.byType(AttendanceFormScreen), findsOneWidget);

      // Switch to Materials tab (index 2)
      await tester.tap(findNavTab('Materials'));
      await tester.pumpAndSettle();

      navBar =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(navBar.currentIndex, equals(2));
      expect(find.byType(MaterialFormScreen), findsOneWidget);

      // Switch to Safety tab (index 3)
      await tester.tap(findNavTab('Safety'));
      await tester.pumpAndSettle();

      navBar =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(navBar.currentIndex, equals(3));
      expect(find.byType(SafetyIncidentFormScreen), findsOneWidget);

      // Switch to More tab (index 4)
      await tester.tap(findNavTab('More'));
      await tester.pumpAndSettle();

      navBar =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(navBar.currentIndex, equals(4));
      expect(find.text('Log out'), findsOneWidget);

      // Switch back to Home (index 0)
      await tester.tap(findNavTab('Home'));
      await tester.pumpAndSettle();

      navBar =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(navBar.currentIndex, equals(0));
      expect(find.byType(SiteDashboardScreen), findsOneWidget);
    });

    testWidgets('Task 4: Uses IndexedStack to preserve form input and state while switching tabs',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify IndexedStack exists as the root body
      final indexedStackFinder = find.byType(IndexedStack);
      expect(indexedStackFinder, findsOneWidget);

      final IndexedStack stack =
          tester.widget<IndexedStack>(indexedStackFinder);
      expect(stack.children.length, equals(5));

      // 1. Navigate to Attendance tab
      await tester.tap(findNavTab('Attendance'));
      await tester.pumpAndSettle();

      // Find the worker name text field and enter text
      final workerNameField = find.byType(TextFormField).first;
      await tester.enterText(workerNameField, 'Vikram Singh (Welder Crew)');
      await tester.pumpAndSettle();

      expect(find.text('Vikram Singh (Welder Crew)'), findsOneWidget);

      // 2. Switch away to Safety tab
      await tester.tap(findNavTab('Safety'));
      await tester.pumpAndSettle();

      // Verify Safety screen is displayed
      expect(find.byType(SafetyIncidentFormScreen), findsOneWidget);

      // 3. Switch back to Attendance tab
      await tester.tap(findNavTab('Attendance'));
      await tester.pumpAndSettle();

      // 4. Confirm the entered text was preserved by IndexedStack and did NOT reset
      expect(find.text('Vikram Singh (Welder Crew)'), findsOneWidget);
    });

    testWidgets('Supports custom initialIndex configuration',
        (WidgetTester tester) async {
      // Launch shell with initialIndex = 2 (Materials)
      await tester.pumpWidget(createTestWidget(initialIndex: 2));
      await tester.pumpAndSettle();

      final BottomNavigationBar navBar =
          tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(navBar.currentIndex, equals(2));
      expect(find.byType(MaterialFormScreen), findsOneWidget);
    });
  });
}
