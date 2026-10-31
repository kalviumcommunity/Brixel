import 'dart:convert';
import 'dart:typed_data';

import 'package:brixel/features/safety/models/incident_model.dart';
import 'package:brixel/features/safety/repositories/safety_incident_write_repository.dart';
import 'package:brixel/features/safety/screens/safety_incident_form_screen.dart';
import 'package:brixel/features/safety/storage/safety_evidence_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

class FakeSafetyIncidentRepository implements SafetyIncidentWriteRepository {
  IncidentModel? addedIncident;
  bool shouldFail = false;

  @override
  String createIncidentId() => 'incident-test-1';

  @override
  Future<String> addIncident({
    required String activeSiteId,
    required IncidentModel incident,
  }) async {
    if (shouldFail) throw StateError('internal write failure');
    addedIncident = incident;
    return incident.id;
  }

  @override
  Future<void> deleteIncident({required String incidentId}) async {}

  @override
  Future<void> updateIncidentFields({
    required String incidentId,
    required Map<String, dynamic> fields,
  }) async {}

  @override
  Future<void> updateIncidentStatus({
    required String incidentId,
    required String status,
    String? resolvedBy,
  }) async {}
}

class FakeSafetyEvidenceStorage implements SafetyEvidenceStorage {
  String? downloadUrl = 'https://example.test/evidence.jpg';
  String? uploadedSiteId;
  String? uploadedIncidentId;
  String? uploadedFileName;
  Uint8List? uploadedBytes;
  String? uploadedContentType;
  Object? error;

  @override
  Future<String> uploadEvidence({
    required String siteId,
    required String incidentId,
    required String fileName,
    required Uint8List bytes,
    required String contentType,
  }) async {
    uploadedSiteId = siteId;
    uploadedIncidentId = incidentId;
    uploadedFileName = fileName;
    uploadedBytes = bytes;
    uploadedContentType = contentType;
    if (error != null) throw error!;
    return downloadUrl!;
  }
}

const _pixelPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jx6kAAAAASUVORK5CYII=';

final _imageBytes = Uint8List.fromList(base64.decode(_pixelPngBase64));

Widget buildForm({
  FakeSafetyIncidentRepository? repository,
  FakeSafetyEvidenceStorage? evidenceStorage,
  Future<XFile?> Function()? pickImage,
}) {
  return MaterialApp(
    home: SafetyIncidentFormScreen(
      siteId: 'site-test',
      siteName: 'Test site',
      reportedBy: 'supervisor-test',
      repository: repository ?? FakeSafetyIncidentRepository(),
      evidenceStorage: evidenceStorage ?? FakeSafetyEvidenceStorage(),
      pickImage: pickImage,
    ),
  );
}

Future<void> enterValidIncident(WidgetTester tester) async {
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Location / Site Area'),
    'Level 2 slab',
  );
  await tester.enterText(
    find.widgetWithText(TextFormField, 'Description'),
    'Worker slipped near temporary stair edge.',
  );
}

Future<void> scrollToBottom(WidgetTester tester) async {
  await tester.drag(find.byType(ListView), const Offset(0, -700));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('tab submission preserves the containing authenticated route', (
    tester,
  ) async {
    final repository = FakeSafetyIncidentRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => SafetyIncidentFormScreen(
                    siteId: 'site-test',
                    reportedBy: 'supervisor-test',
                    repository: repository,
                    popOnSuccess: false,
                  ),
                ),
              ),
              child: const Text('Open site'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open site'));
    await tester.pumpAndSettle();
    await enterValidIncident(tester);
    await scrollToBottom(tester);
    await tester.tap(find.byKey(const Key('submitIncidentButton')));
    await tester.pumpAndSettle();
    expect(repository.addedIncident?.siteId, 'site-test');
    expect(find.byType(SafetyIncidentFormScreen), findsOneWidget);
    expect(find.text('Open site'), findsNothing);
  });

  testWidgets('safety description is configured for multiline input', (
    tester,
  ) async {
    await tester.pumpWidget(buildForm());

    final descriptionField = tester.widget<EditableText>(
      find.descendant(
        of: find.widgetWithText(TextFormField, 'Description'),
        matching: find.byType(EditableText),
      ),
    );

    expect(descriptionField.keyboardType, TextInputType.multiline);
    expect(descriptionField.textInputAction, TextInputAction.newline);
    expect(descriptionField.minLines, 4);
    expect(descriptionField.maxLines, 6);
  });

  testWidgets('safety form renders and captures details', (tester) async {
    await tester.pumpWidget(buildForm());

    expect(find.text('Safety Incident Report'), findsOneWidget);
    expect(find.text('Location / Site Area'), findsOneWidget);
    expect(find.text('Incident Type'), findsOneWidget);
    expect(find.text('Severity'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Incident Photo / Evidence'), findsOneWidget);

    await enterValidIncident(tester);

    expect(find.text('Level 2 slab'), findsOneWidget);
    expect(
      find.text('Worker slipped near temporary stair edge.'),
      findsOneWidget,
    );
  });

  testWidgets('safety location and description are required', (tester) async {
    await tester.pumpWidget(buildForm());

    await scrollToBottom(tester);
    await tester.tap(find.text('Submit Incident'));
    await tester.pump();

    expect(
      find.text('Please enter the location or site area.'),
      findsOneWidget,
    );
    expect(find.text('Please describe the incident.'), findsOneWidget);
  });

  testWidgets('safety description requires at least five characters', (
    tester,
  ) async {
    await tester.pumpWidget(buildForm());
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Location / Site Area'),
      'Level 2 slab',
    );
    final descriptionField = find.widgetWithText(TextFormField, 'Description');

    await tester.enterText(descriptionField, 'Slip');
    await scrollToBottom(tester);
    await tester.tap(find.text('Submit Incident'));
    await tester.pump();

    expect(
      find.text('Description must be at least 5 characters.'),
      findsOneWidget,
    );
    await tester.enterText(descriptionField, 'Valid incident description');
    await tester.enterText(descriptionField, 'Valid incident description');
    await scrollToBottom(tester);
    await tester.tap(find.text('Submit Incident'));
    await tester.pumpAndSettle();

    expect(
      find.text('Safety incident reported for Level 2 slab'),
      findsOneWidget,
    );
  });

  testWidgets('selects and previews evidence image', (tester) async {
    await tester.pumpWidget(
      buildForm(
        pickImage: () async => XFile.fromData(
          _imageBytes,
          name: 'evidence.png',
          mimeType: 'image/png',
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('selectEvidenceButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('selectEvidenceButton')));
    await tester.pump();

    expect(find.byKey(const Key('selectedEvidencePreview')), findsOneWidget);
    expect(find.byKey(const Key('removeEvidenceButton')), findsOneWidget);
  });

  testWidgets('uploads evidence and saves returned URL with incident', (
    tester,
  ) async {
    final repository = FakeSafetyIncidentRepository();
    final evidenceStorage = FakeSafetyEvidenceStorage();
    await tester.pumpWidget(
      buildForm(
        repository: repository,
        evidenceStorage: evidenceStorage,
        pickImage: () async => XFile.fromData(
          _imageBytes,
          name: 'evidence.png',
          mimeType: 'image/png',
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('selectEvidenceButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('selectEvidenceButton')));
    await tester.pump();
    await enterValidIncident(tester);
    await scrollToBottom(tester);
    await tester.tap(find.byKey(const Key('submitIncidentButton')));
    await tester.pumpAndSettle();

    expect(evidenceStorage.uploadedSiteId, 'site-test');
    expect(evidenceStorage.uploadedIncidentId, 'incident-test-1');
    expect(evidenceStorage.uploadedFileName, 'evidence.png');
    expect(evidenceStorage.uploadedBytes, _imageBytes);
    expect(evidenceStorage.uploadedContentType, 'image/png');
    expect(
      repository.addedIncident?.photoUrl,
      'https://example.test/evidence.jpg',
    );
    expect(repository.addedIncident?.siteId, 'site-test');
  });

  testWidgets('handles image upload errors without exposing internals', (
    tester,
  ) async {
    final repository = FakeSafetyIncidentRepository();
    final evidenceStorage = FakeSafetyEvidenceStorage()
      ..error = StateError('private storage details');
    await tester.pumpWidget(
      buildForm(
        repository: repository,
        evidenceStorage: evidenceStorage,
        pickImage: () async => XFile.fromData(
          _imageBytes,
          name: 'evidence.png',
          mimeType: 'image/png',
        ),
      ),
    );

    await tester.ensureVisible(find.byKey(const Key('selectEvidenceButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('selectEvidenceButton')));
    await tester.pump();
    await enterValidIncident(tester);
    await scrollToBottom(tester);
    await tester.tap(find.byKey(const Key('submitIncidentButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not submit incident. Please try again.'),
      findsOneWidget,
    );
    expect(find.textContaining('private storage details'), findsNothing);
    expect(repository.addedIncident, isNull);
  });
}
