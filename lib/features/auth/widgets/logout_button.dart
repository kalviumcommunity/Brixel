import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/auth/screens/login_screen.dart';
import 'package:brixel/features/auth/services/firebase_auth_service.dart';
import 'package:brixel/features/auth/services/user_authentication.dart';
import 'package:flutter/material.dart';

class LogoutButton extends StatefulWidget {
  const LogoutButton({
    super.key,
    this.authService,
    this.destinationBuilder,
    this.navigateAfterSignOut = false,
  });

  final UserAuthentication? authService;
  final WidgetBuilder? destinationBuilder;
  final bool navigateAfterSignOut;

  @override
  State<LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<LogoutButton> {
  bool _isSigningOut = false;

  UserAuthentication get _authService =>
      widget.authService ?? FirebaseAuthService();

  Future<void> _signOut() async {
    setState(() {
      _isSigningOut = true;
    });

    try {
      await _authService.signOut();

      if (!mounted) return;

      if (!widget.navigateAfterSignOut) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      final destination =
          widget.destinationBuilder?.call(context) ?? const LoginScreen();

      Navigator.of(context).pushAndRemoveUntil<void>(
        MaterialPageRoute<void>(builder: (_) => destination),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not log out. Please try again.'),
          backgroundColor: BrixelColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: const Key('logoutButton'),
      onPressed: _isSigningOut ? null : _signOut,
      icon: const Icon(Icons.logout),
      label: Text(_isSigningOut ? 'Logging out...' : 'Log out'),
    );
  }
}
