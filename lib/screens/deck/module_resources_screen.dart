import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:study_deck/core/session/admin_session.dart';
import 'package:study_deck/core/theme/animated_glass_background.dart';
import 'package:study_deck/core/theme/royal_design_system.dart';
import 'package:study_deck/models/academic_resource_model.dart';
import 'package:study_deck/models/module_model.dart';
import 'package:study_deck/models/semester_model.dart';
import 'package:study_deck/models/subject_model.dart';
import 'package:study_deck/screens/viewer/pdf_viewer_screen.dart';
import 'package:study_deck/services/academic_service.dart';
import 'package:study_deck/widgets/download_choice_dialog.dart';
import 'package:study_deck/widgets/edit_resource_dialog.dart';
import 'package:study_deck/widgets/empty_state_view.dart';
import 'package:study_deck/widgets/responsive_layout.dart';
import 'package:study_deck/widgets/study_deck_app_bar.dart';
import 'package:study_deck/widgets/upload_resource_dialog.dart';

/// Screen displaying the three core resource categories for a specific module:
/// Tab 1: Notes (ResourceType.notes)
/// Tab 2: Question Bank (ResourceType.pyq)
/// Tab 3: Extra Resources (ResourceType.assignment, syllabus, other)
/// Styled in StudyDeck's royal navy, antique gold, and warm ivory visual identity.
class ModuleResourcesScreen extends StatefulWidget {
  const ModuleResourcesScreen({
    super.key,
    required this.semester,
    required this.subject,
    required this.module,
    this.academicService,
    this.initialTabIndex = 0,
  });

  final SemesterModel semester;
  final SubjectModel subject;
  final ModuleModel module;
  final AcademicService? academicService;
  final int initialTabIndex;

  @override
  State<ModuleResourcesScreen> createState() => _ModuleResourcesScreenState();
}

class _ModuleResourcesScreenState extends State<ModuleResourcesScreen>
    with SingleTickerProviderStateMixin {
  late final AcademicService _academicService;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _academicService = widget.academicService ?? AcademicService();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _viewPdf(AcademicResourceModel item) {
    final url = item.fileUrl?.trim() ?? '';
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('File link is unavailable for this resource.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          title: item.title,
          fileUrl: url,
          fileName: item.fileName,
          documentId: item.id,
        ),
      ),
    );
  }

  void _openDownloadChoice(AcademicResourceModel item) {
    DownloadChoiceDialog.show(
      context,
      resource: item,
      semester: widget.semester,
      subject: widget.subject,
      module: widget.module,
    );
  }

  Future<void> _openUploadDialog(ResourceType defaultType) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => UploadResourceDialog(
        academicService: _academicService,
        initialSemesterId: widget.semester.id,
        initialSubjectId: widget.subject.id,
        initialModuleId: widget.module.id,
        initialType: defaultType,
        isLockedHierarchy: true,
      ),
    );

    if (result == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _deleteResource(AcademicResourceModel resource) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Resource?'),
        content: Text(
          'Are you sure you want to delete "${resource.title}"? This cannot be undone.',
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
        await _academicService.deleteResource(resource.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Deleted "${resource.title}".'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete resource: $e'),
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

    final moduleLabel = 'Module ${widget.module.moduleNumber}: ${widget.module.title}';
    final primaryGold = isDark ? const Color(0xFFD4AF37) : const Color(0xFF8A6715);
    final unselectedColor = isDark ? const Color(0xFF8A99AD) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: StudyDeckAppBar(
        title: moduleLabel,
        subtitle: '${widget.subject.name} • ${widget.semester.title}',
        showBackButton: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark ? const Color(0x33C5A04A) : const Color(0x33C5A04A),
                  width: 1.0,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: primaryGold,
              unselectedLabelColor: unselectedColor,
              indicatorColor: primaryGold,
              indicatorWeight: 3.0,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: const [
                Tab(
                  icon: Icon(Icons.menu_book_rounded, size: 17),
                  text: 'Notes',
                ),
                Tab(
                  icon: Icon(Icons.quiz_rounded, size: 17),
                  text: 'Question Bank',
                ),
                Tab(
                  icon: Icon(Icons.folder_shared_rounded, size: 17),
                  text: 'Extra Resources',
                ),
              ],
            ),
          ),
        ),
      ),
      body: PremiumAnimatedGlassBackground(
        isDark: isDark,
        child: SafeArea(
          child: StreamBuilder<List<AcademicResourceModel>>(
            stream: _academicService.watchPublishedResources(
              subjectId: widget.subject.id,
              subject: widget.subject,
              moduleId: widget.module.id,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString(), isDark);
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState(isDark);
              }

              final allResources = snapshot.data ?? [];

              // Filter resources belonging to this subject and module
              final moduleResources = allResources.where((r) {
                final matchesSubject = r.subjectId == widget.subject.id ||
                    r.subjectId == widget.subject.name ||
                    r.subjectId == widget.subject.code;
                final matchesModule = r.moduleId == null ||
                    r.moduleId!.isEmpty ||
                    r.moduleId == widget.module.id ||
                    r.moduleId == '${widget.module.moduleNumber}';
                return matchesSubject && matchesModule;
              }).toList();

              final notesResources = moduleResources.where((r) => r.type == ResourceType.notes).toList();
              final pyqResources = moduleResources.where((r) => r.type == ResourceType.pyq).toList();
              final extraResources = moduleResources.where((r) {
                return r.type == ResourceType.assignment ||
                    r.type == ResourceType.syllabus ||
                    r.type == ResourceType.other;
              }).toList();

              return TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Notes
                  _buildResourceListTab(
                    resources: notesResources,
                    tabType: ResourceType.notes,
                    tabName: 'Lecture Notes',
                    emptyTitle: 'No Notes Uploaded',
                    emptySubtitle: 'No lecture notes are published for this module yet.',
                    theme: theme,
                    isDark: isDark,
                    session: session,
                  ),

                  // Tab 2: Question Bank
                  _buildResourceListTab(
                    resources: pyqResources,
                    tabType: ResourceType.pyq,
                    tabName: 'Question Bank',
                    emptyTitle: 'No Question Bank Available',
                    emptySubtitle:
                        'Previous year question papers and question banks will appear here once released.',
                    theme: theme,
                    isDark: isDark,
                    session: session,
                  ),

                  // Tab 3: Extra Resources
                  _buildResourceListTab(
                    resources: extraResources,
                    tabType: ResourceType.assignment,
                    tabName: 'Extra Resources',
                    emptyTitle: 'No Extra Resources',
                    emptySubtitle:
                        'Assignments, syllabus documents, and references for this module will appear here.',
                    theme: theme,
                    isDark: isDark,
                    session: session,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildResourceListTab({
    required List<AcademicResourceModel> resources,
    required ResourceType tabType,
    required String tabName,
    required String emptyTitle,
    required String emptySubtitle,
    required ThemeData theme,
    required bool isDark,
    required AdminSession session,
  }) {
    return ResponsiveContainer(
      maxWidth: 1080,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header action bar with Upload button if Admin is logged in
            SubtleEntranceAnimation(
              delayMs: 40,
              child: _buildTabHeaderBar(tabName, tabType, isDark, session),
            ),
            const SizedBox(height: 16),

            // Resource cards list / grid
            Expanded(
              child: resources.isEmpty
                  ? Center(
                      child: EmptyStateView(
                        icon: Icons.folder_open_rounded,
                        title: emptyTitle,
                        message: emptySubtitle,
                        actionLabel: session.isAdmin ? 'Upload Document' : null,
                        onActionPressed: session.isAdmin ? () => _openUploadDialog(tabType) : null,
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 750;

                        if (isWide) {
                          return GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            padding: const EdgeInsets.only(bottom: 24),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 2.2,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                            ),
                            itemCount: resources.length,
                            itemBuilder: (context, index) {
                              final item = resources[index];
                              return SubtleEntranceAnimation(
                                delayMs: 80 + (index % 6) * 35,
                                child: RoyalResourceCard(
                                  item: item,
                                  isDark: isDark,
                                  isAdmin: session.isAdmin,
                                  onViewPdf: () => _viewPdf(item),
                                  onDownload: () => _openDownloadChoice(item),
                                  onEdit: () async {
                                    final updated = await EditResourceDialog.show(
                                      context,
                                      resource: item,
                                      academicService: _academicService,
                                    );
                                    if (updated == true && mounted) {
                                      setState(() {});
                                    }
                                  },
                                  onDelete: () => _deleteResource(item),
                                ),
                              );
                            },
                          );
                        }

                        return ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: resources.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = resources[index];
                            return SubtleEntranceAnimation(
                              delayMs: 80 + (index % 6) * 35,
                              child: RoyalResourceCard(
                                item: item,
                                isDark: isDark,
                                isAdmin: session.isAdmin,
                                onViewPdf: () => _viewPdf(item),
                                onDownload: () => _openDownloadChoice(item),
                                onEdit: () async {
                                  final updated = await EditResourceDialog.show(
                                    context,
                                    resource: item,
                                    academicService: _academicService,
                                  );
                                  if (updated == true && mounted) {
                                    setState(() {});
                                  }
                                },
                                onDelete: () => _deleteResource(item),
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
  }

  /// Refined category header with breadcrumbs and Admin upload action
  Widget _buildTabHeaderBar(
    String tabName,
    ResourceType tabType,
    bool isDark,
    AdminSession session,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Category title with gold indicator
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                gradient: RoyalGradients.metallicGold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              tabName,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                letterSpacing: -0.3,
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              ),
            ),
          ],
        ),

        // Admin Upload Button
        if (session.isAdmin)
          RoyalLiquidGlassButton(
            label: 'Upload $tabName',
            icon: Icons.cloud_upload_rounded,
            isGold: true,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            borderRadius: 12,
            onPressed: () => _openUploadDialog(tabType),
          ),
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
            'Loading academic resources...',
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
              'Unable to Load Resources',
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

/// A liquid-glass Resource Card with royal borders, metadata hierarchy,
/// distinct View PDF and Download actions, and contextual admin controls.
class RoyalResourceCard extends StatefulWidget {
  const RoyalResourceCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.isAdmin,
    required this.onViewPdf,
    required this.onDownload,
    required this.onEdit,
    required this.onDelete,
  });

  final AcademicResourceModel item;
  final bool isDark;
  final bool isAdmin;
  final VoidCallback onViewPdf;
  final VoidCallback onDownload;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<RoyalResourceCard> createState() => _RoyalResourceCardState();
}

class _RoyalResourceCardState extends State<RoyalResourceCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final item = widget.item;

    final cardBg = isDark
        ? const Color(0xE60B1224) // Frosted dark obsidian navy
        : const Color(0xF2FFFFFF); // Frosted pearl ivory

    final borderColor = _isHovered
        ? (isDark ? const Color(0xFF38BDF8) : RoyalColors.royalGold)
        : (isDark ? const Color(0x33C5A04A) : const Color(0x40C5A04A));

    return MouseRegion(
      cursor: SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.015 : 1.0,
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
              child: Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Top Info Row: PDF Emblem + Metadata
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // PDF Document Icon Badge
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0x26EF4444)
                                : const Color(0x1FEF4444),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                              width: 1.0,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Color(0xFFEF4444),
                              size: 22,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Title, Type Pill & Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Resource Type Pill
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
                                      item.type.displayName,
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.3,
                                        color: isDark
                                            ? const Color(0xFFE5CCA0)
                                            : const Color(0xFF8A6715),
                                      ),
                                    ),
                                  ),
                                  if (!item.isPublished) ...[
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
                                        'Draft / Hidden',
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
                                item.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  letterSpacing: -0.3,
                                  color: isDark
                                      ? RoyalColors.pearlWhite
                                      : RoyalColors.midnightNavy,
                                ),
                              ),
                              if (item.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  item.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 12,
                                    height: 1.4,
                                    color: isDark
                                        ? const Color(0xFF8A99AD)
                                        : const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                '${item.fileName.isNotEmpty ? item.fileName : "Verified Academic Document"}${item.fileSize != null ? " • ${(item.fileSize! / 1024 / 1024).toStringAsFixed(2)} MB" : ""}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? const Color(0xFF6B7A90)
                                      : const Color(0xFF94A3B8),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    Divider(
                      height: 1,
                      color: isDark ? const Color(0x1AFFFFFF) : const Color(0x14000000),
                    ),
                    const SizedBox(height: 10),

                    // Bottom Action Row: View PDF, Download, and Admin Controls
                    Row(
                      children: [
                        // View PDF button (OutlinedButton for test assertion matching)
                        OutlinedButton.icon(
                          icon: const Icon(Icons.visibility_rounded, size: 16),
                          label: const Text(
                            'View PDF',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark
                                ? const Color(0xFF38BDF8)
                                : const Color(0xFF0284C7),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0x6638BDF8)
                                  : const Color(0x660284C7),
                              width: 1.2,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: widget.onViewPdf,
                        ),
                        const SizedBox(width: 8),

                        // Download PDF button (Tonal button with text "Download")
                        FilledButton.tonalIcon(
                          icon: const Icon(Icons.download_rounded, size: 16),
                          label: const Text(
                            'Download',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                          style: FilledButton.styleFrom(
                            foregroundColor: isDark
                                ? RoyalColors.pearlWhite
                                : RoyalColors.midnightNavy,
                            backgroundColor: isDark
                                ? const Color(0x33C5A04A)
                                : const Color(0x26C5A04A),
                            side: BorderSide(
                              color: isDark
                                  ? const Color(0x4DC5A04A)
                                  : const Color(0x40C5A04A),
                              width: 1.0,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: widget.onDownload,
                        ),

                        const Spacer(),

                        // Admin Controls: Edit/Rename and Delete
                        if (widget.isAdmin) ...[
                          IconButton(
                            icon: const Icon(Icons.drive_file_rename_outline_rounded, size: 18),
                            tooltip: 'Edit / Rename',
                            color: isDark
                                ? const Color(0xFFE5CCA0)
                                : const Color(0xFF8A6715),
                            visualDensity: VisualDensity.compact,
                            onPressed: widget.onEdit,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(0xFFDC2626)),
                            tooltip: 'Delete Resource',
                            visualDensity: VisualDensity.compact,
                            onPressed: widget.onDelete,
                          ),
                        ],
                      ],
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
