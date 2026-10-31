import 'dart:typed_data';

import 'package:brixel/features/safety/storage/safety_evidence_storage.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseSafetyEvidenceStorage implements SafetyEvidenceStorage {
  FirebaseSafetyEvidenceStorage({this.storage});

  final FirebaseStorage? storage;

  FirebaseStorage get _firebaseStorage => storage ?? FirebaseStorage.instance;
  static String buildEvidencePath({
    required String siteId,
    required String incidentId,
    required String fileName,
  }) {
    final normalizedSiteId = siteId.trim();
    final normalizedIncidentId = incidentId.trim();
    final normalizedFileName = fileName.trim();

    if (normalizedSiteId.isEmpty || normalizedSiteId.contains('/')) {
      throw ArgumentError('Site ID cannot be empty.');
    }

    if (normalizedIncidentId.isEmpty || normalizedIncidentId.contains('/')) {
      throw ArgumentError('Incident ID cannot be empty.');
    }

    if (normalizedFileName.isEmpty ||
        normalizedFileName.contains('/') ||
        normalizedFileName.contains('\\')) {
      throw ArgumentError('File name cannot be empty.');
    }

    return 'sites/$normalizedSiteId/'
        'safety/$normalizedIncidentId/'
        'evidence/$normalizedFileName';
  }

  @override
  Future<String> uploadEvidence({
    required String siteId,
    required String incidentId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final storagePath = buildEvidencePath(
      siteId: siteId,
      incidentId: incidentId,
      fileName: fileName,
    );

    final normalizedContentType = contentType.trim();

    if (normalizedContentType.isEmpty) {
      throw ArgumentError('Content type cannot be empty.');
    }

    if (!const [
      'image/jpeg',
      'image/png',
      'image/webp',
      'image/gif',
      'image/heic',
      'image/heif',
    ].contains(normalizedContentType)) {
      throw ArgumentError('Evidence must be an image.');
    }
    if (bytes.length > 10 * 1024 * 1024) {
      throw ArgumentError('Evidence must be at most 10 MB.');
    }
    if (bytes.isEmpty) {
      throw ArgumentError('Evidence file cannot be empty.');
    }

    final reference = _firebaseStorage.ref().child(storagePath);

    final metadata = SettableMetadata(contentType: normalizedContentType);

    await reference.putData(bytes, metadata);

    return reference.getDownloadURL();
  }
}
