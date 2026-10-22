import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/materials/models/material_delivery.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:flutter/material.dart';

/// Screen displaying dynamic construction material deliveries using ListView.builder.
class MaterialDeliveryListScreen extends StatefulWidget {
  const MaterialDeliveryListScreen({
    super.key,
    this.initialDeliveries,
    this.siteId = 'site-metro-line1',
    this.siteName = 'Metro Line 1 - Station Pier 4',
  });

  final List<MaterialDelivery>? initialDeliveries;
  final String siteId;
  final String siteName;

  /// Default dataset containing 25 realistic delivery records for smooth scrolling.
  static List<MaterialDelivery> defaultDeliveries(String siteId) {
    return [
      MaterialDelivery(
        id: 'DEL-1001',
        siteId: siteId,
        materialName: 'OPC 53 Grade Cement',
        quantity: 350,
        unit: 'bags',
        supplier: 'UltraTech Cement Ltd.',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 22, 8, 30),
      ),
      MaterialDelivery(
        id: 'DEL-1002',
        siteId: siteId,
        materialName: '16mm TMT Reinforcement Steel',
        quantity: 18.5,
        unit: 'metric_tons',
        supplier: 'Tata Tiscon Steel',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 22, 9, 15),
      ),
      MaterialDelivery(
        id: 'DEL-1003',
        siteId: siteId,
        materialName: 'M30 Ready-Mix Concrete',
        quantity: 45,
        unit: 'cubic_meters',
        supplier: 'ACC Concrete Batching',
        status: 'In Transit',
        deliveryDate: DateTime(2026, 10, 22, 10, 0),
      ),
      MaterialDelivery(
        id: 'DEL-1004',
        siteId: siteId,
        materialName: 'Coarse River Sand',
        quantity: 28,
        unit: 'metric_tons',
        supplier: 'Godavari Aggregate Supplies',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 21, 14, 0),
      ),
      MaterialDelivery(
        id: 'DEL-1005',
        siteId: siteId,
        materialName: '20mm Crushed Blue Metal Aggregate',
        quantity: 40,
        unit: 'metric_tons',
        supplier: 'Deccan Quarry Works',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 21, 16, 30),
      ),
      MaterialDelivery(
        id: 'DEL-1006',
        siteId: siteId,
        materialName: 'Fly Ash Red Bricks',
        quantity: 12000,
        unit: 'pieces',
        supplier: 'Pragati Brick Industries',
        status: 'Pending',
        deliveryDate: DateTime(2026, 10, 22, 11, 30),
      ),
      MaterialDelivery(
        id: 'DEL-1007',
        siteId: siteId,
        materialName: '12mm TMT Steel Rebars',
        quantity: 14.0,
        unit: 'metric_tons',
        supplier: 'JSW Steel Infra',
        status: 'In Transit',
        deliveryDate: DateTime(2026, 10, 22, 12, 0),
      ),
      MaterialDelivery(
        id: 'DEL-1008',
        siteId: siteId,
        materialName: 'PPC Blended Cement',
        quantity: 200,
        unit: 'bags',
        supplier: 'Ambuja Cements',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 20, 11, 0),
      ),
      MaterialDelivery(
        id: 'DEL-1009',
        siteId: siteId,
        materialName: 'Waterproofing Chemical Compound',
        quantity: 50,
        unit: 'cans (20L)',
        supplier: 'Dr. Fixit Commercial',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 20, 15, 45),
      ),
      MaterialDelivery(
        id: 'DEL-1010',
        siteId: siteId,
        materialName: '110mm Heavy Duty PVC Drainage Pipes',
        quantity: 150,
        unit: 'lengths (6m)',
        supplier: 'Supreme Piping Systems',
        status: 'Pending',
        deliveryDate: DateTime(2026, 10, 22, 14, 15),
      ),
      MaterialDelivery(
        id: 'DEL-1011',
        siteId: siteId,
        materialName: 'Scaffolding Steel Clamps & Couplers',
        quantity: 600,
        unit: 'pieces',
        supplier: 'Kalyani Formwork Tech',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 19, 10, 30),
      ),
      MaterialDelivery(
        id: 'DEL-1012',
        siteId: siteId,
        materialName: '10mm Shuttering Plywood Sheets',
        quantity: 85,
        unit: 'sheets',
        supplier: 'Century Infra Ply',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 19, 13, 0),
      ),
      MaterialDelivery(
        id: 'DEL-1013',
        siteId: siteId,
        materialName: 'M25 Ready-Mix Concrete',
        quantity: 36,
        unit: 'cubic_meters',
        supplier: 'ACC Concrete Batching',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 18, 9, 0),
      ),
      MaterialDelivery(
        id: 'DEL-1014',
        siteId: siteId,
        materialName: '8mm Structural Stirrup Steel',
        quantity: 8.5,
        unit: 'metric_tons',
        supplier: 'Tata Tiscon Steel',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 18, 14, 20),
      ),
      MaterialDelivery(
        id: 'DEL-1015',
        siteId: siteId,
        materialName: 'Reinforced Geotextile Membrane',
        quantity: 12,
        unit: 'rolls',
        supplier: 'Garware Technical Fibres',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 17, 16, 0),
      ),
      MaterialDelivery(
        id: 'DEL-1016',
        siteId: siteId,
        materialName: 'Hydraulic Oil (Grade 68)',
        quantity: 4,
        unit: 'drums (200L)',
        supplier: 'Indian Oil Industrial',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 17, 11, 30),
      ),
      MaterialDelivery(
        id: 'DEL-1017',
        siteId: siteId,
        materialName: 'Safety Cones & Hazard Tape',
        quantity: 120,
        unit: 'sets',
        supplier: 'SafeTech Industrial Equip',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 16, 10, 0),
      ),
      MaterialDelivery(
        id: 'DEL-1018',
        siteId: siteId,
        materialName: '25mm Electrical Conduit PVC Pipes',
        quantity: 300,
        unit: 'lengths (3m)',
        supplier: 'Finolex Cables Ltd.',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 16, 15, 10),
      ),
      MaterialDelivery(
        id: 'DEL-1019',
        siteId: siteId,
        materialName: 'Expansion Joint Filler Boards',
        quantity: 40,
        unit: 'sheets',
        supplier: 'Pidilite Construction Chem',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 15, 11, 40),
      ),
      MaterialDelivery(
        id: 'DEL-1020',
        siteId: siteId,
        materialName: 'Granular Sub-Base Gravel (GSB)',
        quantity: 65,
        unit: 'metric_tons',
        supplier: 'Deccan Quarry Works',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 15, 14, 0),
      ),
      MaterialDelivery(
        id: 'DEL-1021',
        siteId: siteId,
        materialName: 'Anchor Bolts & Base Plates (Grade 8.8)',
        quantity: 450,
        unit: 'pieces',
        supplier: 'Unbrako Fasteners',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 14, 9, 30),
      ),
      MaterialDelivery(
        id: 'DEL-1022',
        siteId: siteId,
        materialName: 'Curing Compound Membrane',
        quantity: 15,
        unit: 'cans (25L)',
        supplier: 'Fosroc Construction Chemicals',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 14, 13, 15),
      ),
      MaterialDelivery(
        id: 'DEL-1023',
        siteId: siteId,
        materialName: 'Heavy Structural Steel Beams (ISMB 300)',
        quantity: 22.0,
        unit: 'metric_tons',
        supplier: 'SAIL Steel Authority',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 13, 10, 45),
      ),
      MaterialDelivery(
        id: 'DEL-1024',
        siteId: siteId,
        materialName: 'AAC Lightweight Autoclaved Blocks',
        quantity: 3500,
        unit: 'blocks',
        supplier: 'Magicrete Building Solutions',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 13, 15, 30),
      ),
      MaterialDelivery(
        id: 'DEL-1025',
        siteId: siteId,
        materialName: 'Tile Adhesive & Epoxy Grout',
        quantity: 80,
        unit: 'bags (20kg)',
        supplier: 'Roff Construction Chem',
        status: 'Delivered',
        deliveryDate: DateTime(2026, 10, 12, 11, 0),
      ),
    ];
  }

  @override
  State<MaterialDeliveryListScreen> createState() =>
      _MaterialDeliveryListScreenState();
}

class _MaterialDeliveryListScreenState
    extends State<MaterialDeliveryListScreen> {
  // Task 1: Dart list driving the dynamic ListView.builder
  late List<MaterialDelivery> _deliveries;
  int _counter = 2000;

  @override
  void initState() {
    super.initState();
    _deliveries = List<MaterialDelivery>.from(
      widget.initialDeliveries ??
          MaterialDeliveryListScreen.defaultDeliveries(widget.siteId),
    );
  }

  // Summary counts computed from list data
  int get _deliveredCount =>
      _deliveries.where((d) => d.status.toLowerCase() == 'delivered').length;
  int get _inTransitCount =>
      _deliveries.where((d) => d.status.toLowerCase() == 'in transit').length;
  int get _pendingCount =>
      _deliveries.where((d) => d.status.toLowerCase() == 'pending').length;

  // Task 4: Add an item inside setState() and update screen
  void _addSampleDelivery() {
    setState(() {
      _counter++;
      final newDelivery = MaterialDelivery(
        id: 'DEL-$_counter',
        siteId: widget.siteId,
        materialName: 'Structural Steel Rebars 20mm',
        quantity: 15.0,
        unit: 'metric_tons',
        supplier: 'JSW Steel Infra',
        status: 'In Transit',
        deliveryDate: DateTime.now(),
      );
      _deliveries.insert(0, newDelivery);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added new delivery DEL-$_counter to feed'),
        backgroundColor: BrixelColors.success,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Task 4: Remove an item inside setState() and update screen
  void _removeDelivery(String id) {
    setState(() {
      _deliveries.removeWhere((d) => d.id == id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Delivery $id removed'),
        backgroundColor: BrixelColors.secondaryText,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return BrixelColors.success;
      case 'in transit':
        return BrixelColors.primary;
      case 'pending':
      default:
        return BrixelColors.secondaryText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: BrixelColors.background,
      appBar: AppBar(
        title: Text('${widget.siteName} Deliveries'),
        actions: [
          IconButton(
            key: const Key('addDeliveryButton'),
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Delivery Batch',
            onPressed: _addSampleDelivery,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addDeliveryFab'),
        onPressed: _addSampleDelivery,
        backgroundColor: BrixelColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Delivery'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // KPI Summary Header Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: BrixelColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BrixelColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricCol('Total', '${_deliveries.length}', BrixelColors.primaryText),
                    Container(height: 28, width: 1, color: BrixelColors.border),
                    _buildMetricCol('Delivered', '$_deliveredCount', BrixelColors.success),
                    Container(height: 28, width: 1, color: BrixelColors.border),
                    _buildMetricCol('In Transit', '$_inTransitCount', BrixelColors.primary),
                    Container(height: 28, width: 1, color: BrixelColors.border),
                    _buildMetricCol('Pending', '$_pendingCount', BrixelColors.secondaryText),
                  ],
                ),
              ),
            ),

            // Feed Info Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.swap_vert, size: 18, color: BrixelColors.secondaryText),
                  const SizedBox(width: 4),
                  Text(
                    'Dynamic Builder Feed (${_deliveries.length} items)',
                    key: const Key('deliveriesCountText'),
                    style: textTheme.bodySmall?.copyWith(
                      color: BrixelColors.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Task 1, 2 & 3: Dynamic ListView.builder generating rows on demand
            Expanded(
              child: _deliveries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 48,
                            color: BrixelColors.secondaryText.withValues(alpha: 0.5),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No deliveries recorded yet',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Tap the + button to add a material delivery.',
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      key: const Key('materialDeliveryListView'),
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _deliveries.length,
                      itemBuilder: (context, index) {
                        // Task 2: Generate item widget directly from model object
                        final delivery = _deliveries[index];
                        final statusColor = _getStatusColor(delivery.status);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: BrixelSectionCard(
                            key: Key('deliveryCard_${delivery.id}'),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Top row: Material name & Status badge
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            delivery.materialName,
                                            style: textTheme.titleMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: BrixelColors.background,
                                                  borderRadius: BorderRadius.circular(4),
                                                  border: Border.all(color: BrixelColors.border),
                                                ),
                                                child: Text(
                                                  delivery.id,
                                                  style: const TextStyle(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600,
                                                    color: BrixelColors.secondaryText,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  delivery.supplier,
                                                  style: textTheme.bodySmall?.copyWith(
                                                    color: BrixelColors.secondaryText,
                                                  ),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: statusColor.withValues(alpha: 0.4),
                                        ),
                                      ),
                                      child: Text(
                                        delivery.status,
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Divider(height: 1, color: BrixelColors.border),
                                const SizedBox(height: 8),

                                // Bottom row: Quantity badge, Date, and Delete action button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.local_shipping_outlined,
                                          size: 16,
                                          color: BrixelColors.secondaryText,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${delivery.quantity} ${delivery.unit}',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: BrixelColors.primaryText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${delivery.deliveryDate.day}/${delivery.deliveryDate.month}/${delivery.deliveryDate.year}',
                                          style: textTheme.bodySmall?.copyWith(
                                            color: BrixelColors.secondaryText,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          key: Key('deleteDelivery_${delivery.id}'),
                                          icon: const Icon(
                                            Icons.delete_outline,
                                            size: 18,
                                            color: BrixelColors.secondaryText,
                                          ),
                                          tooltip: 'Remove delivery',
                                          onPressed: () => _removeDelivery(delivery.id),
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: BrixelColors.secondaryText,
          ),
        ),
      ],
    );
  }
}
