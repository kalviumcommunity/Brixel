import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String role; // 'pending' | 'supervisor' | 'manager'
  final String status; // 'pending' | 'approved' | 'rejected'
  final List<String> assignedSiteIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    String? status,
    this.assignedSiteIds = const [],
    required this.createdAt,
    this.updatedAt,
  }) : status = status ?? (role == 'pending' ? 'pending' : 'approved');

  bool get isApproved =>
      status == 'approved' ||
      (status != 'rejected' &&
          (role == 'supervisor' || role == 'manager' || role == 'admin'));

  bool get isPending => status == 'pending' || role == 'pending';

  bool get isRejected => status == 'rejected';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role,
      'status': status,
      'assignedSiteIds': assignedSiteIds,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    final role = map['role'] as String? ?? 'pending';
    final status = map['status'] as String? ?? (role == 'pending' ? 'pending' : 'approved');
    return UserModel(
      uid: id,
      email: map['email'] as String? ?? '',
      displayName: map['displayName'] as String? ?? '',
      role: role,
      status: status,
      assignedSiteIds: List<String>.from(map['assignedSiteIds'] ?? []),
      createdAt: (map['createdAt'] is Timestamp)
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (map['updatedAt'] is Timestamp)
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? role,
    String? status,
    List<String>? assignedSiteIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      status: status ?? this.status,
      assignedSiteIds: assignedSiteIds ?? this.assignedSiteIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
