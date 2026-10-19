import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:study_deck/core/session/admin_session.dart';
import 'package:study_deck/core/theme/animated_glass_background.dart';
import 'package:study_deck/core/theme/royal_design_system.dart';
import 'package:study_deck/models/semester_model.dart';
import 'package:study_deck/models/subject_model.dart';
import 'package:study_deck/screens/deck/module_list_screen.dart';
import 'package:study_deck/services/academic_service.dart';
import 'package:study_deck/widgets/edit_subject_dialog.dart';
import 'package:study_deck/widgets/empty_state_view.dart';
import 'package:study_deck/widgets/responsive_layout.dart';
import 'package:study_deck/widgets/study_deck_app_bar.dart';

/// Screen displaying subjects offered under a selected academic semester.
/// Designed with the royal navy, antique gold, and warm ivory aesthetic.
/// Provides public open access for students and in-place editing for authenticated admins.
class SubjectListScreen extends StatefulWidget {
  const SubjectListScreen({
    super.key,
    required this.semester,
    this.academicService,
  });

  final SemesterModel semester;
  final AcademicService? academicService;

  @override
  State<SubjectListScreen> createState() => _SubjectListScreenState();
}

class _SubjectListScreenState extends State<SubjectListScreen> {
  late final AcademicService _academicService;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  bool _isSearchFocused = false;

  @override
  void initState() {
    super.initState();
    _academicService = widget.academicService ?? AcademicService();
    _searchFocusNode.addListener(() {
      if (mounted) {
        setState(() => _isSearchFocused = _searchFocusNode.hasFocus);
      }
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _handleEditSubject(SubjectModel subject) async {
    final updated = await EditSubjectDialog.show(
      context,
      subject: subject,
      academicService: _academicService,
    );
    if (updated == true && mounted) {
      setState(() {});
    }
  }

  Future<void> _handleCreateSubject() async {
    final newSubject = SubjectModel(
      id: '',
      semesterId: widget.semester.id,
      name: '',
      code: '',
      description: '',
      isPublished: true,
      order: 0,
    );
    final created = await EditSubjectDialog.show(
      context,
      subject: newSubject,
      academicService: _academicService,
    );
    if (created == true && mounted) {
      setState(() {});
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
        title: widget.semester.title,
        subtitle: 'Select a course subject',
        showBackButton: true,
      ),
      body: PremiumAnimatedGlassBackground(
        isDark: isDark,
        child: SafeArea(
          child: ResponsiveContainer(
            maxWidth: 1080,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Breadcrumb and Academic Header
                  SubtleEntranceAnimation(
                    delayMs: 40,
                    child: _buildHeaderSection(isDark),
                  ),
                  const SizedBox(height: 16),

                  // 2. Liquid Glass Search Bar & Admin Controls
                  SubtleEntranceAnimation(
                    delayMs: 100,
                    child: _buildSearchAndActionBar(isDark, session),
                  ),
                  const SizedBox(height: 20),

                  // 3. Subjects Stream & Dynamic Grid/List Layout
                  Expanded(
                    child: StreamBuilder<List<SubjectModel>>(
                      stream: _academicService.watchPublishedSubjects(
                        widget.semester.id,
                        semester: widget.semester,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return _buildErrorState(snapshot.error.toString(), isDark);
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return _buildLoadingState(isDark);
                        }

                        final allSubjects = snapshot.data ?? [];
                        final subjects = allSubjects.where((s) {
                          if (_searchQuery.isEmpty) return true;
                          return s.name.toLowerCase().contains(_searchQuery) ||
                              s.code.toLowerCase().contains(_searchQuery) ||
                              s.description.toLowerCase().contains(_searchQuery);
                        }).toList();

                        if (allSubjects.isEmpty) {
                          return EmptyStateView(
                            icon: Icons.menu_book_rounded,
                            title: 'No Subjects Published',
                            message:
                                'Course subjects for this semester have not been published yet. Faculty administrators are organizing the curriculum.',
                            actionLabel: session.isAdmin ? 'Create Subject' : null,
                            onActionPressed: session.isAdmin ? _handleCreateSubject : null,
                          );
                        }

                        if (subjects.isEmpty) {
                          return EmptyStateView(
                            icon: Icons.search_off_rounded,
                            title: 'No Matching Courses',
                            message:
                                'No subjects matched "$_searchQuery". Try searching by course code or full title.',
                            actionLabel: 'Clear Search',
                            onActionPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          );
                        }

                        return LayoutBuilder(
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
                                itemCount: subjects.length,
                                itemBuilder: (context, index) {
                                  final subject = subjects[index];
                                  return SubtleEntranceAnimation(
                                    delayMs: 120 + (index % 6) * 40,
                                    child: RoyalSubjectCard(
                                      subject: subject,
                                      semester: widget.semester,
                                      isDark: isDark,
                                      isAdmin: session.isAdmin,
                                      onTap: () => _navigateToSubject(subject),
                                      onEdit: () => _handleEditSubject(subject),
                                    ),
                                  );
                                },
                              );
                            }

                            return ListView.separated(
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.only(bottom: 24),
                              itemCount: subjects.length,
                              separatorBuilder: (context, index) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final subject = subjects[index];
                                return SubtleEntranceAnimation(
                                  delayMs: 120 + (index % 6) * 40,
                                  child: RoyalSubjectCard(
                                    subject: subject,
                                    semester: widget.semester,
                                    isDark: isDark,
                                    isAdmin: session.isAdmin,
                                    onTap: () => _navigateToSubject(subject),
                                    onEdit: () => _handleEditSubject(subject),
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToSubject(SubjectModel subject) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ModuleListScreen(
          semester: widget.semester,
          subject: subject,
          academicService: _academicService,
        ),
      ),
    );
  }

  /// Refined academic context header with royal gold accents
  Widget _buildHeaderSection(bool isDark) {
    return Column(
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
              'Academic Curriculum',
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
            Text(
              widget.semester.title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xFFE5CCA0) : const Color(0xFF8A6715),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Section Title & Gold Indicator Bar
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
              'Course Subjects',
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
          'Select a subject to access curated syllabus modules, notes, and question banks.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF8A99AD) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  /// Search bar with frosted glass styling and contextual admin "Add Subject" button
  Widget _buildSearchAndActionBar(bool isDark, AdminSession session) {
    final active = _isSearchFocused || _searchQuery.isNotEmpty;

    final bgColor = isDark
        ? (active ? const Color(0xE60D152A) : const Color(0xCC0B1120))
        : (active ? const Color(0xF2FFFFFF) : const Color(0xD9FFFFFF));

    final borderColor = active
        ? (isDark ? const Color(0xFFC5A04A) : const Color(0xFFC5A04A))
        : (isDark ? const Color(0x33C5A04A) : const Color(0x40C5A04A));

    final textColor = isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy;
    final hintColor = isDark ? const Color(0xFF6B7A90) : const Color(0xFF7A8A9E);
    final iconColor = active
        ? const Color(0xFFD4AF37)
        : (isDark ? const Color(0xFF8A99AD) : const Color(0xFF7A8A9E));

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 820),
        child: Row(
          children: [
            // Liquid Glass Search Input
            Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: bgColor,
                  border: Border.all(
                    color: borderColor,
                    width: active ? 1.4 : 1.0,
                  ),
                  boxShadow: [
                    if (active)
                      BoxShadow(
                        color: const Color(0xFFC5A04A).withValues(alpha: isDark ? 0.25 : 0.18),
                        blurRadius: 18,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      )
                    else if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 2.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search_rounded,
                            color: iconColor,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              focusNode: _searchFocusNode,
                              controller: _searchController,
                              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                              style: TextStyle(
                                color: textColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              cursorColor: const Color(0xFFD4AF37),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Search course by name or subject code (e.g. CS201)...',
                                hintStyle: TextStyle(
                                  color: hintColor,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          if (_searchQuery.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              color: hintColor,
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Admin Add Subject Button
            if (session.isAdmin) ...[
              const SizedBox(width: 12),
              RoyalLiquidGlassButton(
                label: 'Add Subject',
                icon: Icons.add_rounded,
                isGold: true,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                borderRadius: 14,
                onPressed: _handleCreateSubject,
              ),
            ],
          ],
        ),
      ),
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
            'Loading course subjects...',
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
              'Unable to Load Subjects',
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

/// A liquid-glass Subject Card with royal borders, hover highlights,
/// subject code pills, and integrated admin editing controls.
class RoyalSubjectCard extends StatefulWidget {
  const RoyalSubjectCard({
    super.key,
    required this.subject,
    required this.semester,
    required this.isDark,
    required this.isAdmin,
    required this.onTap,
    required this.onEdit,
  });

  final SubjectModel subject;
  final SemesterModel semester;
  final bool isDark;
  final bool isAdmin;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  @override
  State<RoyalSubjectCard> createState() => _RoyalSubjectCardState();
}

class _RoyalSubjectCardState extends State<RoyalSubjectCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

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
                        // Left: Royal Book Emblem
                        Container(
                          width: 46,
                          height: 46,
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
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 22,
                            color: _isHovered
                                ? (isDark
                                    ? const Color(0xFF38BDF8)
                                    : RoyalColors.royalGold)
                                : (isDark
                                    ? const Color(0xFF60A5FA)
                                    : const Color(0xFF8A6715)),
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Center: Subject Code Pill, Name, and Description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  if (widget.subject.code.isNotEmpty) ...[
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
                                        widget.subject.code,
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
                                    const SizedBox(width: 8),
                                  ],
                                  if (!widget.subject.isPublished) ...[
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
                                        'Draft / Unpublished',
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
                                widget.subject.name,
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
                              if (widget.subject.description.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  widget.subject.description,
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

                        // Right: Admin Edit Option + Chevron indicator
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.isAdmin) ...[
                              IconButton(
                                icon: const Icon(Icons.edit_note_rounded, size: 22),
                                tooltip: 'Edit Subject',
                                color: isDark
                                    ? const Color(0xFFE5CCA0)
                                    : const Color(0xFF8A6715),
                                onPressed: widget.onEdit,
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
