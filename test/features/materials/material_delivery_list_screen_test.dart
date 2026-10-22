import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/materials/models/material_delivery.dart';
import 'package:brixel/features/materials/screens/material_delivery_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const testSiteId = 'site-metro-line1';
  const testSiteName = 'Metro Line 1 - Station Pier 4';

  Widget createTestWidget({List<MaterialDelivery>? deliveries}) {
    return MaterialApp(
      theme: buildBrixelTheme(),
      home: MaterialDeliveryListScreen(
        initialDeliveries: deliveries,
        siteId: testSiteId,
        siteName: testSiteName,
      ),
    );
  }

  group('MaterialDeliveryListScreen - Displaying Dynamic Lists Tests', () {
    testWidgets('Task 1: Displays dynamic list using ListView.builder driven by Dart list',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verify ListView exists and is driven by builder
      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);

      // Verify header summary displays initial 25 deliveries
      expect(find.text('25'), findsOneWidget); // Total metric
      expect(find.text('Dynamic Builder Feed (25 items)'), findsOneWidget);
    });

    testWidgets('Task 2: Generates each row item dynamically from model object fields',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final customDeliveries = [
        MaterialDelivery(
          id: 'DEL-CUSTOM-01',
          siteId: testSiteId,
          materialName: 'High-Tensile Steel Cables',
          quantity: 45.5,
          unit: 'coils',
          supplier: 'Precision Wire Works',
          status: 'In Transit',
          deliveryDate: DateTime(2026, 10, 22),
        ),
        MaterialDelivery(
          id: 'DEL-CUSTOM-02',
          siteId: testSiteId,
          materialName: 'Rapid-Hardening Portland Cement',
          quantity: 120,
          unit: 'bags',
          supplier: 'Shree Cement Corp',
          status: 'Delivered',
          deliveryDate: DateTime(2026, 10, 22),
        ),
      ];

      await tester.pumpWidget(createTestWidget(deliveries: customDeliveries));
      await tester.pumpAndSettle();

      // Verify row 1 fields generated from custom model
      expect(find.text('High-Tensile Steel Cables'), findsOneWidget);
      expect(find.text('DEL-CUSTOM-01'), findsOneWidget);
      expect(find.text('Precision Wire Works'), findsOneWidget);
      expect(find.text('45.5 coils'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('deliveryCard_DEL-CUSTOM-01')),
          matching: find.text('In Transit'),
        ),
        findsOneWidget,
      );

      // Verify row 2 fields generated from custom model
      expect(find.text('Rapid-Hardening Portland Cement'), findsOneWidget);
      expect(find.text('DEL-CUSTOM-02'), findsOneWidget);
      expect(find.text('Shree Cement Corp'), findsOneWidget);
      expect(find.text('120.0 bags'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const Key('deliveryCard_DEL-CUSTOM-02')),
          matching: find.text('Delivered'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Task 3: Confirms smooth scrolling across large collection of items',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 800); // Shorter viewport to force scrolling
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initially top item DEL-1001 is on-screen
      expect(find.text('DEL-1001'), findsOneWidget);
      // Bottom item DEL-1025 is off-screen
      expect(find.text('DEL-1025'), findsNothing);

      // Scroll until the last item DEL-1025 comes into view smoothly
      await tester.scrollUntilVisible(
        find.text('DEL-1025'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Confirm scrolled position renders previously off-screen items smoothly
      expect(find.text('DEL-1025'), findsOneWidget);
      expect(find.text('Tile Adhesive & Epoxy Grout'), findsOneWidget);
    });

    testWidgets('Task 4: Adding an item inside setState() immediately updates the list on screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Initial count: 25
      expect(find.text('Dynamic Builder Feed (25 items)'), findsOneWidget);
      expect(find.text('DEL-2001'), findsNothing);

      // Tap Add Delivery button in AppBar
      await tester.tap(find.byKey(const Key('addDeliveryButton')));
      await tester.pumpAndSettle();

      // Verify new item was inserted at the top and rendered
      expect(find.text('DEL-2001'), findsOneWidget);
      expect(find.text('Structural Steel Rebars 20mm'), findsOneWidget);

      // Verify counter incremented to 26
      expect(find.text('Dynamic Builder Feed (26 items)'), findsOneWidget);
    });

    testWidgets('Task 4: Removing an item inside setState() immediately removes row from screen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final sampleDeliveries = [
        MaterialDelivery(
          id: 'DEL-DELETE-ME',
          siteId: testSiteId,
          materialName: 'Temporary Wooden Battens',
          quantity: 20,
          unit: 'bundles',
          supplier: 'Local Timber Depot',
          status: 'Pending',
          deliveryDate: DateTime(2026, 10, 22),
        ),
        MaterialDelivery(
          id: 'DEL-KEEP-ME',
          siteId: testSiteId,
          materialName: 'Permanent Structural Beams',
          quantity: 5,
          unit: 'metric_tons',
          supplier: 'Apex Steel',
          status: 'Delivered',
          deliveryDate: DateTime(2026, 10, 22),
        ),
      ];

      await tester.pumpWidget(createTestWidget(deliveries: sampleDeliveries));
      await tester.pumpAndSettle();

      expect(find.text('Temporary Wooden Battens'), findsOneWidget);
      expect(find.text('Permanent Structural Beams'), findsOneWidget);
      expect(find.text('Dynamic Builder Feed (2 items)'), findsOneWidget);

      // Tap delete on DEL-DELETE-ME
      await tester.tap(find.byKey(const Key('deleteDelivery_DEL-DELETE-ME')));
      await tester.pumpAndSettle();

      // Confirm removed item is gone from the screen and count is 1
      expect(find.text('Temporary Wooden Battens'), findsNothing);
      expect(find.text('Permanent Structural Beams'), findsOneWidget);
      expect(find.text('Dynamic Builder Feed (1 items)'), findsOneWidget);
    });

    testWidgets('Renders empty state when delivery list has zero items',
        (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget(deliveries: []));
      await tester.pumpAndSettle();

      expect(find.text('No deliveries recorded yet'), findsOneWidget);
      expect(
        find.text('Tap the + button to add a material delivery.'),
        findsOneWidget,
      );
    });
  });
}
