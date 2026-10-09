import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/shared/widgets/brixel_primary_button.dart';
import 'package:brixel/shared/widgets/brixel_worker_card.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const AttendancePreviewApp());
}

class AttendancePreviewApp extends StatelessWidget {
  const AttendancePreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brixel Attendance',
      theme: buildBrixelTheme(),
      home: const AttendancePreviewScreen(),
    );
  }
}

class AttendancePreviewScreen extends StatelessWidget {
  const AttendancePreviewScreen({super.key});

  static const List<Map<String, String>> workers = [
    {
      'name': 'Ramesh Kumar',
      'role': 'Mason',
      'workerId': 'W-001',
      'status': 'Present',
    },
    {
      'name': 'Suresh Yadav',
      'role': 'Helper',
      'workerId': 'W-002',
      'status': 'Present',
    },
    {
      'name': 'Imran Shaikh',
      'role': 'Electrician',
      'workerId': 'W-003',
      'status': 'Present',
    },
    {
      'name': 'Pooja Singh',
      'role': 'Supervisor',
      'workerId': 'W-004',
      'status': 'Present',
    },
    {
      'name': 'Vikram Patel',
      'role': 'Mason',
      'workerId': 'W-005',
      'status': 'Present',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BrixelColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {},
        ),
        title: const Text('Attendance'),
        centerTitle: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date Switcher Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {},
                    visualDensity: VisualDensity.compact,
                  ),
                  const Text(
                    'Mon, 6 Oct 2026',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: BrixelColors.primaryText,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {},
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: BrixelColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BrixelColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search,
                        size: 20, color: BrixelColors.secondaryText),
                    SizedBox(width: 10),
                    Text(
                      'Search worker or ID',
                      style: TextStyle(
                        color: BrixelColors.secondaryText,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Segmented Status Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: BrixelColors.primary,
                            width: 2.5,
                          ),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'On-Site (56)',
                        style: TextStyle(
                          color: BrixelColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      child: const Text(
                        'Absent (6)',
                        style: TextStyle(
                          color: BrixelColors.secondaryText,
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Worker List Reusing BrixelWorkerCard
            Expanded(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: workers.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final worker = workers[index];
                  return BrixelWorkerCard(
                    name: worker['name']!,
                    role: worker['role']!,
                    workerId: worker['workerId']!,
                    status: worker['status']!,
                    onTap: () {},
                  );
                },
              ),
            ),

            // Bottom CTA
            Padding(
              padding: const EdgeInsets.all(20),
              child: BrixelPrimaryButton(
                label: 'Mark Attendance',
                icon: Icons.add,
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}
