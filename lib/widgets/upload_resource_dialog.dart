import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:study_deck/core/theme/app_theme.dart';
import 'package:study_deck/models/academic_resource_model.dart';
import 'package:study_deck/models/module_model.dart';
import 'package:study_deck/models/subject_model.dart';
import 'package:study_deck/services/academic_service.dart';
import 'package:study_deck/services/cloudinary_service.dart';
import 'package:study_deck/services/pdf_picker_service.dart';

/// Modal dialog for uploading PDF documents to Cloudinary
/// and publishing resource metadata to Cloud Firestore.
class UploadResourceDialog extends StatefulWidget {
  const UploadResourceDialog({
    super.key,
    required this.academicService,
    this.cloudinaryService,
    this.pdfPickerService,
    this.initialSemesterId,
    this.initialSubjectId,
    this.initialModuleId,
    this.initialType,
    this.isLockedHierarchy,
  });

  final AcademicService academicService;
  final CloudinaryService? cloudinaryService;
  final PdfPickerService? pdfPickerService;
  final String? initialSemesterId;
  final String? initialSubjectId;
  final String? initialModuleId;
  final ResourceType? initialType;
  final bool? isLockedHierarchy;

  @override
  State<UploadResourceDialog> createState() => _UploadResourceDialogState();
}

class _UploadResourceDialogState extends State<UploadResourceDialog> {
  late final CloudinaryService _cloudinaryService;
  late final PdfPickerService _pdfPickerService;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _semIdController;
  late final TextEditingController _subIdController;
  late final TextEditingController _modIdController;
  late final TextEditingController _descController;

  late ResourceType _selectedType;
  SelectedPdfDocument? _selectedFile;

  List<SubjectModel> _availableSubjects = [];
  List<ModuleModel> _availableModules = [];
  String? _selectedSubjectId;
  String? _selectedModuleId;
  bool _isLoadingHierarchy = true;
  bool _showManualIdInputs = false;
  late final bool _isLocked;

  bool _isUploading = false;
  String? _uploadStatusMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cloudinaryService = widget.cloudinaryService ?? CloudinaryService();
    _pdfPickerService = widget.pdfPickerService ?? const PdfPickerService();

    _isLocked = widget.isLockedHierarchy ??
        (widget.initialSemesterId != null &&
            widget.initialSubjectId != null &&
            widget.initialModuleId != null);

    _selectedType = widget.initialType ?? ResourceType.notes;
    _titleController = TextEditingController();
    _semIdController = TextEditingController(text: widget.initialSemesterId ?? '');
    _subIdController = TextEditingController(text: widget.initialSubjectId ?? '');
    _modIdController = TextEditingController(text: widget.initialModuleId ?? '');
    _selectedSubjectId = widget.initialSubjectId;
    _selectedModuleId = widget.initialModuleId;
    _descController = TextEditingController();

    if (_isLocked) {
      _isLoadingHierarchy = false;
    } else {
      _loadHierarchy();
    }
  }


  Future<void> _loadHierarchy() async {
    try {
      final subs = await widget.academicService.watchAllSubjects().first;
      if (!mounted) return;
      setState(() {
        _availableSubjects = subs;
        _isLoadingHierarchy = false;

        if (subs.isNotEmpty) {
          final initialMatch = subs.firstWhere(
            (s) => s.id == widget.initialSubjectId,
            orElse: () => subs.first,
          );
          _selectSubject(initialMatch);
        }
      });
    } catch (e) {
      developer.log('Error loading subjects in UploadResourceDialog', error: e);
      if (mounted) {
        setState(() {
          _isLoadingHierarchy = false;
        });
      }
    }
  }

  void _selectSubject(SubjectModel sub) {
    _selectedSubjectId = sub.id;
    _subIdController.text = sub.id;
    _semIdController.text = sub.semesterId;
    _selectedModuleId = null;
    _modIdController.text = '';

    _loadModules(sub.id);
  }

  Future<void> _loadModules(String subjectId) async {
    try {
      final mods = await widget.academicService.watchAllModules().first;
      if (!mounted) return;
      setState(() {
        _availableModules = mods.where((m) => m.subjectId == subjectId).toList();
      });
    } catch (e) {
      developer.log('Error loading modules for subject $subjectId', error: e);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _semIdController.dispose();
    _subIdController.dispose();
    _modIdController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handlePickFile() async {
    setState(() {
      _errorMessage = null;
    });

    try {
      final picked = await _pdfPickerService.pickPdf();
      if (picked != null) {
        setState(() {
          _selectedFile = picked;
          // Auto-fill title from filename if title is currently empty
          if (_titleController.text.trim().isEmpty) {
            final baseName = picked.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), '');
            _titleController.text = baseName;
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _handleUploadAndSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFile == null) {
      setState(() {
        _errorMessage = 'Please select a PDF file (under 10 MB) to upload.';
      });
      return;
    }

    if (_subIdController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'A Course Subject must be selected before uploading.';
      });
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _uploadStatusMessage = 'Uploading PDF to Cloudinary...';
    });

    final CloudinaryUploadResult uploadResult;

    // Step 1: Upload directly to Cloudinary (unsigned preset)
    try {
      uploadResult = await _cloudinaryService.uploadPdf(
        fileBytes: _selectedFile!.bytes,
        fileName: _selectedFile!.name,
      );
    } catch (e) {
      developer.log('Cloudinary upload failure', error: e, name: 'UploadResourceDialog');
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _uploadStatusMessage = null;
        _errorMessage = 'Cloudinary Upload Failed: $e\n(No metadata was written to Firestore).';
      });
      return;
    }

    // Step 2: Save to Firestore ONLY after successful Cloudinary upload
    if (!mounted) return;
    setState(() {
      _uploadStatusMessage = 'Saving resource metadata to Firestore...';
    });

    try {
      final resourceModel = AcademicResourceModel(
        id: '',
        title: _titleController.text.trim(),
        semesterId: _semIdController.text.trim(),
        subjectId: _subIdController.text.trim(),
        moduleId: _modIdController.text.trim().isNotEmpty ? _modIdController.text.trim() : null,
        description: _descController.text.trim(),
        type: _selectedType,
        fileUrl: uploadResult.secureUrl,
        fileName: _selectedFile!.name,
        fileSize: uploadResult.bytes > 0 ? uploadResult.bytes : _selectedFile!.size,
        isPublished: true,
        createdAt: DateTime.now(),
      );

      await widget.academicService.createResource(resourceModel);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      developer.log('Firestore save failure after upload', error: e, name: 'UploadResourceDialog');
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _uploadStatusMessage = null;
        _errorMessage =
            'CRITICAL: The PDF was uploaded to Cloudinary:\n${uploadResult.secureUrl}\n'
            'However, saving to Firestore failed: $e\n'
            'The asset exists in Cloudinary but is not linked in Firestore.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xF2101B3B) : const Color(0xF7FAF7F0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: isDark ? RoyalColors.glassGoldBorder : const Color(0x33C5A04A),
          width: 1.2,
        ),
      ),
      elevation: 20,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: RoyalGradients.metallicGold,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: RoyalColors.royalGold.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.cloud_upload_rounded,
              color: RoyalColors.midnightNavy,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Publish Study Material',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 580,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error Alert Banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF991B1B) : const Color(0xFFF87171),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SelectableText(
                            _errorMessage!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Upload Progress Banner
                if (_isUploading) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x33C5A04A) : const Color(0x1FC5A04A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? RoyalColors.glassGoldBorder : const Color(0x4DC5A04A),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: RoyalColors.royalGold,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _uploadStatusMessage ?? 'Processing...',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            color: RoyalColors.royalGold,
                            backgroundColor: isDark ? const Color(0x33101B3B) : const Color(0x33C5A04A),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // PDF File Selection Box
                InkWell(
                  onTap: _isUploading ? null : _handlePickFile,
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _selectedFile != null
                            ? const Color(0xFF10B981)
                            : (isDark ? RoyalColors.glassGoldBorder : const Color(0x4DC5A04A)),
                        width: _selectedFile != null ? 1.5 : 1,
                      ),
                      color: _selectedFile != null
                          ? (isDark ? const Color(0x2610B981) : const Color(0xFFECFDF5))
                          : (isDark ? const Color(0x33162248) : Colors.white),
                    ),
                    child: _selectedFile == null
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.attach_file_rounded,
                                color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Choose PDF Document (Max 10 MB)',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF064E3B) : const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  color: Color(0xFF10B981),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedFile!.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_selectedFile!.formattedSize} • Validated PDF',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF15803D),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: _isUploading ? null : _handlePickFile,
                                child: const Text('Change'),
                              ),
                            ],
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title Field
                TextFormField(
                  controller: _titleController,
                  enabled: !_isUploading,
                  decoration: const InputDecoration(
                    labelText: 'Resource Title *',
                    hintText: 'e.g., Module 1 Complete Lecture Notes',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title for the resource.';
                    }
                    if (value.trim().length > 200) {
                      return 'Title must be 200 characters or less.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Resource Type Dropdown
                DropdownButtonFormField<ResourceType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Resource Category *',
                    border: OutlineInputBorder(),
                  ),
                  items: ResourceType.values
                      .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName)))
                      .toList(),
                  onChanged: _isUploading
                      ? null
                      : (val) {
                          if (val != null) setState(() => _selectedType = val);
                        },
                ),
                const SizedBox(height: 12),

                // Course Subject and Module selection (Hidden when locked in-context)
                if (!_isLocked) ...[
                  if (_isLoadingHierarchy) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ] else if (_availableSubjects.isEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: Colors.amber),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No subjects exist in Firestore. Please create a subject first before uploading study materials.',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ] else ...[
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubjectId,
                      decoration: const InputDecoration(
                        labelText: 'Select Course Subject *',
                        border: OutlineInputBorder(),
                      ),
                      items: _availableSubjects
                          .map(
                            (s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(
                                '${s.name} (${s.code.isNotEmpty ? s.code : "No Code"})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: _isUploading
                          ? null
                          : (val) {
                              if (val != null) {
                                final match = _availableSubjects.firstWhere((s) => s.id == val);
                                _selectSubject(match);
                              }
                            },
                      validator: (val) => val == null || val.isEmpty ? 'Subject is required' : null,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Syllabus Module Dropdown (Optional Link)
                  if (_availableModules.isNotEmpty) ...[
                    DropdownButtonFormField<String?>(
                      initialValue: _selectedModuleId,
                      decoration: const InputDecoration(
                        labelText: 'Syllabus Module (Optional)',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('General / Entire Subject (No specific module)'),
                        ),
                        ..._availableModules.map(
                          (m) => DropdownMenuItem<String?>(
                            value: m.id,
                            child: Text('Module ${m.moduleNumber}: ${m.title}'),
                          ),
                        ),
                      ],
                      onChanged: _isUploading
                          ? null
                          : (val) {
                              setState(() {
                                _selectedModuleId = val;
                                _modIdController.text = val ?? '';
                              });
                            },
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Manual ID Override Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _showManualIdInputs = !_showManualIdInputs;
                          });
                        },
                        icon: Icon(
                          _showManualIdInputs ? Icons.expand_less : Icons.tune_rounded,
                          size: 16,
                        ),
                        label: Text(
                          _showManualIdInputs ? 'Hide Custom IDs' : 'Advanced: Verify / Edit IDs',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.deepNavy.withValues(alpha: 0.5)
                          : AppColors.champagne.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.royalGold.withValues(alpha: isDark ? 0.35 : 0.45),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded, size: 20, color: AppColors.royalGold),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Module & Subject auto-linked from current view',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.goldLight : AppColors.deepNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],


                if (_showManualIdInputs) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _subIdController,
                    enabled: !_isUploading,
                    decoration: const InputDecoration(
                      labelText: 'Linked Subject Document ID *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v == null || v.trim().isEmpty ? 'Subject ID is required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _semIdController,
                    enabled: !_isUploading,
                    decoration: const InputDecoration(
                      labelText: 'Linked Semester Document ID (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _modIdController,
                    enabled: !_isUploading,
                    decoration: const InputDecoration(
                      labelText: 'Linked Module Document ID (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Description
                TextFormField(
                  controller: _descController,
                  enabled: !_isUploading,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Resource Description (Optional)',
                    hintText: 'Brief summary of contents, lecture units, or exam year',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: isDark ? RoyalColors.textMutedDark : const Color(0xFF64748B),
            ),
          ),
        ),
        FilledButton.icon(
          onPressed: _isUploading ? null : _handleUploadAndSave,
          style: FilledButton.styleFrom(
            backgroundColor: RoyalColors.royalGold,
            foregroundColor: RoyalColors.midnightNavy,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          icon: _isUploading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: RoyalColors.midnightNavy,
                  ),
                )
              : const Icon(Icons.cloud_upload_rounded, size: 18),
          label: Text(
            _isUploading ? 'Uploading & Publishing...' : 'Upload & Publish',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
