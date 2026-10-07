import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentModel {
  final String id;
  final String siteId;
  final String incidentType; // 'injury' | 'near_miss' | 'equipment_failure' | 'hazard'
  final String severity; // 'low' | 'medium' | 'high' | 'critical'
  final String description;
  final String? photoUrl; // Firebase Storage URL
  final String status; // 'reported' | 'acknowledged' | 'resolved'
  final String reportedBy; // Supervisor user ID
  final String? resolvedBy; // Manager user ID
  final DateTime createdAt;
  final DateTime? resolvedAt;

  IncidentModel({
    required this.id,
    required this.siteId,
    required this.incidentType,
    required this.severity,
    required this.description,
    this.photoUrl,
    required this.status,
    required this.reportedBy,
    this.resolvedBy,
    required this.createdAt,
    this.resolvedAt,
  });

  bool get isCritical => severity == 'high' || severity == 'critical';

  Map<String, dynamic> toMap() {
    return {
      'siteId': siteId,
      'incidentType': incidentType,
      'severity': severity,
      'description': description,
      'photoUrl': photoUrl,
      'status': status,
      'reportedBy': reportedBy,
      'resolvedBy': resolvedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  factory IncidentModel.fromMap(Map<String, dynamic> map, String id) {
    return IncidentModel(
      id: id,
      siteId: map['siteId'] as String? ?? '',
      incidentType: map['incidentType'] as String? ?? 'hazard',
      severity: map['severity'] as String? ?? 'low',
      description: map['description'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      status: map['status'] as String? ?? 'reported',
      reportedBy: map['reportedBy'] as String? ?? '',
      resolvedBy: map['resolvedBy'] as String?,
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      resolvedAt: (map['resolvedAt'] is Timestamp)
          ? (map['resolvedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory IncidentModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return IncidentModel.fromMap(data, doc.id);
  }

  IncidentModel copyWith({
    String? id,
    String? siteId,
    String? incidentType,
    String? severity,
    String? description,
    String? photoUrl,
    String? status,
    String? reportedBy,
    String? resolvedBy,
    DateTime? createdAt,
    DateTime? resolvedAt,
  }) {
    return IncidentModel(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      incidentType: incidentType ?? this.incidentType,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      reportedBy: reportedBy ?? this.reportedBy,
      resolvedBy: resolvedBy ?? this.resolvedBy,
      createdAt: createdAt ?? this.createdAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
