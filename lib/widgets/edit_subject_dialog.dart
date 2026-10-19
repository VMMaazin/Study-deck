import 'package:flutter/material.dart';
import 'package:study_deck/core/theme/app_theme.dart';
import 'package:study_deck/models/subject_model.dart';
import 'package:study_deck/services/academic_service.dart';

/// Modal dialog allowing administrators to edit an existing subject in place,
/// preserving its Firestore document ID, semesterId, and resource relationships.
class EditSubjectDialog extends StatefulWidget {
  const EditSubjectDialog({
    super.key,
    required this.subject,
    required this.academicService,
  });

  final SubjectModel subject;
  final AcademicService academicService;

  static Future<bool?> show(
    BuildContext context, {
    required SubjectModel subject,
    required AcademicService academicService,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditSubjectDialog(
        subject: subject,
        academicService: academicService,
      ),
    );
  }

  @override
  State<EditSubjectDialog> createState() => _EditSubjectDialogState();
}

class _EditSubjectDialogState extends State<EditSubjectDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _descController;
  late bool _isPublished;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.subject.name);
    _codeController = TextEditingController(text: widget.subject.code);
    _descController = TextEditingController(text: widget.subject.description);
    _isPublished = widget.subject.isPublished;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final updated = widget.subject.copyWith(
        name: _nameController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        description: _descController.text.trim(),
        isPublished: _isPublished,
      );

      final isEditing = widget.subject.id.trim().isNotEmpty;
      if (isEditing) {
        // Saves changes in place in Firestore, preserving document ID & semesterId
        await widget.academicService.updateSubject(updated);
      } else {
        await widget.academicService.createSubject(updated);
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Subject "${updated.name}" updated successfully.'
                : 'Subject "${updated.name}" created successfully.',
          ),
          backgroundColor: AppColors.midnightNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.5)),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Failed to save subject: $e';

        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: isDark ? RoyalColors.glassGoldBorder : const Color(0x33C5A04A),
          width: 1.2,
        ),
      ),
      backgroundColor: isDark ? const Color(0xF2101B3B) : const Color(0xF7FAF7F0),
      elevation: 20,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title row
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
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
                          Icons.edit_note_rounded,
                          color: RoyalColors.midnightNavy,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.subject.id.trim().isNotEmpty ? 'Edit Subject' : 'Add Course Subject',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                              ),
                            ),
                            Text(
                              widget.subject.id.trim().isNotEmpty
                                  ? 'Preserves document ID and all connected modules & notes'
                                  : 'Linked to current academic semester',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? RoyalColors.champagne.withValues(alpha: 0.8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: isDark ? RoyalColors.textMutedDark : const Color(0xFF64748B),
                        ),
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Color(0xFFDC2626),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Subject Name
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Subject Name *',
                      hintText: 'e.g. Data Structures and Algorithms',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? RoyalColors.royalGold : const Color(0xFF8A6715),
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter a subject name.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Subject Code
                  TextFormField(
                    controller: _codeController,
                    decoration: InputDecoration(
                      labelText: 'Subject Code *',
                      hintText: 'e.g. CS201',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? RoyalColors.royalGold : const Color(0xFF8A6715),
                          width: 1.5,
                        ),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Please enter a subject code.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Description
                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'Course overview, objectives, and prerequisites...',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                          color: isDark ? RoyalColors.royalGold : const Color(0xFF8A6715),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Published status switch
                  SwitchListTile(
                    title: const Text('Published to Students', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    subtitle: Text(
                      _isPublished ? 'Visible to students and public viewers' : 'Hidden from public student catalog',
                      style: const TextStyle(fontSize: 11),
                    ),
                    value: _isPublished,
                    activeThumbColor: RoyalColors.royalGold,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _isPublished = val),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark ? RoyalColors.textMutedDark : const Color(0xFF64748B),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      FilledButton.icon(
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: RoyalColors.midnightNavy),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          widget.subject.id.trim().isNotEmpty ? 'Save Changes' : 'Create Subject',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: RoyalColors.royalGold,
                          foregroundColor: RoyalColors.midnightNavy,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isLoading ? null : _handleSave,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
