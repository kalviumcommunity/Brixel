/// Represents a construction material delivery record.
class MaterialDelivery {
  final String id;
  final String siteId;
  final String materialName;
  final double quantity;
  final String unit;
  final String supplier;
  final String status; // 'Delivered', 'In Transit', 'Pending'
  final DateTime deliveryDate;

  const MaterialDelivery({
    required this.id,
    required this.siteId,
    required this.materialName,
    required this.quantity,
    required this.unit,
    required this.supplier,
    required this.status,
    required this.deliveryDate,
  });

  MaterialDelivery copyWith({
    String? id,
    String? siteId,
    String? materialName,
    double? quantity,
    String? unit,
    String? supplier,
    String? status,
    DateTime? deliveryDate,
  }) {
    return MaterialDelivery(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      materialName: materialName ?? this.materialName,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      supplier: supplier ?? this.supplier,
      status: status ?? this.status,
      deliveryDate: deliveryDate ?? this.deliveryDate,
    );
  }
}
