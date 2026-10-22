import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/attendance/screens/attendance_tracker_screen.dart';
import 'package:brixel/shared/widgets/brixel_primary_button.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:brixel/shared/widgets/brixel_section_title.dart';
import 'package:flutter/material.dart';

class AttendanceFormScreen extends StatefulWidget {
  const AttendanceFormScreen({super.key, this.siteName, this.onSubmit});

  final String? siteName;
  final Future<void> Function(Map<String, dynamic> data)? onSubmit;

  @override
  State<AttendanceFormScreen> createState() => _AttendanceFormScreenState();
}

class _AttendanceFormScreenState extends State<AttendanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workerController = TextEditingController();
  final _tradeController = TextEditingController();
  final _hoursController = TextEditingController();

  String _selectedStatus = 'Present';
  bool _isLoading = false;

  @override
  void dispose() {
    _workerController.dispose();
    _tradeController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final hoursWorked = double.parse(_hoursController.text.trim());
      final payload = {
        'workerName': _workerController.text.trim(),
        'trade': _tradeController.text.trim(),
        'status': _selectedStatus,
        'hoursWorked': hoursWorked,
      };

      if (widget.onSubmit != null) {
        await widget.onSubmit!(payload);
      }

      if (!mounted) return;

      final workerName = payload['workerName'] as String;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Attendance recorded locally for $workerName'),
          backgroundColor: BrixelColors.success,
        ),
      );

      debugPrint('Attendance form submitted: $payload');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to record attendance. Please try again.'),
            backgroundColor: BrixelColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
            key: const Key('openTrackerButton'),
            icon: const Icon(Icons.people_alt_outlined),
            tooltip: 'Crew Roster Tracker',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      AttendanceTrackerScreen(siteName: widget.siteName),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.siteName != null) ...[
                Text(
                  widget.siteName!,
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
              ],
              BrixelSectionTitle(
                title: 'Attendance Report',
                subtitle: widget.siteName == null
                    ? 'Record today\'s crew attendance for this site.'
                    : 'Attendance reporting for ${widget.siteName!}.',
              ),
              const SizedBox(height: 18),
              BrixelSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _workerController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Worker / Crew Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a worker or crew name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tradeController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Trade',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the trade.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Attendance Status',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['Present', 'Absent']
                          .map(
                            (status) => DropdownMenuItem(
                              value: status,
                              child: Text(status),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedStatus = value;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an attendance status.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _hoursController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submitForm(),
                      decoration: const InputDecoration(
                        labelText: 'Hours Worked',
                        border: OutlineInputBorder(),
                        hintText: '8.0',
                      ),
                      validator: (value) {
                        final raw = value?.trim() ?? '';
                        if (raw.isEmpty) {
                          return 'Please enter hours worked.';
                        }

                        final hours = double.tryParse(raw);
                        if (hours == null) {
                          return 'Please enter a valid number.';
                        }
                        if (hours <= 0 || hours > 24) {
                          return 'Hours worked must be greater than 0 and at most 24.';
                        }

                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              BrixelPrimaryButton(
                key: const Key('submitAttendanceButton'),
                label: 'Submit Attendance',
                isLoading: _isLoading,
                onPressed: _isLoading ? null : _submitForm,
              ),
              if (_isLoading) ...[
                const SizedBox(height: 12),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
