import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/auth/models/user_model.dart';
import '../../features/sites/models/site_model.dart';
import '../../features/attendance/models/attendance_model.dart';
import '../../features/materials/models/material_model.dart';
import '../../features/safety/models/incident_model.dart';

/// Helper service demonstrating consistent document creation,
/// sample data seeding, and query patterns for the Brixel mobile app.
class FirestoreDatabaseService {
  final FirebaseFirestore _firestore;

  FirestoreDatabaseService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Collection References
  CollectionReference<Map<String, dynamic>> get usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get sitesCollection =>
      _firestore.collection('sites');

  CollectionReference<Map<String, dynamic>> get attendanceCollection =>
      _firestore.collection('attendance');

  CollectionReference<Map<String, dynamic>> get materialsCollection =>
      _firestore.collection('materials');

  CollectionReference<Map<String, dynamic>> get transactionsCollection =>
      _firestore.collection('material_transactions');

  CollectionReference<Map<String, dynamic>> get incidentsCollection =>
      _firestore.collection('incidents');

  // --- SEEDING SAMPLE DATA WITH CONSISTENT STRUCTURE ---

  Future<void> seedInitialData() async {
    // 1. Seed Supervisor User
    final supervisorDoc = usersCollection.doc('usr_sup_101');
    await supervisorDoc.set({
      'uid': 'usr_sup_101',
      'email': 'supervisor.meera@brixel.app',
      'displayName': 'Meera Sundaram',
      'role': 'supervisor',
      'assignedSiteIds': ['site_metro_line1', 'site_tower_b'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 2. Seed Project Manager User
    final managerDoc = usersCollection.doc('usr_mgr_201');
    await managerDoc.set({
      'uid': 'usr_mgr_201',
      'email': 'manager.arjun@brixel.app',
      'displayName': 'Arjun Rao',
      'role': 'manager',
      'assignedSiteIds': ['site_metro_line1', 'site_tower_b'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 3. Seed Construction Site
    final siteDoc = sitesCollection.doc('site_metro_line1');
    await siteDoc.set({
      'name': 'Metro Line 1 - Station Pier 4',
      'location': 'Madhapur, Hyderabad',
      'status': 'active',
      'expectedHeadcount': 45,
      'assignedSupervisorIds': ['usr_sup_101'],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 4. Seed Daily Attendance Record
    final attendanceDoc = attendanceCollection.doc('att_20261007_001');
    await attendanceDoc.set({
      'siteId': 'site_metro_line1',
      'workerName': 'Ramesh Kumar (Mason Crew Alpha)',
      'trade': 'Mason',
      'status': 'present',
      'hoursWorked': 8.5,
      'date': '2026-10-07',
      'recordedBy': 'usr_sup_101',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 5. Seed Material Item with Low Stock alert capability
    final cementDoc = materialsCollection.doc('mat_cement_53');
    await cementDoc.set({
      'siteId': 'site_metro_line1',
      'materialName': 'OPC 53 Grade Cement',
      'unit': 'bags',
      'currentStock': 85.0,
      'reorderThreshold': 100.0, // Triggers low-stock alert
      'updatedAt': FieldValue.serverTimestamp(),
    });

    // 6. Seed Material Transaction (Usage)
    final txDoc = transactionsCollection.doc('tx_20261007_01');
    await txDoc.set({
      'materialId': 'mat_cement_53',
      'siteId': 'site_metro_line1',
      'type': 'used',
      'quantity': 25.0,
      'notes': 'Pier footing concrete pour phase 2',
      'recordedBy': 'usr_sup_101',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 7. Seed Safety Incident (High Severity)
    final incidentDoc = incidentsCollection.doc('inc_20261007_001');
    await incidentDoc.set({
      'siteId': 'site_metro_line1',
      'incidentType': 'equipment_failure',
      'severity': 'high',
      'description': 'Hydraulic oil leakage detected on Crane #2 hydraulic arm.',
      'photoUrl': 'https://firebasestorage.googleapis.com/v0/b/brixel-app.appspot.com/o/incidents%2Fcrane_leak.jpg',
      'status': 'reported',
      'reportedBy': 'usr_sup_101',
      'resolvedBy': null,
      'createdAt': FieldValue.serverTimestamp(),
      'resolvedAt': null,
    });
  }

  // --- QUERY PATTERNS SUPPORTING FEATURES ---

  /// Stream user profile by UID
  Stream<UserModel?> streamUserProfile(String uid) {
    return usersCollection.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromDocument(doc);
    });
  }

  /// Stream assigned sites for a supervisor
  Stream<List<SiteModel>> streamAssignedSites(List<String> siteIds) {
    if (siteIds.isEmpty) return Stream.value([]);
    return sitesCollection
        .where(FieldPath.documentId, whereIn: siteIds)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SiteModel.fromDocument(doc))
            .toList());
  }

  /// Real-time stream of today's attendance for a specific site (Supervisor view)
  Stream<List<AttendanceRecordModel>> streamDailyAttendance(String siteId, String date) {
    return attendanceCollection
        .where('siteId', isEqualTo: siteId)
        .where('date', isEqualTo: date)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceRecordModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Real-time stream of materials below reorder threshold (Manager alert view)
  Stream<List<MaterialItemModel>> streamLowStockMaterials(String siteId) {
    return materialsCollection
        .where('siteId', isEqualTo: siteId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MaterialItemModel.fromMap(doc.data(), doc.id))
            .where((item) => item.isLowStock)
            .toList());
  }

  /// Real-time stream of active / high-severity incidents across sites (Manager dashboard)
  Stream<List<IncidentModel>> streamHighSeverityIncidents() {
    return incidentsCollection
        .where('severity', whereIn: ['high', 'critical'])
        .where('status', isEqualTo: 'reported')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => IncidentModel.fromMap(doc.data(), doc.id))
            .toList());
  }
}
