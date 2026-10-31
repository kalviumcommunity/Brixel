import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/auth/models/user_model.dart';
import 'package:brixel/features/auth/services/user_authentication.dart';
import 'package:brixel/features/auth/widgets/logout_button.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:flutter/material.dart';

class PendingAccessScreen extends StatelessWidget {
  const PendingAccessScreen({super.key, this.profile, this.authService});

  final UserModel? profile;
  final UserAuthentication? authService;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = profile?.email.trim() ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Access pending'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: BrixelColors.primarySoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          color: BrixelColors.primary,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Account created successfully',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Icon(
                    Icons.hourglass_top_rounded,
                    size: 44,
                    color: BrixelColors.primary,
                    semanticLabel: 'Access approval pending',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Your Brixel account is ready',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Access approval is pending',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: BrixelColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "You're signed in successfully. A project manager or administrator needs to assign your role and construction site before you can start reporting.",
                    textAlign: TextAlign.center,
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    BrixelSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Signed in as',
                            style: theme.textTheme.labelLarge,
                          ),
                          const SizedBox(height: 6),
                          SelectableText(
                            email,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  BrixelSectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What happens next',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const _NextStep(
                          number: '1',
                          text: 'Your manager assigns your role and site.',
                        ),
                        const _NextStep(
                          number: '2',
                          text:
                              'Brixel detects the access update automatically.',
                        ),
                        const _NextStep(
                          number: '3',
                          text: 'You are taken to your permitted sites.',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Access updates automatically — you do not need to create another account.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: LogoutButton(
                      authService: authService,
                      navigateAfterSignOut: false,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NextStep extends StatelessWidget {
  const _NextStep({required this.number, required this.text});
  final String number;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$number.',
          style: const TextStyle(
            color: BrixelColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
