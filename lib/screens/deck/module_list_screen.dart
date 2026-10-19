import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:study_deck/core/session/admin_session.dart';
import 'package:study_deck/core/theme/animated_glass_background.dart';
import 'package:study_deck/core/theme/royal_design_system.dart';
import 'package:study_deck/models/module_model.dart';
import 'package:study_deck/models/semester_model.dart';
import 'package:study_deck/models/subject_model.dart';
import 'package:study_deck/screens/deck/module_resources_screen.dart';
import 'package:study_deck/services/academic_service.dart';
import 'package:study_deck/widgets/edit_module_dialog.dart';
import 'package:study_deck/widgets/empty_state_view.dart';
import 'package:study_deck/widgets/responsive_layout.dart';
import 'package:study_deck/widgets/study_deck_app_bar.dart';

/// Screen displaying syllabus modules for a chosen subject:
/// Module 1, Module 2, Module 3, etc.
/// Styled in the royal navy, antique gold, and warm ivory aesthetic.
class ModuleListScreen extends StatefulWidget {
  const ModuleListScreen({
    super.key,
    required this.semester,
    required this.subject,
    this.academicService,
  });

  final SemesterModel semester;
  final SubjectModel subject;
  final AcademicService? academicService;

  @override
  State<ModuleListScreen> createState() => _ModuleListScreenState();
}

class _ModuleListScreenState extends State<ModuleListScreen> {
  late final AcademicService _academicService;

  @override
  void initState() {
    super.initState();
    _academicService = widget.academicService ?? AcademicService();
  }

  Future<void> _createModule(int nextModuleNumber) async {
    final result = await EditModuleDialog.show(
      context,
      subjectId: widget.subject.id,
      academicService: _academicService,
      suggestedModuleNumber: nextModuleNumber,
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _editModule(ModuleModel module) async {
    final result = await EditModuleDialog.show(
      context,
      subjectId: widget.subject.id,
      module: module,
      academicService: _academicService,
    );
    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteModule(ModuleModel module) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Module?'),
        content: Text(
          'Are you sure you want to delete "${module.title}"? Resources linked to this module will remain in the subject catalog.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _academicService.deleteModule(module.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "${module.title}".'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete module: $e'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final session = AdminSessionScope.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: StudyDeckAppBar(
        title: widget.subject.name,
        subtitle: '${widget.semester.title} • ${widget.subject.code.isNotEmpty ? widget.subject.code : "Course Modules"}',
        showBackButton: true,
      ),
      body: PremiumAnimatedGlassBackground(
        isDark: isDark,
        child: SafeArea(
          child: StreamBuilder<List<ModuleModel>>(
            stream: _academicService.watchPublishedModules(
              widget.subject.id,
              subject: widget.subject,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString(), isDark);
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState(isDark);
              }

              final modules = snapshot.data ?? [];
              final nextNumber = modules.isEmpty ? 1 : (modules.last.moduleNumber + 1);

              return ResponsiveContainer(
                maxWidth: 1080,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Breadcrumb and Academic Header
                      SubtleEntranceAnimation(
                        delayMs: 40,
                        child: _buildHeaderSection(isDark, session, nextNumber),
                      ),
                      const SizedBox(height: 20),

                      // 2. Module cards stream list
                      Expanded(
                        child: modules.isEmpty
                            ? Center(
                                child: EmptyStateView(
                                  icon: Icons.layers_clear_rounded,
                                  title: 'No Modules Published Yet',
                                  message:
                                      'Syllabus units for this course are being prepared. Published modules will appear here.',
                                  actionLabel: session.isAdmin ? 'Create First Module' : null,
                                  onActionPressed: session.isAdmin ? () => _createModule(1) : null,
                                ),
                              )
                            : LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWide = constraints.maxWidth >= 720;

                                  if (isWide) {
                                    return GridView.builder(
                                      physics: const BouncingScrollPhysics(),
                                      padding: const EdgeInsets.only(bottom: 24),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        childAspectRatio: 2.35,
                                        crossAxisSpacing: 16,
                                        mainAxisSpacing: 16,
                                      ),
                                      itemCount: modules.length,
                                      itemBuilder: (context, index) {
                                        final module = modules[index];
                                        return SubtleEntranceAnimation(
                                          delayMs: 100 + (index % 6) * 40,
                                          child: RoyalModuleCard(
                                            module: module,
                                            isDark: isDark,
                                            isAdmin: session.isAdmin,
                                            onTap: () => _navigateToResources(module),
                                            onEdit: () => _editModule(module),
                                            onDelete: () => _deleteModule(module),
                                          ),
                                        );
                                      },
                                    );
                                  }

                                  return ListView.separated(
                                    physics: const BouncingScrollPhysics(),
                                    padding: const EdgeInsets.only(bottom: 24),
                                    itemCount: modules.length,
                                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final module = modules[index];
                                      return SubtleEntranceAnimation(
                                        delayMs: 100 + (index % 6) * 40,
                                        child: RoyalModuleCard(
                                          module: module,
                                          isDark: isDark,
                                          isAdmin: session.isAdmin,
                                          onTap: () => _navigateToResources(module),
                                          onEdit: () => _editModule(module),
                                          onDelete: () => _deleteModule(module),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToResources(ModuleModel module) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModuleResourcesScreen(
          semester: widget.semester,
          subject: widget.subject,
          module: module,
          academicService: _academicService,
        ),
      ),
    );
  }

  /// Refined academic context header with breadcrumb trail and admin actions
  Widget _buildHeaderSection(bool isDark, AdminSession session, int nextNumber) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Breadcrumb row
              Row(
                children: [
                  Icon(
                    Icons.school_rounded,
                    size: 15,
                    color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF8A6715),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    widget.semester.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF8A99AD) : const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF6B7A90) : const Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.subject.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? const Color(0xFFE5CCA0) : const Color(0xFF8A6715),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Headline & Gold Indicator Bar
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 22,
                    decoration: BoxDecoration(
                      gradient: RoyalGradients.metallicGold,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Course Syllabus Modules',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                      letterSpacing: -0.4,
                      color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Select a module to view notes, questions & resources',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? const Color(0xFF8A99AD) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),

        // Admin Add Module Button
        if (session.isAdmin) ...[
          const SizedBox(width: 12),
          RoyalLiquidGlassButton(
            label: 'Add Module',
            icon: Icons.add_rounded,
            isGold: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            borderRadius: 14,
            onPressed: () => _createModule(nextNumber),
          ),
        ],
      ],
    );
  }

  /// Refined Loading State with Royal Gold styling
  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: RoyalColors.royalGold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Loading syllabus modules...',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF8A99AD) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  /// Refined Error State with Antique Gold icon and Liquid Glass retry action
  Widget _buildErrorState(String error, bool isDark) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xCC0B1120) : const Color(0xCCFFFFFF),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: RoyalColors.glassGoldBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: RoyalColors.paleGold,
                border: Border.all(color: RoyalColors.royalGold),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 28,
                color: RoyalColors.antiqueGold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to Load Modules',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF8A99AD) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 18),
            RoyalLiquidGlassButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }
}

/// A liquid-glass Module Card with royal styling, module badge,
/// interactive hover lighting, and contextual admin controls.
class RoyalModuleCard extends StatefulWidget {
  const RoyalModuleCard({
    super.key,
    required this.module,
    required this.isDark,
    required this.isAdmin,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final ModuleModel module;
  final bool isDark;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<RoyalModuleCard> createState() => _RoyalModuleCardState();
}

class _RoyalModuleCardState extends State<RoyalModuleCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final module = widget.module;
    final moduleBadge = 'Module ${module.moduleNumber}';

    final cardBg = isDark
        ? const Color(0xE60B1224) // Frosted dark obsidian navy
        : const Color(0xF2FFFFFF); // Frosted pearl ivory

    final borderColor = _isHovered
        ? (isDark ? const Color(0xFF38BDF8) : RoyalColors.royalGold)
        : (isDark ? const Color(0x33C5A04A) : const Color(0x40C5A04A));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.018 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: _isHovered ? 1.5 : 1.0,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: (isDark ? const Color(0xFF38BDF8) : RoyalColors.royalGold)
                      .withValues(alpha: isDark ? 0.25 : 0.18),
                  blurRadius: 18,
                  spreadRadius: 1,
                  offset: const Offset(0, 5),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: widget.onTap,
                  splashColor: isDark
                      ? const Color(0x2638BDF8)
                      : RoyalColors.paleGold,
                  highlightColor: isDark
                      ? const Color(0x1A38BDF8)
                      : const Color(0x14C5A04A),
                  child: Padding(
                    padding: const EdgeInsets.all(18.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: Royal Module Number Emblem
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _isHovered
                                ? (isDark
                                    ? const Color(0x3338BDF8)
                                    : RoyalColors.paleGold)
                                : (isDark
                                    ? const Color(0x1F38BDF8)
                                    : const Color(0x1FC5A04A)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _isHovered
                                  ? (isDark
                                      ? const Color(0xFF38BDF8)
                                      : RoyalColors.royalGold)
                                  : (isDark
                                      ? const Color(0x3338BDF8)
                                      : const Color(0x33C5A04A)),
                              width: 1.2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'M${module.moduleNumber}',
                              style: TextStyle(
                                color: _isHovered
                                    ? (isDark
                                        ? const Color(0xFF38BDF8)
                                        : RoyalColors.royalGold)
                                    : (isDark
                                        ? const Color(0xFF60A5FA)
                                        : const Color(0xFF8A6715)),
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Center: Module Pill, Title, and Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  // Module Number Pill (e.g. "Module 1")
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? const Color(0x2EC5A04A)
                                          : const Color(0x1FC5A04A),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0x4DC5A04A)
                                            : const Color(0x40C5A04A),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: Text(
                                      moduleBadge,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                        color: isDark
                                            ? const Color(0xFFE5CCA0)
                                            : const Color(0xFF8A6715),
                                      ),
                                    ),
                                  ),
                                  if (!module.isPublished) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                          color: Colors.amber.withValues(alpha: 0.4),
                                          width: 0.8,
                                        ),
                                      ),
                                      child: const Text(
                                        'Draft',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                module.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  letterSpacing: -0.3,
                                  color: isDark
                                      ? RoyalColors.pearlWhite
                                      : RoyalColors.midnightNavy,
                                ),
                              ),
                              if (module.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  module.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    fontWeight: FontWeight.w400,
                                    color: isDark
                                        ? const Color(0xFF8A99AD)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Right: Admin Actions & Navigation Chevron
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.isAdmin) ...[
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, size: 20),
                                tooltip: 'Edit Module',
                                color: isDark
                                    ? const Color(0xFFE5CCA0)
                                    : const Color(0xFF8A6715),
                                onPressed: widget.onEdit,
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: Color(0xFFDC2626),
                                ),
                                tooltip: 'Delete Module',
                                onPressed: widget.onDelete,
                              ),
                              const SizedBox(width: 4),
                            ],
                            AnimatedPadding(
                              duration: const Duration(milliseconds: 180),
                              padding: EdgeInsets.only(left: _isHovered ? 4.0 : 0.0),
                              child: Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 14,
                                color: _isHovered
                                    ? (isDark
                                        ? const Color(0xFF38BDF8)
                                        : RoyalColors.royalGold)
                                    : (isDark
                                        ? const Color(0xFF6B7A90)
                                        : const Color(0xFF94A3B8)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
