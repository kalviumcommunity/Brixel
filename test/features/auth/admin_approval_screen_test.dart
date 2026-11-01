import 'dart:async';

import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/auth/models/user_model.dart';
import 'package:brixel/features/auth/repositories/user_repository.dart';
import 'package:brixel/features/auth/screens/admin_approval_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class MockUserRepository implements UserRepository {
  MockUserRepository({
    List<UserModel>? initialPending,
    this.shouldThrowError = false,
  }) {
    if (initialPending != null) {
      _pendingUsers.addAll(initialPending);
    }
  }

  final List<UserModel> _pendingUsers = [];
  final bool shouldThrowError;
  late final StreamController<List<UserModel>> _controller =
      StreamController<List<UserModel>>.broadcast(
        onListen: _emit,
        sync: true,
      );

  String? lastApprovedUid;
  String? lastApprovedRole;
  List<String>? lastApprovedSites;
  String? lastRejectedUid;

  void _emit() {
    if (_controller.isClosed) return;
    if (shouldThrowError) {
      _controller.addError(Exception('Database connection failed'));
    } else {
      _controller.add(List<UserModel>.from(_pendingUsers));
    }
  }

  @override
  Stream<UserModel?> watchUserProfile(String uid) => Stream.value(null);

  @override
  Stream<List<UserModel>> watchPendingUsers() => _controller.stream;

  @override
  Future<void> approveUser(
    String uid, {
    String role = 'supervisor',
    List<String> assignedSiteIds = const [],
  }) async {
    lastApprovedUid = uid;
    lastApprovedRole = role;
    lastApprovedSites = assignedSiteIds;
    _pendingUsers.removeWhere((u) => u.uid == uid);
    _emit();
  }

  @override
  Future<void> rejectUser(String uid) async {
    lastRejectedUid = uid;
    _pendingUsers.removeWhere((u) => u.uid == uid);
    _emit();
  }

  void dispose() {
    _controller.close();
  }
}

void main() {
  final sampleDate = DateTime(2026, 11, 1, 10, 30);

  final testPendingUser1 = UserModel(
    uid: 'pending_user_001',
    email: 'karan.sharma@example.com',
    displayName: 'Karan Sharma',
    role: 'pending',
    status: 'pending',
    createdAt: sampleDate,
  );

  final testPendingUser2 = UserModel(
    uid: 'pending_user_002',
    email: 'priya.verma@example.com',
    displayName: 'Priya Verma',
    role: 'pending',
    status: 'pending',
    createdAt: sampleDate.add(const Duration(hours: 1)),
  );

  Widget createTestWidget(UserRepository repository) {
    return MaterialApp(
      theme: buildBrixelTheme(),
      home: AdminApprovalScreen(userRepository: repository),
    );
  }

  group('AdminApprovalScreen', () {
    testWidgets('displays empty state when there are no pending requests', (
      tester,
    ) async {
      final repository = MockUserRepository(initialPending: []);
      addTearDown(repository.dispose);

      await tester.pumpWidget(createTestWidget(repository));
      await tester.pumpAndSettle();

      expect(find.text('No pending registration requests'), findsOneWidget);
      expect(
        find.text('All user accounts are currently up to date.'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('renders list of pending user requests with details', (
      tester,
    ) async {
      final repository = MockUserRepository(
        initialPending: [testPendingUser1, testPendingUser2],
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(createTestWidget(repository));
      await tester.pumpAndSettle();

      expect(find.text('Karan Sharma'), findsOneWidget);
      expect(find.text('karan.sharma@example.com'), findsOneWidget);
      expect(find.text('Doc ID: pending_user_001'), findsOneWidget);

      expect(find.text('Priya Verma'), findsOneWidget);
      expect(find.text('priya.verma@example.com'), findsOneWidget);
      expect(find.text('Doc ID: pending_user_002'), findsOneWidget);

      expect(find.text('Pending'), findsNWidgets(2));
      expect(find.byKey(const Key('approveUser_pending_user_001')), findsOneWidget);
      expect(find.byKey(const Key('rejectUser_pending_user_001')), findsOneWidget);
    });

    testWidgets('approves user as site supervisor by default via role dialog', (
      tester,
    ) async {
      final repository = MockUserRepository(
        initialPending: [testPendingUser1],
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(createTestWidget(repository));
      await tester.pumpAndSettle();

      // Tap Approve
      await tester.tap(find.byKey(const Key('approveUser_pending_user_001')));
      await tester.pumpAndSettle();

      // Dialog is displayed with role options
      expect(find.byKey(const Key('roleSelectionDialog')), findsOneWidget);
      expect(find.text('Site Supervisor'), findsOneWidget);
      expect(find.text('Project Manager'), findsOneWidget);

      // Confirm default role (Site Supervisor)
      await tester.tap(find.byKey(const Key('confirmApprovalButton')));
      await tester.pumpAndSettle();

      expect(repository.lastApprovedUid, 'pending_user_001');
      expect(repository.lastApprovedRole, 'supervisor');
      expect(
        find.text('Karan Sharma approved as Site Supervisor.'),
        findsOneWidget,
      );
      // User is removed from list, now shows empty state
      expect(find.text('No pending registration requests'), findsOneWidget);
    });

    testWidgets('approves user as project manager when selected in dialog', (
      tester,
    ) async {
      final repository = MockUserRepository(
        initialPending: [testPendingUser1],
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(createTestWidget(repository));
      await tester.pumpAndSettle();

      // Tap Approve
      await tester.tap(find.byKey(const Key('approveUser_pending_user_001')));
      await tester.pumpAndSettle();

      // Select Project Manager
      await tester.tap(find.byKey(const Key('roleManagerOption')));
      await tester.pumpAndSettle();

      // Confirm
      await tester.tap(find.byKey(const Key('confirmApprovalButton')));
      await tester.pumpAndSettle();

      expect(repository.lastApprovedUid, 'pending_user_001');
      expect(repository.lastApprovedRole, 'manager');
      expect(
        find.text('Karan Sharma approved as Project Manager.'),
        findsOneWidget,
      );
    });

    testWidgets('rejects user after confirming rejection dialog', (
      tester,
    ) async {
      final repository = MockUserRepository(
        initialPending: [testPendingUser1],
      );
      addTearDown(repository.dispose);

      await tester.pumpWidget(createTestWidget(repository));
      await tester.pumpAndSettle();

      // Tap Reject
      await tester.tap(find.byKey(const Key('rejectUser_pending_user_001')));
      await tester.pumpAndSettle();

      // Rejection confirmation dialog appears
      expect(find.byKey(const Key('confirmRejectDialog')), findsOneWidget);

      // Confirm rejection
      await tester.tap(find.byKey(const Key('confirmRejectButton')));
      await tester.pumpAndSettle();

      expect(repository.lastRejectedUid, 'pending_user_001');
      expect(
        find.text('Registration for Karan Sharma was rejected.'),
        findsOneWidget,
      );
      expect(find.text('No pending registration requests'), findsOneWidget);
    });

    testWidgets('displays error state when stream fails and handles retry', (
      tester,
    ) async {
      final repository = MockUserRepository(shouldThrowError: true);
      addTearDown(repository.dispose);

      await tester.pumpWidget(createTestWidget(repository));
      await tester.pumpAndSettle();

      expect(find.text('Unable to load pending requests'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('UserModel status and backward compatibility', () {
    test('defaults status to approved for supervisor and manager when status is omitted', () {
      final supervisor = UserModel(
        uid: 'sup_1',
        email: 'sup@example.com',
        displayName: 'Supervisor',
        role: 'supervisor',
        createdAt: sampleDate,
      );
      expect(supervisor.status, 'approved');
      expect(supervisor.isApproved, isTrue);
      expect(supervisor.isPending, isFalse);
      expect(supervisor.isRejected, isFalse);

      final manager = UserModel(
        uid: 'mgr_1',
        email: 'mgr@example.com',
        displayName: 'Manager',
        role: 'manager',
        createdAt: sampleDate,
      );
      expect(manager.status, 'approved');
      expect(manager.isApproved, isTrue);
    });

    test('defaults status to pending for role: pending', () {
      final pending = UserModel(
        uid: 'pen_1',
        email: 'pen@example.com',
        displayName: 'Pending',
        role: 'pending',
        createdAt: sampleDate,
      );
      expect(pending.status, 'pending');
      expect(pending.isPending, isTrue);
      expect(pending.isApproved, isFalse);
    });

    test('handles status: rejected properly', () {
      final rejected = UserModel(
        uid: 'rej_1',
        email: 'rej@example.com',
        displayName: 'Rejected',
        role: 'rejected',
        status: 'rejected',
        createdAt: sampleDate,
      );
      expect(rejected.isRejected, isTrue);
      expect(rejected.isApproved, isFalse);
      expect(rejected.isPending, isFalse);
    });

    test('fromMap and toMap preserve status correctly', () {
      final map = {
        'uid': 'usr_42',
        'email': 'usr@example.com',
        'displayName': 'Usr',
        'role': 'supervisor',
        'status': 'approved',
        'assignedSiteIds': ['site_1'],
      };
      final user = UserModel.fromMap(map, 'usr_42');
      expect(user.status, 'approved');
      expect(user.role, 'supervisor');

      final serialized = user.toMap();
      expect(serialized['status'], 'approved');
      expect(serialized['role'], 'supervisor');
    });
  });
}
