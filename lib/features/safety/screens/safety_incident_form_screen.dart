import 'dart:typed_data';

import 'package:brixel/core/theme/brixel_theme.dart';
import 'package:brixel/features/auth/services/firebase_auth_service.dart';
import 'package:brixel/features/safety/models/incident_model.dart';
import 'package:brixel/features/safety/repositories/firestore_safety_incident_write_repository.dart';
import 'package:brixel/features/safety/repositories/safety_incident_write_repository.dart';
import 'package:brixel/features/safety/storage/firebase_safety_evidence_storage.dart';
import 'package:brixel/features/safety/storage/safety_evidence_storage.dart';
import 'package:brixel/shared/widgets/brixel_primary_button.dart';
import 'package:brixel/shared/widgets/brixel_section_card.dart';
import 'package:brixel/shared/widgets/brixel_section_title.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SafetyIncidentFormScreen extends StatefulWidget {
  const SafetyIncidentFormScreen({
    super.key,
    required this.siteId,
    this.siteName,
    this.reportedBy,
    this.repository,
    this.evidenceStorage,
    this.pickImage,
  });

  final String siteId;
  final String? siteName;
  final String? reportedBy;
  final SafetyIncidentWriteRepository? repository;
  final SafetyEvidenceStorage? evidenceStorage;
  final Future<XFile?> Function()? pickImage;

  @override
  State<SafetyIncidentFormScreen> createState() =>
      _SafetyIncidentFormScreenState();
}

class _SafetyIncidentFormScreenState extends State<SafetyIncidentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();

  late final SafetyIncidentWriteRepository _repository =
      widget.repository ?? FirestoreSafetyIncidentWriteRepository();
  late final SafetyEvidenceStorage _evidenceStorage =
      widget.evidenceStorage ?? FirebaseSafetyEvidenceStorage();

  String _selectedIncidentType = 'Fall';
  String _selectedSeverity = 'Medium';
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<XFile?> _pickFromGallery() {
    return ImagePicker().pickImage(source: ImageSource.gallery);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: BrixelColors.danger),
    );
  }

  Future<void> _selectImage() async {
    try {
      final image = await (widget.pickImage ?? _pickFromGallery)();
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    } catch (_) {
      if (mounted) {
        _showError('Could not select that image. Please try again.');
      }
    }
  }

  String _contentTypeFor(XFile image) {
    final mimeType = image.mimeType?.trim();
    if (mimeType != null &&
        mimeType.startsWith('image/') &&
        mimeType.isNotEmpty) {
      return mimeType;
    }

    switch (image.name.split('.').last.toLowerCase()) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      default:
        return 'image/jpeg';
    }
  }

  String _fileNameFor(XFile image) {
    if (image.name.trim().isNotEmpty) return image.name;

    switch (image.mimeType?.toLowerCase()) {
      case 'image/png':
        return 'evidence.png';
      case 'image/webp':
        return 'evidence.webp';
      case 'image/gif':
        return 'evidence.gif';
      case 'image/heic':
        return 'evidence.heic';
      case 'image/heif':
        return 'evidence.heif';
      default:
        return 'evidence.jpg';
    }
  }

  String _incidentTypeValue(String type) {
    switch (type) {
      case 'Fall':
        return 'fall';
      case 'Equipment':
        return 'equipment_failure';
      case 'Injury':
        return 'injury';
      default:
        return 'hazard';
    }
  }

  Future<void> _submitForm() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) {
      return;
    }

    final reportedBy =
        widget.reportedBy ?? FirebaseAuthService().currentUser?.uid ?? '';
    if (reportedBy.trim().isEmpty) {
      _showError('Could not verify your account. Please sign in again.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final incidentId = _repository.createIncidentId();
      String? photoUrl;

      if (_selectedImage != null && _selectedImageBytes != null) {
        photoUrl = await _evidenceStorage.uploadEvidence(
          siteId: widget.siteId,
          incidentId: incidentId,
          fileName: _fileNameFor(_selectedImage!),
          bytes: _selectedImageBytes!,
          contentType: _contentTypeFor(_selectedImage!),
        );
      }

      final incident = IncidentModel(
        id: incidentId,
        siteId: widget.siteId,
        incidentType: _incidentTypeValue(_selectedIncidentType),
        severity: _selectedSeverity.toLowerCase(),
        description:
            '${_locationController.text.trim()}: '
            '${_descriptionController.text.trim()}',
        photoUrl: photoUrl,
        status: 'reported',
        reportedBy: reportedBy.trim(),
        createdAt: DateTime.now(),
      );

      await _repository.addIncident(
        activeSiteId: widget.siteId,
        incident: incident,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Safety incident reported for ${_locationController.text.trim()}',
          ),
          backgroundColor: BrixelColors.success,
        ),
      );
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        _showError('Could not submit incident. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety')),
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
                title: 'Safety Incident Report',
                subtitle: widget.siteName == null
                    ? 'Record a site issue or hazard before it becomes worse.'
                    : 'Safety reporting for ${widget.siteName!}.',
              ),
              const SizedBox(height: 18),
              BrixelSectionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _locationController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Location / Site Area',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter the location or site area.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedIncidentType,
                      decoration: const InputDecoration(
                        labelText: 'Incident Type',
                        border: OutlineInputBorder(),
                      ),
                      items:
                          const [
                                'Fall',
                                'Equipment',
                                'Electrical',
                                'Fire',
                                'Injury',
                                'Other',
                              ]
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ),
                              )
                              .toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedIncidentType = value;
                                });
                              }
                            },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select an incident type.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSeverity,
                      decoration: const InputDecoration(
                        labelText: 'Severity',
                        border: OutlineInputBorder(),
                      ),
                      items: const ['Low', 'Medium', 'High']
                          .map(
                            (severity) => DropdownMenuItem(
                              value: severity,
                              child: Text(severity),
                            ),
                          )
                          .toList(),
                      onChanged: _isSubmitting
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() {
                                  _selectedSeverity = value;
                                });
                              }
                            },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a severity.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      keyboardType: TextInputType.multiline,
                      textInputAction: TextInputAction.newline,
                      minLines: 4,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        final description = value?.trim() ?? '';
                        if (description.isEmpty) {
                          return 'Please describe the incident.';
                        }
                        if (description.length < 5) {
                          return 'Description must be at least 5 characters.';
                        }

                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Incident Photo / Evidence',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    if (_selectedImageBytes != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _selectedImageBytes!,
                          key: const Key('selectedEvidencePreview'),
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: _isSubmitting ? null : _selectImage,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Change image'),
                          ),
                          TextButton.icon(
                            key: const Key('removeEvidenceButton'),
                            onPressed: _isSubmitting
                                ? null
                                : () => setState(() {
                                    _selectedImage = null;
                                    _selectedImageBytes = null;
                                  }),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove'),
                          ),
                        ],
                      ),
                    ] else
                      OutlinedButton.icon(
                        key: const Key('selectEvidenceButton'),
                        onPressed: _isSubmitting ? null : _selectImage,
                        icon: const Icon(Icons.add_a_photo_outlined),
                        label: const Text('Select image'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              BrixelPrimaryButton(
                key: const Key('submitIncidentButton'),
                label: _isSubmitting ? 'Submitting...' : 'Submit Incident',
                onPressed: _isSubmitting ? null : _submitForm,
              ),
              if (_isSubmitting) ...[
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
