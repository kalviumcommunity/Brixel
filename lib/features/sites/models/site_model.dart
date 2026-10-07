import 'package:cloud_firestore/cloud_firestore.dart';

class SiteModel {
  final String id;
  final String name;
  final String location;
  final String status; // 'active' | 'on_hold' | 'completed'
  final int expectedHeadcount;
  final List<String> assignedSupervisorIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  SiteModel({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
    required this.expectedHeadcount,
    this.assignedSupervisorIds = const [],
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'location': location,
      'status': status,
      'expectedHeadcount': expectedHeadcount,
      'assignedSupervisorIds': assignedSupervisorIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory SiteModel.fromMap(Map<String, dynamic> map, String id) {
    return SiteModel(
      id: id,
      name: map['name'] as String? ?? '',
      location: map['location'] as String? ?? '',
      status: map['status'] as String? ?? 'active',
      expectedHeadcount: (map['expectedHeadcount'] as num?)?.toInt() ?? 0,
      assignedSupervisorIds: List<String>.from(map['assignedSupervisorIds'] ?? []),
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory SiteModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return SiteModel.fromMap(data, doc.id);
  }

  SiteModel copyWith({
    String? id,
    String? name,
    String? location,
    String? status,
    int? expectedHeadcount,
    List<String>? assignedSupervisorIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SiteModel(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      status: status ?? this.status,
      expectedHeadcount: expectedHeadcount ?? this.expectedHeadcount,
      assignedSupervisorIds: assignedSupervisorIds ?? this.assignedSupervisorIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
