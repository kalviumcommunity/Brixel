import 'package:brixel/features/auth/widgets/logout_button.dart';
import 'package:flutter/material.dart';

class PendingAccessScreen extends StatelessWidget {
  const PendingAccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access pending'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.hourglass_top_rounded,
                  size: 56,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 20),
                Text(
                  'Your account is waiting for approval',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your role and construction-site access must be assigned '
                  'before you can use site reporting features.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                const LogoutButton(navigateAfterSignOut: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
