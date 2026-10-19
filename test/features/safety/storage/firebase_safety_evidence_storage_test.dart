import 'dart:typed_data';

import 'package:brixel/features/safety/storage/firebase_safety_evidence_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FirebaseSafetyEvidenceStorage path building', () {
    test('builds a site and incident scoped evidence path', () {
      final path = FirebaseSafetyEvidenceStorage.buildEvidencePath(
        siteId: 'site_123',
        incidentId: 'incident_456',
        fileName: 'cracked-column.jpg',
      );

      expect(
        path,
        'sites/site_123/safety/incident_456/evidence/cracked-column.jpg',
      );
    });

    test('trims path inputs before building the storage path', () {
      final path = FirebaseSafetyEvidenceStorage.buildEvidencePath(
        siteId: '  site_123  ',
        incidentId: '  incident_456  ',
        fileName: '  evidence.jpg  ',
      );

      expect(path, 'sites/site_123/safety/incident_456/evidence/evidence.jpg');
    });

    test('rejects an empty site ID', () {
      expect(
        () => FirebaseSafetyEvidenceStorage.buildEvidencePath(
          siteId: '   ',
          incidentId: 'incident_456',
          fileName: 'evidence.jpg',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects an empty incident ID', () {
      expect(
        () => FirebaseSafetyEvidenceStorage.buildEvidencePath(
          siteId: 'site_123',
          incidentId: '   ',
          fileName: 'evidence.jpg',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects an empty file name', () {
      expect(
        () => FirebaseSafetyEvidenceStorage.buildEvidencePath(
          siteId: 'site_123',
          incidentId: 'incident_456',
          fileName: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('FirebaseSafetyEvidenceStorage upload validation', () {
    test('rejects an empty content type before accessing Firebase', () async {
      final storage = FirebaseSafetyEvidenceStorage();

      await expectLater(
        storage.uploadEvidence(
          siteId: 'site_123',
          incidentId: 'incident_456',
          fileName: 'evidence.jpg',
          bytes: Uint8List.fromList([1, 2, 3]),
          contentType: '   ',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects empty evidence bytes before accessing Firebase', () async {
      final storage = FirebaseSafetyEvidenceStorage();

      await expectLater(
        storage.uploadEvidence(
          siteId: 'site_123',
          incidentId: 'incident_456',
          fileName: 'evidence.jpg',
          bytes: Uint8List(0),
          contentType: 'image/jpeg',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
