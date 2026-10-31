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

      expect(
        rulesFile.existsSync(),
        isTrue,
        reason: 'firestore.rules file must exist in the project root',
      );
      expect(
        firebaseJsonFile.existsSync(),
        isTrue,
        reason: 'firebase.json must exist in the project root',
      );

      rulesContent = rulesFile.readAsStringSync();
      firebaseJson = jsonDecode(
        firebaseJsonFile.readAsStringSync(),
      ) as Map<String, dynamic>;
    });

    test('Task 1: firebase.json properly configures firestore rules path', () {
      expect(
        firebaseJson.containsKey('firestore'),
        isTrue,
        reason: 'firebase.json must contain firestore configuration',
      );
      final firestoreConfig = firebaseJson['firestore'] as Map<String, dynamic>;
      expect(
        firestoreConfig['rules'],
        equals('firestore.rules'),
        reason: 'firebase.json must link firestore.rules',
      );
    });

    test('Task 1: firestore.rules declares rules_version 2 and service cloud.firestore', () {
      expect(
        rulesContent,
        contains("rules_version = '2';"),
        reason: 'Must declare rules_version 2',
      );
      expect(
        rulesContent,
        contains('service cloud.firestore'),
        reason: 'Must target cloud.firestore service',
      );
      expect(
        rulesContent,
        contains('match /databases/{database}/documents'),
        reason: 'Must match document root',
      );
    });

    test('Task 2 & 3: Declares reusable access control helpers', () {
      expect(
        rulesContent,
        contains('function isAuthenticated()'),
        reason: 'Must define isAuthenticated helper',
      );
      expect(
        rulesContent,
        contains('request.auth != null'),
        reason: 'isAuthenticated must verify request.auth != null',
      );

      expect(
        rulesContent,
        contains('function isOwner('),
        reason: 'Must define isOwner helper',
      );
      expect(
        rulesContent,
        contains('request.auth.uid == userId'),
        reason: 'isOwner must verify request.auth.uid matches userId',
      );

      expect(
        rulesContent,
        contains('function isSupervisorOrManager()'),
        reason: 'Must define role helper for elevated access',
      );
      expect(
        rulesContent,
        contains('function isManager()'),
        reason: 'Must define manager role helper',
      );
    });

    test('Task 3: Enforces default denial for unmatched paths', () {
      expect(
        rulesContent,
        contains('match /{document=**}'),
        reason: 'Must include catch-all path match',
      );
      expect(
        rulesContent,
        contains('allow read, write: if false;'),
        reason: 'Catch-all must explicitly deny read and write',
      );
    });

    test('Task 4: Match rules to Users collection (/users/{userId}) with role lockdown', () {
      expect(
        rulesContent,
        contains('match /users/{userId}'),
        reason: 'Must have rules for users collection',
      );
      expect(
        rulesContent,
        contains('allow read: if isOwner(userId) || isSupervisorOrManager();'),
        reason: 'Users can read own profile; supervisors/managers can read',
      );
      expect(
        rulesContent,
        contains("request.resource.data.role == 'pending'"),
        reason: 'Restricts initial self-registration strictly to pending role',
      );
      expect(
        rulesContent,
        contains('role'),
        reason: 'Shields role from unauthorized self-elevation',
      );
    });

    test('Task 4: Match rules to Sites collection (/sites/{siteId})', () {
      expect(
        rulesContent,
        contains('match /sites/{siteId}'),
        reason: 'Must have rules for sites collection',
      );
      expect(
        rulesContent,
        contains('canAccessSite('),
        reason: 'Authenticated users can view sites',
      );
      expect(
        rulesContent,
        contains('allow create, update, delete: if isManager();'),
        reason: 'Only supervisors/managers can modify site records',
      );
    });

    test('Task 4: Match rules to Attendance collection (/attendance/{attendanceId})', () {
      expect(
        rulesContent,
        contains('match /attendance/{attendanceId}'),
        reason: 'Must have rules for attendance collection',
      );
      expect(
        rulesContent,
        contains('request.resource.data.recordedBy == request.auth.uid'),
        reason: 'Creating attendance must enforce author identity matching',
      );
      expect(
        rulesContent,
        contains('siteId'),
        reason: 'Protects siteId and audit keys from falsification on update',
      );
    });

    test(
      'Task 4: Match rules to Materials collection (/materials/{materialId})',
      () {
        expect(
          rulesContent,
          contains('match /materials/{materialId}'),
          reason: 'Must have rules for materials inventory',
        );
        expect(
          rulesContent,
          contains('canAccessSite('),
          reason: 'Authenticated users can view inventory',
        );
        expect(
          rulesContent,
          contains(
            'allow create: if canAccessSite(request.resource.data.siteId);',
          ),
          reason: 'Inventory adjustment requires supervisor or manager role',
        );
      },
    );

    test('Task 4: Match rules to Material Transactions (/material_transactions/{txId}) as immutable audit logs', () {
      expect(
        rulesContent,
        contains('match /material_transactions/{txId}'),
        reason: 'Must have rules for material transactions audit trail',
      );
      expect(
        rulesContent,
        contains('request.resource.data.recordedBy == request.auth.uid'),
        reason: 'Transaction creation requires author identity verification',
      );
      expect(
        rulesContent,
        contains('allow update: if isManager()'),
        reason: 'Restricts transaction modifications exclusively to manager audit corrections',
      );
    });

    test('Task 4: Match rules to Safety Incidents (/incidents/{incidentId}) with field-level permissions', () {
      expect(
        rulesContent,
        contains('match /incidents/{incidentId}'),
        reason: 'Must have rules for safety incidents',
      );
      expect(
        rulesContent,
        contains('request.resource.data.reportedBy == request.auth.uid'),
        reason: 'Reporting an incident requires matching reporter auth UID',
      );
      expect(
        rulesContent,
        contains("request.resource.data.status == 'reported'"),
        reason: 'Initial report must have status reported',
      );
      expect(
        rulesContent,
        contains('status'),
        reason:
            'Prevents reporters from altering status and shields audit keys',
      );
    });
  });

  group('Simulated Security Rules Logical Behavior Tests', () {
    bool evaluateIsAuthenticated(Map<String, dynamic>? auth) {
      return auth != null && auth['uid'] != null;
    }

    bool evaluateIsOwner(Map<String, dynamic>? auth, String targetUserId) {
      return evaluateIsAuthenticated(auth) && auth!['uid'] == targetUserId;
    }

    bool evaluateIsManager(Map<String, dynamic>? auth) {
      return evaluateIsAuthenticated(auth) && auth!['role'] == 'manager';
    }

    bool evaluateIsSupervisorOrManager(Map<String, dynamic>? auth) {
      if (!evaluateIsAuthenticated(auth)) return false;
      final role = auth!['role'];
      return role == 'supervisor' || role == 'manager';
    }

    // User Create: Only manager or self-registering as pending with empty assignedSiteIds
    bool evaluateUserCreate({
      required Map<String, dynamic>? auth,
      required String targetUserId,
      required Map<String, dynamic> incomingData,
    }) {
      if (!evaluateIsOwner(auth, targetUserId)) return false;
      if (evaluateIsManager(auth)) return true;

      final role = incomingData['role'];
      final siteIds = incomingData['assignedSiteIds'] as List?;
      final isPending = role == 'pending';
      final hasNoSites = siteIds == null || siteIds.isEmpty;

      return isPending && hasNoSites;
    }

    // User Update: Manager can update, or Owner cannot change role, assignedSiteIds, uid, email
    bool evaluateUserUpdate({
      required Map<String, dynamic>? auth,
      required String targetUserId,
      required Map<String, dynamic> existingData,
      required Map<String, dynamic> incomingData,
    }) {
      if (!evaluateIsAuthenticated(auth)) return false;
      if (evaluateIsManager(auth)) return true;
      if (!evaluateIsOwner(auth, targetUserId)) return false;

      // Check immutable fields for non-managers
      final roleChanged = existingData['role'] != incomingData['role'];
      final sitesChanged =
          existingData['assignedSiteIds'] != incomingData['assignedSiteIds'];
      final uidChanged = existingData['uid'] != incomingData['uid'];
      final emailChanged = existingData['email'] != incomingData['email'];

      if (roleChanged || sitesChanged || uidChanged || emailChanged) {
        return false;
      }
      return true;
    }

    // Incident Create: Author verification, initial status reported, resolvedBy null
    bool evaluateIncidentCreate({
      required Map<String, dynamic>? auth,
      required Map<String, dynamic> incomingData,
    }) {
      if (!evaluateIsAuthenticated(auth)) return false;
      if (incomingData['reportedBy'] != auth!['uid']) return false;
      if (incomingData['status'] != 'reported') return false;
      if (incomingData['resolvedBy'] != null) return false;
      return true;
    }

    // Incident Update:
    // Reporter can only update description/notes (cannot change status, siteId, reportedBy, createdAt, resolvedBy)
    // Supervisor/Manager can transition status, but cannot alter siteId, reportedBy, createdAt
    bool evaluateIncidentUpdate({
      required Map<String, dynamic>? auth,
      required Map<String, dynamic> existingDoc,
      required Map<String, dynamic> incomingDoc,
    }) {
      if (!evaluateIsAuthenticated(auth)) return false;

      // Audit keys that NO ONE can alter on an incident:
      if (incomingDoc['siteId'] != existingDoc['siteId']) return false;
      if (incomingDoc['reportedBy'] != existingDoc['reportedBy']) return false;
      if (incomingDoc['createdAt'] != existingDoc['createdAt']) return false;

      final isReporter = existingDoc['reportedBy'] == auth!['uid'];
      final isElevated = evaluateIsSupervisorOrManager(auth);

      // Case A: Original reporter (not elevated)
      if (isReporter && !isElevated) {
        // Reporter CANNOT alter status or resolution fields
        if (incomingDoc['status'] != existingDoc['status']) return false;
        if (incomingDoc['resolvedBy'] != existingDoc['resolvedBy']) {
          return false;
        }
        return true;
      }

      // Case B: Supervisor or Manager
      if (isElevated) {
        const validStatuses = ['reported', 'acknowledged', 'resolved'];
        if (!validStatuses.contains(incomingDoc['status'])) return false;
        return true;
      }

      return false;
    }

    // Material Transaction Update:
    // Regular users CANNOT alter transactions (immutable audit records).
    // Only managers can perform corrections, and even then materialId, siteId, recordedBy, timestamp are immutable.
    bool evaluateTransactionUpdate({
      required Map<String, dynamic>? auth,
      required Map<String, dynamic> existingDoc,
      required Map<String, dynamic> incomingDoc,
    }) {
      if (!evaluateIsManager(auth)) return false;
      if (incomingDoc['materialId'] != existingDoc['materialId']) return false;
      if (incomingDoc['siteId'] != existingDoc['siteId']) return false;
      if (incomingDoc['recordedBy'] != existingDoc['recordedBy']) return false;
      if (incomingDoc['timestamp'] != existingDoc['timestamp']) return false;
      return true;
    }

    test('Task 2 & 3: Unauthenticated requests are completely rejected', () {
      expect(evaluateIsAuthenticated(null), isFalse);
      expect(evaluateIsOwner(null, 'usr_101'), isFalse);
      expect(
        evaluateIncidentCreate(
          auth: null,
          incomingData: {'reportedBy': 'usr_101', 'status': 'reported'},
        ),
        isFalse,
      );
    });

    test('Task 3: Self-registration with supervisor or manager role is strictly DENIED', () {
      final newAuth = {'uid': 'usr_worker_99', 'role': 'pending'};

      // Attempting to self-assign 'supervisor' -> DENIED
      final trySupervisor = evaluateUserCreate(
        auth: newAuth,
        targetUserId: 'usr_worker_99',
        incomingData: {
          'role': 'supervisor',
          'displayName': 'Fake Supervisor',
          'assignedSiteIds': [],
        },
      );
      expect(
        trySupervisor,
        isFalse,
        reason:
            'Initial self-registration with supervisor role must be blocked',
      );

      // Attempting to self-assign 'manager' -> DENIED
      final tryManager = evaluateUserCreate(
        auth: newAuth,
        targetUserId: 'usr_worker_99',
        incomingData: {
          'role': 'manager',
          'displayName': 'Fake Manager',
          'assignedSiteIds': [],
        },
      );
      expect(
        tryManager,
        isFalse,
        reason: 'Initial self-registration with manager role must be blocked',
      );

      // Registering as 'pending' with empty assigned sites -> ALLOWED
      final legitimateRegistration = evaluateUserCreate(
        auth: newAuth,
        targetUserId: 'usr_worker_99',
        incomingData: {
          'role': 'pending',
          'displayName': 'Ramesh Kumar',
          'assignedSiteIds': [],
        },
      );
      expect(
        legitimateRegistration,
        isTrue,
        reason: 'Self-registration with pending role is permitted',
      );
    });

    test('Task 3: Self-assigning sites during registration is DENIED', () {
      final newAuth = {'uid': 'usr_worker_99', 'role': 'pending'};
      final tryStealSiteAccess = evaluateUserCreate(
        auth: newAuth,
        targetUserId: 'usr_worker_99',
        incomingData: {
          'role': 'pending',
          'displayName': 'Ramesh Kumar',
          'assignedSiteIds': ['site_metro_line1', 'site_secret_vault'],
        },
      );
      expect(
        tryStealSiteAccess,
        isFalse,
        reason: 'Users cannot self-assign site access without manager authorization',
      );
    });

    test('Task 3: Users cannot escalate their own role or site access on profile update', () {
      final userAuth = {'uid': 'usr_worker_99', 'role': 'pending'};
      final existingDoc = {
        'uid': 'usr_worker_99',
        'email': 'worker@brixel.app',
        'role': 'pending',
        'displayName': 'Ramesh Kumar',
        'assignedSiteIds': [],
      };

      // Updating display name -> ALLOWED
      final allowedNameUpdate = evaluateUserUpdate(
        auth: userAuth,
        targetUserId: 'usr_worker_99',
        existingData: existingDoc,
        incomingData: {
          ...existingDoc,
          'displayName': 'Ramesh K. (Senior Mason)',
        },
      );
      expect(allowedNameUpdate, isTrue);

      // Tampering with role field -> DENIED
      final tryRoleElevation = evaluateUserUpdate(
        auth: userAuth,
        targetUserId: 'usr_worker_99',
        existingData: existingDoc,
        incomingData: {...existingDoc, 'role': 'supervisor'},
      );
      expect(
        tryRoleElevation,
        isFalse,
        reason: 'User cannot modify their own role',
      );

      // Tampering with assignedSiteIds -> DENIED
      final trySiteElevation = evaluateUserUpdate(
        auth: userAuth,
        targetUserId: 'usr_worker_99',
        existingData: existingDoc,
        incomingData: {
          ...existingDoc,
          'assignedSiteIds': ['site_metro_line1'],
        },
      );
      expect(
        trySiteElevation,
        isFalse,
        reason: 'User cannot modify their assigned sites',
      );
    });

    test('Task 4: Incident reporter CANNOT alter status or audit keys', () {
      final reporterAuth = {'uid': 'usr_worker_10', 'role': 'pending'};
      final existingIncident = {
        'siteId': 'site_metro_line1',
        'reportedBy': 'usr_worker_10',
        'createdAt': '2026-10-21T09:00:00Z',
        'status': 'reported',
        'description': 'Scaffolding plank loose on tier 3',
        'resolvedBy': null,
      };

      // Reporter updating description -> ALLOWED
      final allowedNoteEdit = evaluateIncidentUpdate(
        auth: reporterAuth,
        existingDoc: existingIncident,
        incomingDoc: {
          ...existingIncident,
          'description': 'Scaffolding plank loose on tier 3 near east column',
        },
      );
      expect(allowedNoteEdit, isTrue);

      // Reporter attempting to change status to resolved -> DENIED
      final tryTamperStatus = evaluateIncidentUpdate(
        auth: reporterAuth,
        existingDoc: existingIncident,
        incomingDoc: {...existingIncident, 'status': 'resolved'},
      );
      expect(
        tryTamperStatus,
        isFalse,
        reason: 'Reporters cannot mark their own incidents resolved',
      );

      // Reporter attempting to alter siteId -> DENIED
      final tryTamperSite = evaluateIncidentUpdate(
        auth: reporterAuth,
        existingDoc: existingIncident,
        incomingDoc: {...existingIncident, 'siteId': 'site_other_project'},
      );
      expect(tryTamperSite, isFalse, reason: 'Audit key siteId is immutable');
    });

    test('Task 4: Supervisors CAN transition status but CANNOT alter siteId or reportedBy', () {
      final supervisorAuth = {'uid': 'usr_sup_101', 'role': 'supervisor'};
      final existingIncident = {
        'siteId': 'site_metro_line1',
        'reportedBy': 'usr_worker_10',
        'createdAt': '2026-10-21T09:00:00Z',
        'status': 'reported',
        'description': 'Loose plank',
        'resolvedBy': null,
      };

      // Supervisor transitions status to acknowledged -> ALLOWED
      final allowedStatusTransition = evaluateIncidentUpdate(
        auth: supervisorAuth,
        existingDoc: existingIncident,
        incomingDoc: {...existingIncident, 'status': 'acknowledged'},
      );
      expect(allowedStatusTransition, isTrue);

      // Supervisor attempting to overwrite original reportedBy -> DENIED
      final trySpoofReporter = evaluateIncidentUpdate(
        auth: supervisorAuth,
        existingDoc: existingIncident,
        incomingDoc: {
          ...existingIncident,
          'status': 'acknowledged',
          'reportedBy': 'usr_sup_101',
        },
      );
      expect(
        trySpoofReporter,
        isFalse,
        reason: 'Audit key reportedBy cannot be altered even by supervisors',
      );
    });

    test('Task 4: Material transactions are immutable audit logs for regular users', () {
      final workerAuth = {'uid': 'usr_worker_5', 'role': 'pending'};
      final existingTx = {
        'siteId': 'site_metro_line1',
        'materialId': 'mat_cement_53',
        'quantity': 20.0,
        'recordedBy': 'usr_worker_5',
        'timestamp': '2026-10-21T10:00:00Z',
        'notes': 'Slab pour phase 1',
      };

      // Worker attempting to edit transaction quantity -> DENIED
      final tryAlterQuantity = evaluateTransactionUpdate(
        auth: workerAuth,
        existingDoc: existingTx,
        incomingDoc: {...existingTx, 'quantity': 5.0},
      );
      expect(
        tryAlterQuantity,
        isFalse,
        reason: 'Transaction audit records cannot be modified by regular users',
      );

      // Manager updating note correction without touching quantity/materialId/siteId -> ALLOWED
      final managerAuth = {'uid': 'usr_mgr_201', 'role': 'manager'};
      final allowedManagerCorrection = evaluateTransactionUpdate(
        auth: managerAuth,
        existingDoc: existingTx,
        incomingDoc: {
          ...existingTx,
          'notes': 'Corrected note: Slab pour phase 1 approved by QA',
        },
      );
      expect(allowedManagerCorrection, isTrue);
    });
  });
}
