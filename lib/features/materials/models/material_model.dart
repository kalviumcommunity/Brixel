import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialItemModel {
  final String id;
  final String siteId;
  final String materialName;
  final String unit; // e.g., 'bags', 'metric_tons', 'cubic_meters', 'pieces'
  final double currentStock;
  final double reorderThreshold;
  final DateTime updatedAt;

  MaterialItemModel({
    required this.id,
    required this.siteId,
    required this.materialName,
    required this.unit,
    required this.currentStock,
    required this.reorderThreshold,
    required this.updatedAt,
  });

  bool get isLowStock => currentStock <= reorderThreshold;

  Map<String, dynamic> toMap() {
    return {
      'siteId': siteId,
      'materialName': materialName,
      'unit': unit,
      'currentStock': currentStock,
      'reorderThreshold': reorderThreshold,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory MaterialItemModel.fromMap(Map<String, dynamic> map, String id) {
    return MaterialItemModel(
      id: id,
      siteId: map['siteId'] as String? ?? '',
      materialName: map['materialName'] as String? ?? '',
      unit: map['unit'] as String? ?? 'units',
      currentStock: (map['currentStock'] as num?)?.toDouble() ?? 0.0,
      reorderThreshold: (map['reorderThreshold'] as num?)?.toDouble() ?? 0.0,
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory MaterialItemModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MaterialItemModel.fromMap(data, doc.id);
  }

  MaterialItemModel copyWith({
    String? id,
    String? siteId,
    String? materialName,
    String? unit,
    double? currentStock,
    double? reorderThreshold,
    DateTime? updatedAt,
  }) {
    return MaterialItemModel(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      materialName: materialName ?? this.materialName,
      unit: unit ?? this.unit,
      currentStock: currentStock ?? this.currentStock,
      reorderThreshold: reorderThreshold ?? this.reorderThreshold,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class MaterialTransactionModel {
  final String id;
  final String materialId;
  final String siteId;
  final String type; // 'received' | 'used'
  final double quantity;
  final String? notes;
  final String recordedBy; // Supervisor user ID
  final DateTime timestamp;

  MaterialTransactionModel({
    required this.id,
    required this.materialId,
    required this.siteId,
    required this.type,
    required this.quantity,
    this.notes,
    required this.recordedBy,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'materialId': materialId,
      'siteId': siteId,
      'type': type,
      'quantity': quantity,
      'notes': notes,
      'recordedBy': recordedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory MaterialTransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return MaterialTransactionModel(
      id: id,
      materialId: map['materialId'] as String? ?? '',
      siteId: map['siteId'] as String? ?? '',
      type: map['type'] as String? ?? 'used',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0.0,
      notes: map['notes'] as String?,
      recordedBy: map['recordedBy'] as String? ?? '',
      timestamp: (map['timestamp'] is Timestamp)
          ? (map['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  factory MaterialTransactionModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return MaterialTransactionModel.fromMap(data, doc.id);
  }
}
