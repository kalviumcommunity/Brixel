import 'package:brixel/features/materials/models/material_model.dart';
import 'package:brixel/features/materials/repositories/firestore_material_usage_write_repository.dart';
import 'package:brixel/core/services/firestore_database_service.dart';
import 'package:brixel/features/auth/services/firebase_auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Site-scoped report persistence. Creates are deliberately not retried: an
/// uncertain network response must not silently generate duplicate reports.
class SiteReportRepository {
  SiteReportRepository({
    FirestoreDatabaseService? database,
    String Function()? userId,
  }) : _database = database ?? FirestoreDatabaseService(),
       _userId = userId ?? (() => FirebaseAuthService().currentUser?.uid ?? '');

  final FirestoreDatabaseService _database;
  final String Function() _userId;

  String _author(String siteId) {
    if (siteId.trim().isEmpty) throw ArgumentError('Select a site first.');
    final uid = _userId();
    if (uid.isEmpty) throw StateError('Sign in to submit reports.');
    return uid;
  }

  static String dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> saveAttendance(String siteId, Map<String, dynamic> data) async {
    final uid = _author(siteId);
    final hours = (data['hoursWorked'] as num).toDouble();
    final status = (data['status'] as String).toLowerCase();
    if (!hours.isFinite ||
        hours < 0 ||
        hours > 24 ||
        (status == 'present' && hours == 0)) {
      throw ArgumentError('Invalid hours.');
    }
    if (status == 'absent' && hours != 0) {
      throw ArgumentError('Absent workers must have zero hours.');
    }
    await _database.addAttendanceReport({
      ...data,
      'status': status,
      'siteId': siteId,
      'recordedBy': uid,
      'date': dateKey(DateTime.now()),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> saveMaterial(String siteId, Map<String, dynamic> data) async {
    final uid = _author(siteId);
    final quantity = (data['quantity'] as num).toDouble();
    if (!quantity.isFinite || quantity <= 0) {
      throw ArgumentError('Invalid quantity.');
    }
    await FirestoreMaterialUsageWriteRepository(databaseService: _database)
        .addUsage(
          activeSiteId: siteId,
          usage: MaterialTransactionModel(
            id: '',
            materialId: '',
            siteId: siteId,
            materialName: data['materialName'] as String,
            unit: data['unit'] as String,
            type: 'used',
            quantity: quantity,
            notes: data['notes'] as String?,
            recordedBy: uid,
            timestamp: DateTime.now(),
          ),
        );
  }

  Stream<List<Map<String, dynamic>>> watch(String siteId, String collection) {
    if (siteId.trim().isEmpty) throw ArgumentError('Select a site first.');
    final reference = switch (collection) {
      'attendance' => _database.attendanceCollection,
      'incidents' => _database.incidentsCollection,
      'material_transactions' => _database.transactionsCollection,
      _ => throw ArgumentError('Unsupported report type.'),
    };
    return reference
        .where('siteId', isEqualTo: siteId)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList(),
        );
  }
}
