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
        initialDeliveries:
            deliveries ??
            MaterialDeliveryListScreen.sampleDeliveriesForPreview(testSiteId),
        siteId: testSiteId,
        siteName: testSiteName,
      ),
    );
  }

  group('MaterialDeliveryListScreen - Displaying Dynamic Lists Tests', () {
    testWidgets(
      'Task 1: Displays dynamic list using ListView.builder driven by Dart list',
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
      },
    );

    testWidgets(
      'Task 2: Generates each row item dynamically from model object fields',
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
      },
    );

    testWidgets(
      'Task 3: Confirms smooth scrolling across large collection of items',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(
          800,
          800,
        ); // Shorter viewport to force scrolling
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
      },
    );

    testWidgets(
      'does not expose non-persistent local delivery creation controls',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(800, 1400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        expect(find.text('Dynamic Builder Feed (25 items)'), findsOneWidget);
        expect(find.byKey(const Key('addDeliveryButton')), findsNothing);
        expect(find.byKey(const Key('addDeliveryFab')), findsNothing);
      },
    );

    testWidgets(
      'does not expose non-persistent local delivery deletion controls',
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

        expect(
          find.byKey(const Key('deleteDelivery_DEL-DELETE-ME')),
          findsNothing,
        );
        expect(find.text('Temporary Wooden Battens'), findsOneWidget);
        expect(find.text('Permanent Structural Beams'), findsOneWidget);
        expect(find.text('Dynamic Builder Feed (2 items)'), findsOneWidget);
      },
    );

    testWidgets(
      'production default does not show fabricated delivery records',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: buildBrixelTheme(),
            home: const MaterialDeliveryListScreen(
              siteId: testSiteId,
              siteName: testSiteName,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Dynamic Builder Feed (0 items)'), findsOneWidget);
        expect(find.text('No deliveries recorded yet'), findsOneWidget);
        expect(
          find.text('Delivery records are not available for this site yet.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('Renders empty state when delivery list has zero items', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(deliveries: []));
      await tester.pumpAndSettle();

      expect(find.text('No deliveries recorded yet'), findsOneWidget);
      expect(
        find.text('Delivery records are not available for this site yet.'),
        findsOneWidget,
      );
    });
  });
}
