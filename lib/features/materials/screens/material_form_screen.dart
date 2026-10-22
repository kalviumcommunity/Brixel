import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/shared/widgets/brixel_primary_button.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:brixel/shared/widgets/brixel_section_title.dart';
import 'package:flutter/material.dart';

class MaterialFormScreen extends StatefulWidget {
  const MaterialFormScreen({super.key, this.siteName, this.onSubmit});

  final String? siteName;
  final Future<void> Function(Map<String, dynamic> data)? onSubmit;

  @override
  State<MaterialFormScreen> createState() => _MaterialFormScreenState();
}

class _MaterialFormScreenState extends State<MaterialFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _materialController = TextEditingController();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedUnit = 'bags';
  bool _isLoading = false;

  @override
  void dispose() {
    _materialController.dispose();
    _quantityController.dispose();
    _notesController.dispose();
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
      final quantity = double.parse(_quantityController.text.trim());
      final payload = {
        'materialName': _materialController.text.trim(),
        'quantity': quantity,
        'unit': _selectedUnit,
        'notes': _notesController.text.trim(),
      };

      if (widget.onSubmit != null) {
        await widget.onSubmit!(payload);
      }

      if (!mounted) return;

      final materialName = payload['materialName'] as String;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Material usage recorded locally for $materialName'),
          backgroundColor: BrixelColors.success,
        ),
      );

      debugPrint('Material form submitted: $payload');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to record material usage. Please try again.'),
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
      appBar: AppBar(title: const Text('Materials')),
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
                title: 'Material Usage Report',
                subtitle: widget.siteName == null
                    ? 'Log material usage for the active site.'
                    : 'Material usage reporting for ${widget.siteName!}.',
              ),
              const SizedBox(height: 18),
              BrixelSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _materialController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Material Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the material name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _quantityController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final raw = value?.trim() ?? '';
                        if (raw.isEmpty) {
                          return 'Please enter the quantity.';
                        }

                        final quantity = double.tryParse(raw);
                        if (quantity == null) {
                          return 'Please enter a valid number.';
                        }
                        if (quantity <= 0) {
                          return 'Quantity must be greater than zero.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['bags', 'kg', 'tons', 'pieces']
                          .map(
                            (unit) => DropdownMenuItem(
                              value: unit,
                              child: Text(unit),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedUnit = value;
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please choose a unit.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 3,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Notes (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              BrixelPrimaryButton(
                key: const Key('submitMaterialButton'),
                label: 'Submit Material Usage',
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
