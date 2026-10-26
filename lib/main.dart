import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/attendance/screens/attendance_tracker_screen.dart';
import 'package:brixel/features/auth/screens/auth_state_gate.dart';
import 'package:brixel/features/auth/screens/sign_up_screen.dart';
import 'package:brixel/features/materials/screens/material_delivery_list_screen.dart';
import 'package:brixel/features/safety/screens/safety_incident_list_screen.dart';
import 'package:brixel/features/sites/models/site.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:brixel/features/splash/screens/splash_screen.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
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
      home: home ?? const SplashScreen(),
      routes: {
        '/login': _buildAuthStateGate,
        '/signup': (context) => const SignUpScreen(),
        '/sites': _buildAuthStateGate,
        '/attendance-tracker': (context) => const AttendanceTrackerScreen(),
        '/material-deliveries': (context) => const MaterialDeliveryListScreen(),
        '/safety-incidents': (context) => const SafetyIncidentListScreen(
          site: Site(
            id: 'site_metro_line1',
            name: 'Metro Line 1 - Station Pier 4',
            location: 'Madhapur, Hyderabad',
          ),
        ),
      },
    );
  }
}
