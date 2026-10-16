import 'package:brixel/features/auth/models/user_model.dart';
import 'package:brixel/features/auth/repositories/firestore_user_repository.dart';
import 'package:brixel/features/auth/repositories/user_repository.dart';
import 'package:brixel/features/auth/screens/login_screen.dart';
import 'package:brixel/features/auth/screens/pending_access_screen.dart';
import 'package:brixel/features/auth/services/authentication_state.dart';
import 'package:brixel/features/auth/services/firebase_auth_service.dart';
import 'package:brixel/features/auth/widgets/logout_button.dart';
import 'package:brixel/features/sites/screens/site_selection_screen.dart';
import 'package:flutter/material.dart';

class AuthStateGate extends StatefulWidget {
  const AuthStateGate({
    super.key,
    this.authenticationState,
    this.userRepository,
    this.signedOutBuilder,
    this.pendingBuilder,
    this.supervisorBuilder,
    this.managerBuilder,
  });

  final AuthenticationState? authenticationState;
  final UserRepository? userRepository;

  final WidgetBuilder? signedOutBuilder;
  final WidgetBuilder? pendingBuilder;
  final WidgetBuilder? supervisorBuilder;
  final WidgetBuilder? managerBuilder;

  @override
  State<AuthStateGate> createState() => _AuthStateGateState();
}

class _AuthStateGateState extends State<AuthStateGate> {
  late final AuthenticationState _authenticationState;
  late final UserRepository _userRepository;

  @override
  void initState() {
    super.initState();

    _authenticationState = widget.authenticationState ?? FirebaseAuthService();

    _userRepository = widget.userRepository ?? FirestoreUserRepository();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: _authenticationState.watchUserId(),
      builder: (context, authSnapshot) {
        if (authSnapshot.hasError) {
          return const _AuthStateMessageScreen(
            title: 'Unable to verify your account',
            message:
                'Brixel could not verify your authentication state. '
                'Please try again.',
          );
        }

        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        final uid = authSnapshot.data;

        if (uid == null) {
          return widget.signedOutBuilder?.call(context) ??
              const LoginScreen(navigateAfterSignIn: false);
        }

        return StreamBuilder<UserModel?>(
          stream: _userRepository.watchUserProfile(uid),
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return const _AuthStateMessageScreen(
                title: 'Unable to load your access',
                message:
                    'Your account is signed in, but Brixel could not '
                    'load your role and site access.',
                showLogout: true,
              );
            }

            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _AuthLoadingScreen();
            }

            final profile = profileSnapshot.data;

            if (profile == null) {
              return const _AuthStateMessageScreen(
                title: 'Account profile unavailable',
                message:
                    'Your authentication account exists, but no Brixel '
                    'access profile is available yet.',
                showLogout: true,
              );
            }

            return _screenForRole(context, profile);
          },
        );
      },
    );
  }

  Widget _screenForRole(BuildContext context, UserModel profile) {
    switch (profile.role) {
      case 'pending':
        return widget.pendingBuilder?.call(context) ??
            const PendingAccessScreen();

      case 'supervisor':
        return widget.supervisorBuilder?.call(context) ??
            const SiteSelectionScreen();

      case 'manager':
        return widget.managerBuilder?.call(context) ??
            const SiteSelectionScreen();

      default:
        return const _AuthStateMessageScreen(
          title: 'Access unavailable',
          message:
              'Your account has an unsupported access role. '
              'Please contact an administrator.',
          showLogout: true,
        );
    }
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _AuthStateMessageScreen extends StatelessWidget {
  const _AuthStateMessageScreen({
    required this.title,
    required this.message,
    this.showLogout = false,
  });

  final String title;
  final String message;
  final bool showLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 52),
                const SizedBox(height: 20),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(message, textAlign: TextAlign.center),
                if (showLogout) ...[
                  const SizedBox(height: 24),
                  const LogoutButton(navigateAfterSignOut: false),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
