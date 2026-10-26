import 'dart:async';

import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/auth/screens/auth_state_gate.dart';
import 'package:flutter/material.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.displayDuration = const Duration(milliseconds: 1500),
    this.destinationBuilder,
  });

  final Duration displayDuration;
  final WidgetBuilder? destinationBuilder;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer = Timer(widget.displayDuration, _continueToApp);
  }

  void _continueToApp() {
    if (!mounted) {
      return;
    }

    final destination =
        widget.destinationBuilder?.call(context) ?? const AuthStateGate();

    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: BrixelColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: BrixelColors.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    key: Key('splashLogo'),
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Brixel',
                  key: const Key('splashTitle'),
                  style: textTheme.headlineSmall?.copyWith(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: BrixelColors.primaryText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Construction site reporting, kept current.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium?.copyWith(
                    color: BrixelColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 32),
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    key: Key('splashProgress'),
                    strokeWidth: 2.5,
                    color: BrixelColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
