import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/auth/screens/auth_state_gate.dart';
import 'package:brixel/features/auth/screens/sign_up_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:brixel/features/splash/screens/splash_screen.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(const MyApp());
  } catch (_) {
    runApp(
      MaterialApp(
        theme: buildBrixelTheme(),
        home: _StartupFailure(onRetry: main),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.home, this.authStateGateBuilder});

  final Widget? home;
  final WidgetBuilder? authStateGateBuilder;

  Widget _buildAuthStateGate(BuildContext context) {
    return authStateGateBuilder?.call(context) ?? const AuthStateGate();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brixel',
      theme: buildBrixelTheme(),
      debugShowCheckedModeBanner: false,
      home: home ?? SplashScreen(destinationBuilder: _buildAuthStateGate),
      routes: {
        '/login': _buildAuthStateGate,
        '/signup': (context) => const SignUpScreen(),
        '/sites': _buildAuthStateGate,
      },
    );
  }
}

class _StartupFailure extends StatefulWidget {
  const _StartupFailure({required this.onRetry});
  final Future<void> Function() onRetry;
  @override
  State<_StartupFailure> createState() => _StartupFailureState();
}

class _StartupFailureState extends State<_StartupFailure> {
  bool _retrying = false;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            const Text('Brixel could not start. Please check your connection.'),
            TextButton(
              onPressed: _retrying
                  ? null
                  : () async {
                      setState(() => _retrying = true);
                      await widget.onRetry();
                      if (mounted) setState(() => _retrying = false);
                    },
              child: Text(_retrying ? 'Starting…' : 'Retry'),
            ),
          ],
        ),
      ),
    ),
  );
}
