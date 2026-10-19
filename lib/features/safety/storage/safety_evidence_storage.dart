import 'dart:typed_data';

abstract class SafetyEvidenceStorage {
  Future<String> uploadEvidence({
    required String siteId,
    required String incidentId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  });
}
