import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Firestore Security Rules Configuration & Integrity', () {
    late File rulesFile;
    late File firebaseJsonFile;
    late String rulesContent;
    late Map<String, dynamic> firebaseJson;

    setUpAll(() {
      rulesFile = File('firestore.rules');
      firebaseJsonFile = File('firebase.json');

      expect(rulesFile.existsSync(), isTrue,
          reason: 'firestore.rules file must exist in the project root');
      expect(firebaseJsonFile.existsSync(), isTrue,
          reason: 'firebase.json must exist in the project root');

      rulesContent = rulesFile.readAsStringSync();
      firebaseJson = jsonDecode(firebaseJsonFile.readAsStringSync())
          as Map<String, dynamic>;
    });

    test('Task 1: firebase.json properly configures firestore rules path', () {
      expect(firebaseJson.containsKey('firestore'), isTrue,
          reason: 'firebase.json must contain firestore configuration');
      final firestoreConfig = firebaseJson['firestore'] as Map<String, dynamic>;
      expect(firestoreConfig['rules'], equals('firestore.rules'),
          reason: 'firebase.json must link firestore.rules');
    });

    test('Task 1: firestore.rules declares rules_version 2 and service cloud.firestore', () {
      expect(rulesContent, contains("rules_version = '2';"),
          reason: 'Must declare rules_version 2');
      expect(rulesContent, contains('service cloud.firestore'),
          reason: 'Must target cloud.firestore service');
      expect(rulesContent, contains('match /databases/{database}/documents'),
          reason: 'Must match document root');
    });

    test('Task 2 & 3: Declares reusable access control helpers', () {
      expect(rulesContent, contains('function isAuthenticated()'),
          reason: 'Must define isAuthenticated helper');
      expect(rulesContent, contains('request.auth != null'),
          reason: 'isAuthenticated must verify request.auth != null');

      expect(rulesContent, contains('function isOwner('),
          reason: 'Must define isOwner helper');
      expect(rulesContent, contains('request.auth.uid == userId'),
          reason: 'isOwner must verify request.auth.uid matches userId');

      expect(rulesContent, contains('function isSupervisorOrManager()'),
          reason: 'Must define role helper for elevated access');
      expect(rulesContent, contains('function isManager()'),
          reason: 'Must define manager role helper');
    });

    test('Task 3: Enforces default denial for unmatched paths', () {
      expect(rulesContent, contains('match /{document=**}'),
          reason: 'Must include catch-all path match');
      expect(rulesContent, contains('allow read, write: if false;'),
          reason: 'Catch-all must explicitly deny read and write');
    });

    test('Task 4: Match rules to Users collection (/users/{userId})', () {
      expect(rulesContent, contains('match /users/{userId}'),
          reason: 'Must have rules for users collection');
      expect(rulesContent, contains('allow read: if isOwner(userId) || isSupervisorOrManager();'),
          reason: 'Users can read own profile; supervisors/managers can read');
      expect(rulesContent, contains('request.resource.data.role != \'manager\''),
          reason: 'Prevent unprivileged self-promotion to manager on registration');
    });

    test('Task 4: Match rules to Sites collection (/sites/{siteId})', () {
      expect(rulesContent, contains('match /sites/{siteId}'),
          reason: 'Must have rules for sites collection');
      expect(rulesContent, contains('allow read: if isAuthenticated();'),
          reason: 'Authenticated users can view sites');
      expect(rulesContent, contains('allow create, update, delete: if isSupervisorOrManager();'),
          reason: 'Only supervisors/managers can modify site records');
    });

    test('Task 4: Match rules to Attendance collection (/attendance/{attendanceId})', () {
      expect(rulesContent, contains('match /attendance/{attendanceId}'),
          reason: 'Must have rules for attendance collection');
      expect(rulesContent, contains('request.resource.data.recordedBy == request.auth.uid'),
          reason: 'Creating attendance must enforce author identity matching');
      expect(rulesContent, contains('resource.data.recordedBy == request.auth.uid'),
          reason: 'Editing attendance requires author or manager access');
    });

    test('Task 4: Match rules to Materials collection (/materials/{materialId})', () {
      expect(rulesContent, contains('match /materials/{materialId}'),
          reason: 'Must have rules for materials inventory');
      expect(rulesContent, contains('allow read: if isAuthenticated();'),
          reason: 'Authenticated users can view inventory');
      expect(rulesContent, contains('allow create, update: if isSupervisorOrManager();'),
          reason: 'Inventory adjustment requires supervisor or manager role');
    });

    test('Task 4: Match rules to Material Transactions (/material_transactions/{txId})', () {
      expect(rulesContent, contains('match /material_transactions/{txId}'),
          reason: 'Must have rules for material transactions audit trail');
      expect(rulesContent, contains('request.resource.data.recordedBy == request.auth.uid'),
          reason: 'Transaction creation requires author identity verification');
    });

    test('Task 4: Match rules to Safety Incidents (/incidents/{incidentId})', () {
      expect(rulesContent, contains('match /incidents/{incidentId}'),
          reason: 'Must have rules for safety incidents');
      expect(rulesContent, contains('request.resource.data.reportedBy == request.auth.uid'),
          reason: 'Reporting an incident requires matching reporter auth UID');
      expect(rulesContent, contains('resource.data.reportedBy == request.auth.uid || isSupervisorOrManager()'),
          reason: 'Status transitions and updates allowed for reporter or supervisor/manager');
    });
  });

  group('Simulated Security Rules Logical Behavior Tests', () {
    // Model rule evaluation conditions purely in Dart to verify authorization logic
    bool evaluateIsAuthenticated(Map<String, dynamic>? auth) {
      return auth != null && auth['uid'] != null;
    }

    bool evaluateIsOwner(Map<String, dynamic>? auth, String targetUserId) {
      return evaluateIsAuthenticated(auth) && auth!['uid'] == targetUserId;
    }

    bool evaluateUserCreate({
      required Map<String, dynamic>? auth,
      required String targetUserId,
      required Map<String, dynamic> incomingData,
    }) {
      if (!evaluateIsOwner(auth, targetUserId)) return false;
      final role = incomingData['role'] as String? ?? 'pending';
      if (role == 'manager') {
        final isMgr = auth!['role'] == 'manager';
        return isMgr;
      }
      return true;
    }

    bool evaluateIncidentCreate({
      required Map<String, dynamic>? auth,
      required Map<String, dynamic> incomingData,
    }) {
      if (!evaluateIsAuthenticated(auth)) return false;
      return incomingData['reportedBy'] == auth!['uid'];
    }

    bool evaluateIncidentUpdate({
      required Map<String, dynamic>? auth,
      required Map<String, dynamic> existingDoc,
    }) {
      if (!evaluateIsAuthenticated(auth)) return false;
      final isReporter = existingDoc['reportedBy'] == auth!['uid'];
      final isElevated = auth['role'] == 'supervisor' || auth['role'] == 'manager';
      return isReporter || isElevated;
    }

    test('Task 2 & 3: Unauthenticated requests are completely rejected', () {
      expect(evaluateIsAuthenticated(null), isFalse);
      expect(evaluateIsOwner(null, 'usr_101'), isFalse);
      expect(
        evaluateIncidentCreate(
          auth: null,
          incomingData: {'reportedBy': 'usr_101', 'severity': 'high'},
        ),
        isFalse,
      );
    });

    test('Task 2: Owner can access their own document', () {
      final userAuth = {'uid': 'usr_sup_101', 'role': 'supervisor'};
      expect(evaluateIsOwner(userAuth, 'usr_sup_101'), isTrue);
    });

    test('Task 3: Non-owner cannot access or modify another user\'s document', () {
      final attackerAuth = {'uid': 'usr_attacker', 'role': 'pending'};
      expect(evaluateIsOwner(attackerAuth, 'usr_victim_102'), isFalse);
    });

    test('Task 3: Unprivileged user cannot elevate themselves to manager', () {
      final regularAuth = {'uid': 'usr_worker_50', 'role': 'pending'};
      final allowedSelfRegister = evaluateUserCreate(
        auth: regularAuth,
        targetUserId: 'usr_worker_50',
        incomingData: {'role': 'pending', 'displayName': 'Worker 50'},
      );
      expect(allowedSelfRegister, isTrue);

      final attemptedElevation = evaluateUserCreate(
        auth: regularAuth,
        targetUserId: 'usr_worker_50',
        incomingData: {'role': 'manager', 'displayName': 'Hacked Manager'},
      );
      expect(attemptedElevation, isFalse,
          reason: 'Non-manager cannot self-register as manager');
    });

    test('Task 4: Incident author matching prevents spoofing reportedBy', () {
      final workerAuth = {'uid': 'usr_worker_1', 'role': 'pending'};

      // Author matches auth.uid -> ALLOWED
      final legitReport = evaluateIncidentCreate(
        auth: workerAuth,
        incomingData: {'reportedBy': 'usr_worker_1', 'severity': 'medium'},
      );
      expect(legitReport, isTrue);

      // Author spoofing another user -> REJECTED
      final spoofedReport = evaluateIncidentCreate(
        auth: workerAuth,
        incomingData: {'reportedBy': 'usr_someone_else', 'severity': 'high'},
      );
      expect(spoofedReport, isFalse);
    });

    test('Task 4: Supervisors and managers can transition incident status', () {
      final supervisorAuth = {'uid': 'usr_sup_101', 'role': 'supervisor'};
      final existingIncident = {'reportedBy': 'usr_worker_1', 'status': 'reported'};

      final canSupervisorUpdate = evaluateIncidentUpdate(
        auth: supervisorAuth,
        existingDoc: existingIncident,
      );
      expect(canSupervisorUpdate, isTrue);

      final unrelatedWorkerAuth = {'uid': 'usr_worker_2', 'role': 'pending'};
      final canUnrelatedWorkerUpdate = evaluateIncidentUpdate(
        auth: unrelatedWorkerAuth,
        existingDoc: existingIncident,
      );
      expect(canUnrelatedWorkerUpdate, isFalse);
    });
  });
}
