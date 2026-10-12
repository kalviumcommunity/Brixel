import 'package:brixel/shared/widgets/brixel_primary_button.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:brixel/shared/widgets/brixel_section_title.dart';
import 'package:flutter/material.dart';

class AttendanceFormScreen extends StatefulWidget {
  const AttendanceFormScreen({super.key, this.siteName});

  final String? siteName;

  @override
  State<AttendanceFormScreen> createState() => _AttendanceFormScreenState();
}

class _AttendanceFormScreenState extends State<AttendanceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workerController = TextEditingController();
  final _tradeController = TextEditingController();
  final _hoursController = TextEditingController();

  String _selectedStatus = 'Present';

  @override
  void dispose() {
    _workerController.dispose();
    _tradeController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final payload = {
      'workerName': _workerController.text.trim(),
      'trade': _tradeController.text.trim(),
      'status': _selectedStatus,
      'hoursWorked': _hoursController.text.trim(),
    };

    final workerName = payload['workerName'] as String;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Attendance recorded locally for $workerName')),
    );

    debugPrint('Attendance form submitted: $payload');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance')),
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
                      decoration: const InputDecoration(
                        labelText: 'Hours Worked',
                        border: OutlineInputBorder(),
                        hintText: '8.0',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter hours worked.';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Please enter a valid number.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              BrixelPrimaryButton(
                label: 'Submit Attendance',
                onPressed: _submitForm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
