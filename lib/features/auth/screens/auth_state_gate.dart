import 'package:brixel/features/sites/repositories/site_repository.dart';
import 'package:brixel/features/auth/models/user_model.dart';
import 'package:brixel/features/auth/repositories/firestore_user_repository.dart';
import 'package:brixel/features/auth/repositories/user_repository.dart';
import 'package:brixel/features/auth/screens/login_screen.dart';
import 'package:brixel/features/auth/screens/pending_access_screen.dart';
import 'package:brixel/features/auth/services/authentication_state.dart';
import 'package:brixel/features/auth/services/firebase_auth_service.dart';
import 'package:brixel/features/auth/services/user_authentication.dart';
import 'package:brixel/features/auth/widgets/logout_button.dart';
import 'package:brixel/features/sites/screens/site_selection_screen.dart';
import 'package:flutter/material.dart';

class AuthStateGate extends StatefulWidget {
  const AuthStateGate({
    super.key,
    this.authenticationState,
    this.userRepository,
    this.siteRepository,
    this.userAuthentication,
    this.signedOutBuilder,
    this.pendingBuilder,
    this.supervisorBuilder,
    this.managerBuilder,
  });

  final AuthenticationState? authenticationState;
  final UserRepository? userRepository;
  final SiteRepository? siteRepository;
  final UserAuthentication? userAuthentication;

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
  late final Stream<String?> _userIds;
  String? _profileUid;
  Stream<UserModel?>? _profileStream;

  @override
  void initState() {
    super.initState();

    _authenticationState = widget.authenticationState ?? FirebaseAuthService();

    _userRepository = widget.userRepository ?? FirestoreUserRepository();
    _userIds = _authenticationState.watchUserId().distinct();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: _userIds,
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
          _profileUid = null;
          _profileStream = null;
          return widget.signedOutBuilder?.call(context) ??
              LoginScreen(
                authService: widget.userAuthentication,
                navigateAfterSignIn: false,
              );
        }

        if (_profileUid != uid) {
          _profileUid = uid;
          _profileStream = _userRepository.watchUserProfile(uid);
        }
        return StreamBuilder<UserModel?>(
          key: ValueKey(uid),
          stream: _profileStream,
          builder: (context, profileSnapshot) {
            if (profileSnapshot.hasError) {
              return _AuthStateMessageScreen(
                title: 'Unable to load your access',
                message:
                    'Your account is signed in, but Brixel could not '
                    'load your role and site access.',
                showLogout: true,
                userAuthentication: widget.userAuthentication,
              );
            }

            if (profileSnapshot.connectionState == ConnectionState.waiting) {
              return const _AuthLoadingScreen();
            }

            final profile = profileSnapshot.data;

            if (profile == null) {
              return _AuthStateMessageScreen(
                title: 'Account profile unavailable',
                message:
                    'Your authentication account exists, but no Brixel '
                    'access profile is available yet.',
                showLogout: true,
                userAuthentication: widget.userAuthentication,
              );
            }

            return _screenForRole(context, profile);
          },
        );
      },
    );
  }

  Widget _authorizedFlow(UserModel profile) {
    // Disposing this navigator removes every protected route on logout,
    // role changes or assignment revocation, including open report forms.
    return _AuthorizedSession(
      key: ValueKey(
        '${profile.uid}:${profile.role}:${profile.assignedSiteIds.join(',')}',
      ),
      profile: profile,
      siteRepository: widget.siteRepository,
      authentication: widget.userAuthentication,
    );
  }

  Widget _screenForRole(BuildContext context, UserModel profile) {
    switch (profile.role) {
      case 'pending':
        return widget.pendingBuilder?.call(context) ??
            PendingAccessScreen(
              profile: profile,
              authService: widget.userAuthentication,
            );

      case 'supervisor':
        return widget.supervisorBuilder?.call(context) ??
            _authorizedFlow(profile);

      case 'manager':
        return widget.managerBuilder?.call(context) ?? _authorizedFlow(profile);

      default:
        return _AuthStateMessageScreen(
          title: 'Access unavailable',
          message:
              'Your account has an unsupported access role. '
              'Please contact an administrator.',
          showLogout: true,
          userAuthentication: widget.userAuthentication,
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
    this.userAuthentication,
  });

  final String title;
  final String message;
  final bool showLogout;
  final UserAuthentication? userAuthentication;

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
                  LogoutButton(
                    authService: userAuthentication,
                    navigateAfterSignOut: false,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthorizedSession extends StatefulWidget {
  const _AuthorizedSession({
    super.key,
    required this.profile,
    this.siteRepository,
    this.authentication,
  });
  final UserModel profile;
  final SiteRepository? siteRepository;
  final UserAuthentication? authentication;
  @override
  State<_AuthorizedSession> createState() => _AuthorizedSessionState();
}

class _AuthorizedSessionState extends State<_AuthorizedSession> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  @override
  Widget build(BuildContext context) => NavigatorPopHandler<void>(
    onPopWithResult: (_) => _navigatorKey.currentState!.pop(),
    child: Navigator(
      key: _navigatorKey,
      onGenerateRoute: (_) => MaterialPageRoute<void>(
        builder: (_) => SiteSelectionScreen(
          profile: widget.profile,
          repository: widget.siteRepository,
          authService: widget.authentication,
        ),
      ),
    ),
  );
}
