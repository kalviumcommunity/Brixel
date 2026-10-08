import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/shared/widgets/brixel_metric_card.dart';
import 'package:brixel/shared/widgets/brixel_primary_button.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:brixel/shared/widgets/brixel_section_title.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const BrixelWidgetPreviewApp());
}

class BrixelWidgetPreviewApp extends StatelessWidget {
  const BrixelWidgetPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brixel Reusable Widgets',
      theme: buildBrixelTheme(),
      home: Scaffold(
        backgroundColor: BrixelColors.background,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const BrixelSectionTitle(
                      title: 'Dashboard',
                      subtitle: 'Site overview',
                    ),
                    const SizedBox(height: 18),
                    const BrixelMetricCard(
                      title: 'Attendance',
                      value: '56 / 62',
                      subtitle: 'present today',
                      icon: Icons.people_outline,
                    ),
                    const SizedBox(height: 16),
                    const BrixelMetricCard(
                      title: 'Materials',
                      value: '12',
                      subtitle: 'low stock',
                      icon: Icons.inventory_2_outlined,
                    ),
                    const SizedBox(height: 16),
                    const BrixelMetricCard(
                      title: 'Safety',
                      value: '2',
                      subtitle: 'open incidents',
                      icon: Icons.warning_amber_rounded,
                    ),
                    const SizedBox(height: 16),
                    const BrixelMetricCard(
                      title: 'Reports',
                      value: '8',
                      subtitle: 'this week',
                      icon: Icons.description_outlined,
                    ),
                    const SizedBox(height: 20),
                    BrixelSectionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const BrixelSectionTitle(
                            title: 'Actions',
                            subtitle: 'Quick tasks',
                          ),
                          const SizedBox(height: 16),
                          BrixelPrimaryButton(
                            label: 'Mark Attendance',
                            icon: Icons.add,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
