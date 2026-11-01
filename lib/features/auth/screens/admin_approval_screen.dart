import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/auth/models/user_model.dart';
import 'package:brixel/features/auth/repositories/firestore_user_repository.dart';
import 'package:brixel/features/auth/repositories/user_repository.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:flutter/material.dart';

class AdminApprovalScreen extends StatefulWidget {
  const AdminApprovalScreen({super.key, this.userRepository});

  final UserRepository? userRepository;

  @override
  State<AdminApprovalScreen> createState() => _AdminApprovalScreenState();
}

class _AdminApprovalScreenState extends State<AdminApprovalScreen> {
  late final UserRepository _repository;
  final Set<String> _processingUserIds = <String>{};

  @override
  void initState() {
    super.initState();
    _repository = widget.userRepository ?? FirestoreUserRepository();
  }

  String _formatDate(DateTime date) {
    final year = date.year.toString();
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }

  Future<void> _handleApprove(UserModel user, String role) async {
    setState(() {
      _processingUserIds.add(user.uid);
    });

    try {
      await _repository.approveUser(user.uid, role: role);
      if (!mounted) return;

      final roleLabel = role == 'manager' ? 'Project Manager' : 'Site Supervisor';
      final name = user.displayName.trim().isNotEmpty
          ? user.displayName.trim()
          : user.email;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$name approved as $roleLabel.'),
          backgroundColor: BrixelColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve user: $e'),
          backgroundColor: BrixelColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingUserIds.remove(user.uid);
        });
      }
    }
  }

  Future<void> _handleReject(UserModel user) async {
    setState(() {
      _processingUserIds.add(user.uid);
    });

    try {
      await _repository.rejectUser(user.uid);
      if (!mounted) return;

      final name = user.displayName.trim().isNotEmpty
          ? user.displayName.trim()
          : user.email;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration for $name was rejected.'),
          backgroundColor: BrixelColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject user: $e'),
          backgroundColor: BrixelColors.danger,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _processingUserIds.remove(user.uid);
        });
      }
    }
  }

  Future<void> _showApprovalDialog(UserModel user) async {
    String selectedRole = 'supervisor';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              key: const Key('roleSelectionDialog'),
              title: const Text('Approve User Registration'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Assign an application role for ${user.displayName.trim().isNotEmpty ? user.displayName : user.email}:',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    RadioGroup<String>(
                      groupValue: selectedRole,
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedRole = value;
                          });
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          RadioListTile<String>(
                            key: const Key('roleSupervisorOption'),
                            title: const Text('Site Supervisor'),
                            subtitle: const Text(
                              'Can submit daily site reports, material usage, and safety incidents.',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: 'supervisor',
                          ),
                          RadioListTile<String>(
                            key: const Key('roleManagerOption'),
                            title: const Text('Project Manager'),
                            subtitle: const Text(
                              'Full site oversight, multi-site analytics, and user approval permissions.',
                              style: TextStyle(fontSize: 12),
                            ),
                            value: 'manager',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  key: const Key('confirmApprovalButton'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _handleApprove(user, selectedRole);
                  },
                  child: const Text('Approve & Grant Access'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showRejectDialog(UserModel user) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final name = user.displayName.trim().isNotEmpty
            ? user.displayName.trim()
            : user.email;

        return AlertDialog(
          key: const Key('confirmRejectDialog'),
          title: const Text('Reject Registration'),
          content: Text(
            'Are you sure you want to reject the registration request for $name? The user will be restricted from accessing Brixel.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('confirmRejectButton'),
              style: FilledButton.styleFrom(
                backgroundColor: BrixelColors.danger,
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _handleReject(user);
              },
              child: const Text('Reject Access'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Registration Requests'),
      ),
      body: SafeArea(
        child: StreamBuilder<List<UserModel>>(
          stream: _repository.watchPendingUsers(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: BrixelColors.danger,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Unable to load pending requests',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please verify your admin permissions and connection, then try again.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: BrixelColors.secondaryText),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        onPressed: () => setState(() {}),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  key: Key('adminApprovalsLoading'),
                ),
              );
            }

            final pendingUsers = snapshot.data ?? const <UserModel>[];

            if (pendingUsers.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: BrixelColors.success.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle_outline,
                          size: 48,
                          color: BrixelColors.success,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No pending registration requests',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'All user accounts are currently up to date.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: BrixelColors.secondaryText),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: pendingUsers.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final user = pendingUsers[index];
                final isProcessing = _processingUserIds.contains(user.uid);
                final displayName = user.displayName.trim().isNotEmpty
                    ? user.displayName.trim()
                    : 'Unnamed User';

                return BrixelSectionCard(
                  key: Key('userCard_${user.uid}'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: BrixelColors.primarySoft,
                            child: Text(
                              displayName.isNotEmpty
                                  ? displayName[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: BrixelColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: const TextStyle(
                                    color: BrixelColors.secondaryText,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: BrixelColors.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: BrixelColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                            child: const Text(
                              'Pending',
                              style: TextStyle(
                                color: BrixelColors.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: BrixelColors.background,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(
                                  Icons.badge_outlined,
                                  size: 15,
                                  color: BrixelColors.secondaryText,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Doc ID: ${user.uid}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: BrixelColors.secondaryText,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_outlined,
                                  size: 15,
                                  color: BrixelColors.secondaryText,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Registered: ${_formatDate(user.createdAt)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: BrixelColors.secondaryText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: Key('rejectUser_${user.uid}'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: BrixelColors.danger,
                                side: const BorderSide(color: BrixelColors.danger),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.close, size: 18),
                              label: const Text('Reject'),
                              onPressed: isProcessing
                                  ? null
                                  : () => _showRejectDialog(user),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton.icon(
                              key: Key('approveUser_${user.uid}'),
                              style: FilledButton.styleFrom(
                                backgroundColor: BrixelColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: isProcessing
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Icon(Icons.check, size: 18),
                              label: Text(isProcessing ? 'Saving...' : 'Approve'),
                              onPressed: isProcessing
                                  ? null
                                  : () => _showApprovalDialog(user),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
