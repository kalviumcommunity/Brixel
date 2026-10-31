import 'package:brixel/features/reporting/repositories/site_report_repository.dart';
import 'package:brixel/features/auth/models/user_model.dart';
import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/attendance/screens/attendance_form_screen.dart';
import 'package:brixel/features/auth/services/user_authentication.dart';
import 'package:brixel/features/auth/widgets/logout_button.dart';
import 'package:brixel/features/materials/screens/material_form_screen.dart';
import 'package:brixel/features/safety/screens/safety_incident_form_screen.dart';
import 'package:brixel/features/sites/models/site.dart';
import 'package:brixel/features/sites/screens/site_dashboard_screen.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:flutter/material.dart';

class AppNavigationShell extends StatefulWidget {
  const AppNavigationShell({
    super.key,
    required this.site,
    this.initialIndex = 0,
    this.authService,
    this.profile,
  });

  final Site site;
  final UserModel? profile;
  final int initialIndex;
  final UserAuthentication? authService;

  @override
  State<AppNavigationShell> createState() => _AppNavigationShellState();
}

class _AppNavigationShellState extends State<AppNavigationShell> {
  late int _selectedIndex;

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _buildScreens();
  }

  @override
  void didUpdateWidget(covariant AppNavigationShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.site != widget.site) {
      _buildScreens();
    }
  }

  void _buildScreens() {
    _screens = [
      SiteDashboardScreen(
        site: widget.site,
        displayName: widget.profile?.displayName,
        reports: widget.profile == null ? null : SiteReportRepository(),
      ),
      AttendanceFormScreen(siteName: widget.site.name, siteId: widget.site.id),
      MaterialFormScreen(siteName: widget.site.name, siteId: widget.site.id),
      SafetyIncidentFormScreen(
        popOnSuccess: false,
        siteId: widget.site.id,
        siteName: widget.site.name,
      ),
      _ProfileScreen(
        title: 'Profile',
        description: widget.profile == null
            ? 'Site reporting'
            : '${widget.profile!.displayName} • ${widget.profile!.role}',
        icon: Icons.person_outline,
        site: widget.site,
        authService: widget.authService,
      ),
    ];
  }

  void _selectDestination(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        key: ValueKey(widget.site.id),
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _selectDestination,
        type: BottomNavigationBarType.fixed,
        backgroundColor: BrixelColors.surface,
        selectedItemColor: BrixelColors.primary,
        unselectedItemColor: BrixelColors.secondaryText,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.badge_outlined),
            activeIcon: Icon(Icons.badge),
            label: 'Attendance',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Materials',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.warning_amber_outlined),
            activeIcon: Icon(Icons.warning_amber),
            label: 'Safety',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            activeIcon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
      ),
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen({
    required this.title,
    required this.description,
    required this.icon,
    required this.site,
    this.authService,
  });

  final String title;
  final String description;
  final IconData icon;
  final Site site;
  final UserAuthentication? authService;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BrixelSectionCard(
              child: Column(
                children: [
                  Icon(
                    icon,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    site.name,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(site.location, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  Text(description, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  LogoutButton(
                    authService: authService,
                    navigateAfterSignOut: false,
                    confirmBeforeSignOut: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
