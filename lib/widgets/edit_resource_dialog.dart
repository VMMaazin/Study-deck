import 'package:flutter/material.dart';
import 'package:study_deck/core/theme/app_theme.dart';
import 'package:study_deck/models/academic_resource_model.dart';
import 'package:study_deck/services/academic_service.dart';

/// Modal dialog for editing or renaming an academic resource item.
class EditResourceDialog extends StatefulWidget {
  const EditResourceDialog({
    super.key,
    required this.resource,
    required this.academicService,
  });

  final AcademicResourceModel resource;
  final AcademicService academicService;

  static Future<bool?> show(
    BuildContext context, {
    required AcademicResourceModel resource,
    required AcademicService academicService,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EditResourceDialog(
        resource: resource,
        academicService: academicService,
      ),
    );
  }

  @override
  State<EditResourceDialog> createState() => _EditResourceDialogState();
}

class _EditResourceDialogState extends State<EditResourceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descController;
  late ResourceType _type;
  late bool _isPublished;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.resource.title);
    _descController = TextEditingController(text: widget.resource.description);
    _type = widget.resource.type;
    _isPublished = widget.resource.isPublished;
  }

  @override
  void dispose() {
    _titleController.dispose();
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
      final updated = widget.resource.copyWith(
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        type: _type,
        isPublished: _isPublished,
      );

      await widget.academicService.updateResource(updated);

      if (!mounted) return;
      Navigator.of(context).pop(true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resource "${updated.title}" updated.'),
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
        _errorMessage = 'Failed to update resource: $e';
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
                          Icons.drive_file_rename_outline_rounded,
                          color: RoyalColors.midnightNavy,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Edit / Rename Resource',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 17,
                                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                              ),
                            ),
                            Text(
                              widget.resource.fileName.isNotEmpty ? widget.resource.fileName : 'PDF Material',
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? RoyalColors.champagne.withValues(alpha: 0.8) : const Color(0xFF64748B),
                              ),
                              overflow: TextOverflow.ellipsis,
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

                  // Title
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Resource Title *',
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
                      if (v == null || v.trim().isEmpty) return 'Please enter a resource title.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),

                  // Resource Type
                  DropdownButtonFormField<ResourceType>(
                    initialValue: _type,
                    decoration: InputDecoration(
                      labelText: 'Resource Category',
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
                    items: ResourceType.values.map((t) {
                      return DropdownMenuItem(
                        value: t,
                        child: Text(t.displayName),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _type = val);
                    },
                  ),
                  const SizedBox(height: 14),

                  // Description
                  TextFormField(
                    controller: _descController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Description (Optional)',
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

                  // Published status
                  SwitchListTile(
                    title: const Text('Published to Students', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    value: _isPublished,
                    activeThumbColor: RoyalColors.royalGold,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _isPublished = val),
                  ),
                  const SizedBox(height: 20),

                  // Actions
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
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: RoyalColors.royalGold,
                          foregroundColor: RoyalColors.midnightNavy,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isLoading ? null : _handleSave,
                        child: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: RoyalColors.midnightNavy),
                              )
                            : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700)),
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
