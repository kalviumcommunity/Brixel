import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:flutter/material.dart';

class BrixelPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final bool isLoading;
  final Widget? loadingIndicator;

  const BrixelPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.isLoading = false,
    this.loadingIndicator,
  });

  @override
  Widget build(BuildContext context) {
    final Widget buttonChild;
    if (isLoading) {
      buttonChild = loadingIndicator ??
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
    } else if (icon == null) {
      buttonChild = Text(label);
    } else {
      buttonChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon), const SizedBox(width: 8), Text(label)],
      );
    }

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: BrixelColors.primary,
        foregroundColor: Colors.white,
        disabledBackgroundColor: BrixelColors.primary.withValues(alpha: 0.6),
        disabledForegroundColor: Colors.white70,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      child: buttonChild,
    );

    if (!expand) {
      return button;
    }

    return SizedBox(width: double.infinity, child: button);
  }
}
