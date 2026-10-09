import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:flutter/material.dart';

/// A reusable Stateless Widget representing a worker card for site attendance.
///
/// Adheres to the Brixel design system:
/// - Pure function of its constructor inputs
/// - Renders a worker avatar, full name, worker ID, role, and attendance status
class BrixelWorkerCard extends StatelessWidget {
  final String name;
  final String role;
  final String workerId;
  final String status;
  final String? avatarUrl;
  final VoidCallback? onTap;

  const BrixelWorkerCard({
    super.key,
    required this.name,
    required this.role,
    required this.workerId,
    this.status = 'Present',
    this.avatarUrl,
    this.onTap,
  });

  bool get isPresent =>
      status.toLowerCase() == 'present' || status.toLowerCase() == 'on-site';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusBgColor =
        isPresent ? const Color(0xFFE8F5E9) : const Color(0xFFFFEBEE);
    final statusTextColor =
        isPresent ? const Color(0xFF2E7D32) : const Color(0xFFC62828);

    final cardContent = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrixelColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: BrixelColors.primarySoft,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl!) : null,
            child: avatarUrl == null
                ? Text(
                    _getInitials(name),
                    style: const TextStyle(
                      color: BrixelColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: BrixelColors.primaryText,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$workerId • $role',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: BrixelColors.secondaryText,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: statusTextColor,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  String _getInitials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }
}
