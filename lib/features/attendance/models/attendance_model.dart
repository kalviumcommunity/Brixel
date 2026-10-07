import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceRecordModel {
  final String id;
  final String siteId;
  final String workerName; // Worker or crew name
  final String trade; // e.g., Mason, Carpenter, Electrician, General Laborer
  final String status; // 'present' | 'absent' | 'half_day'
  final double hoursWorked;
  final String date; // 'YYYY-MM-DD' formatted for clean grouping and querying
  final String recordedBy; // Supervisor user ID
  final DateTime createdAt;
  final DateTime? updatedAt;

  AttendanceRecordModel({
    required this.id,
    required this.siteId,
    required this.workerName,
    required this.trade,
    required this.status,
    required this.hoursWorked,
    required this.date,
    required this.recordedBy,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'siteId': siteId,
      'workerName': workerName,
      'trade': trade,
      'status': status,
      'hoursWorked': hoursWorked,
      'date': date,
      'recordedBy': recordedBy,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory AttendanceRecordModel.fromMap(Map<String, dynamic> map, String id) {
    return AttendanceRecordModel(
      id: id,
      siteId: map['siteId'] as String? ?? '',
      workerName: map['workerName'] as String? ?? '',
      trade: map['trade'] as String? ?? 'General Laborer',
      status: map['status'] as String? ?? 'present',
      hoursWorked: (map['hoursWorked'] as num?)?.toDouble() ?? 8.0,
      date: map['date'] as String? ?? '',
      recordedBy: map['recordedBy'] as String? ?? '',
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory AttendanceRecordModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AttendanceRecordModel.fromMap(data, doc.id);
  }

  AttendanceRecordModel copyWith({
    String? id,
    String? siteId,
    String? workerName,
    String? trade,
    String? status,
    double? hoursWorked,
    String? date,
    String? recordedBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AttendanceRecordModel(
      id: id ?? this.id,
      siteId: siteId ?? this.siteId,
      workerName: workerName ?? this.workerName,
      trade: trade ?? this.trade,
      status: status ?? this.status,
      hoursWorked: hoursWorked ?? this.hoursWorked,
      date: date ?? this.date,
      recordedBy: recordedBy ?? this.recordedBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
