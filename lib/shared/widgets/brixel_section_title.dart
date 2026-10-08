import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:flutter/material.dart';

class BrixelSectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const BrixelSectionTitle({super.key, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: BrixelColors.primaryText,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: BrixelColors.secondaryText,
            ),
          ),
        ],
      ],
    );
  }
}
