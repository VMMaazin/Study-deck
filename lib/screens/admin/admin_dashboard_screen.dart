import 'dart:developer' as developer;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:study_deck/core/theme/app_theme.dart';
import 'package:study_deck/core/theme/theme_controller.dart';
import 'package:study_deck/models/academic_resource_model.dart';
import 'package:study_deck/models/admin_user_model.dart';
import 'package:study_deck/models/module_model.dart';
import 'package:study_deck/models/semester_model.dart';
import 'package:study_deck/models/subject_model.dart';
import 'package:study_deck/services/academic_service.dart';
import 'package:study_deck/services/auth_service.dart';
import 'package:study_deck/widgets/edit_module_dialog.dart';
import 'package:study_deck/widgets/empty_state_view.dart';
import 'package:study_deck/widgets/responsive_layout.dart';
import 'package:study_deck/widgets/upload_resource_dialog.dart';
import 'package:url_launcher/url_launcher.dart';

/// Responsive administrative dashboard for managing academic hierarchy and published content.
/// Styled with the royal midnight navy, antique gold, champagne, and frosted glass identity.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.adminUser,
    this.authService,
    this.academicService,
  });

  final AdminUserModel adminUser;
  final AuthService? authService;
  final AcademicService? academicService;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final AuthService _authService;
  late final AcademicService _academicService;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _academicService = widget.academicService ?? AcademicService();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleSignOut() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: isDark
              ? AppColors.midnightNavy.withValues(alpha: 0.95)
              : AppColors.pearlWhite.withValues(alpha: 0.98),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: AppColors.royalGold.withValues(alpha: isDark ? 0.35 : 0.45),
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.royalGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.logout_rounded, color: AppColors.royalGold, size: 20),
              ),
              const SizedBox(width: 12),
              const Text('Sign Out'),
            ],
          ),
          content: Text(
            'Are you sure you want to end your administrative session?\n\nLogged in as: ${widget.adminUser.email}',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.champagne : AppColors.deepNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.goldLight, AppColors.royalGold],
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalGold.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => Navigator.of(ctx).pop(true),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    child: Text(
                      'Sign Out',
                      style: TextStyle(
                        color: AppColors.midnightNavy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirm == true && mounted) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeCtrl = ThemeScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.midnightNavy.withValues(alpha: 0.8)
                    : AppColors.warmIvory,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.royalGold.withValues(alpha: isDark ? 0.4 : 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.royalGold.withValues(alpha: 0.15),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.admin_panel_settings_rounded,
                    size: 16,
                    color: AppColors.royalGold,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'ADMIN CONSOLE',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.royalGold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.goldLight : AppColors.royalGold,
              size: 20,
            ),
            onPressed: () => themeCtrl.toggleTheme(),
          ),
          IconButton(
            tooltip: 'Sign Out (${widget.adminUser.email})',
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: _handleSignOut,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: isDark ? AppColors.goldLight : AppColors.royalGold,
          unselectedLabelColor: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
          indicatorColor: AppColors.royalGold,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [
            Tab(icon: Icon(Icons.calendar_month_rounded, size: 18), text: 'Semesters'),
            Tab(icon: Icon(Icons.school_rounded, size: 18), text: 'Subjects'),
            Tab(icon: Icon(Icons.view_module_rounded, size: 18), text: 'Modules'),
            Tab(icon: Icon(Icons.library_books_rounded, size: 18), text: 'Study Materials'),
          ],
        ),
      ),
      body: PremiumAnimatedGlassBackground(
        isDark: isDark,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildSemestersTab(isDark, theme),
            _buildSubjectsTab(isDark, theme),
            _buildModulesTab(isDark, theme),
            _buildResourcesTab(isDark, theme),
          ],
        ),
      ),
    );
  }

  // ----------------------------------------------------
  // Tab 1: Semesters
  // ----------------------------------------------------
  Widget _buildSemestersTab(bool isDark, ThemeData theme) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _royalFab(
        icon: Icons.add_rounded,
        label: 'Add Semester',
        onPressed: _showAddSemesterDialog,
      ),
      body: StreamBuilder<List<SemesterModel>>(
        stream: _academicService.watchAllSemesters(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading semesters: ${snapshot.error}'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.royalGold));
          }
          final semesters = snapshot.data ?? [];
          if (semesters.isEmpty) {
            return EmptyStateView(
              icon: Icons.calendar_today_rounded,
              title: 'No Semesters Configured',
              message: 'Use "Add Semester" to create and publish semesters for students.',
              actionLabel: 'Create Semester 1',
              onActionPressed: _showAddSemesterDialog,
            );
          }
          return ResponsiveContainer(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: semesters.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final s = semesters[index];
                return Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.midnightNavy.withValues(alpha: 0.85)
                        : AppColors.pearlWhite.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.royalGold.withValues(alpha: isDark ? 0.25 : 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : AppColors.deepNavy.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.royalGold.withValues(alpha: 0.5),
                        ),
                      ),
                      child: CircleAvatar(
                        backgroundColor: AppColors.royalGold.withValues(alpha: isDark ? 0.2 : 0.12),
                        child: Text(
                          '${s.semesterNumber}',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: isDark ? AppColors.goldLight : AppColors.royalGold,
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      s.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.warmIvory : AppColors.deepNavy,
                      ),
                    ),
                    subtitle: Text(
                      '${s.description.isNotEmpty ? s.description : "Academic semester"} • Doc ID: ${s.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _statusChip(s.isPublished, isDark),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                          tooltip: 'Delete Semester',
                          onPressed: () => _confirmDeleteSemester(s),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------
  // Tab 2: Subjects
  // ----------------------------------------------------
  Widget _buildSubjectsTab(bool isDark, ThemeData theme) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _royalFab(
        icon: Icons.add_rounded,
        label: 'Add Subject',
        onPressed: _showAddSubjectDialog,
      ),
      body: StreamBuilder<List<SubjectModel>>(
        stream: _academicService.watchAllSubjects(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading subjects: ${snapshot.error}'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.royalGold));
          }
          final subjects = snapshot.data ?? [];
          if (subjects.isEmpty) {
            return EmptyStateView(
              icon: Icons.book_rounded,
              title: 'No Subjects Added',
              message: 'Add academic courses and subjects linked to semesters.',
              actionLabel: 'Create First Subject',
              onActionPressed: _showAddSubjectDialog,
            );
          }
          return ResponsiveContainer(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: subjects.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final sub = subjects[index];
                return Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.midnightNavy.withValues(alpha: 0.85)
                        : AppColors.pearlWhite.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.royalGold.withValues(alpha: isDark ? 0.25 : 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : AppColors.deepNavy.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.royalGold.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.royalGold.withValues(alpha: 0.5),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.school_rounded, color: AppColors.royalGold, size: 22),
                    ),
                    title: Text(
                      sub.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.warmIvory : AppColors.deepNavy,
                      ),
                    ),
                    subtitle: Text(
                      'Code: ${sub.code.isNotEmpty ? sub.code : "N/A"} • Linked Semester: ${sub.semesterId} • ID: ${sub.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _statusChip(sub.isPublished, isDark),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.royalGold),
                          tooltip: 'Edit / Link Semester',
                          onPressed: () => _showEditSubjectDialog(sub),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                          tooltip: 'Delete Subject',
                          onPressed: () => _confirmDeleteSubject(sub),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------
  // Tab 3: Modules
  // ----------------------------------------------------
  Widget _buildModulesTab(bool isDark, ThemeData theme) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _royalFab(
        icon: Icons.add_rounded,
        label: 'Add Module',
        onPressed: _showAddModuleDialog,
      ),
      body: StreamBuilder<List<ModuleModel>>(
        stream: _academicService.watchAllModules(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading modules: ${snapshot.error}'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.royalGold));
          }
          final modules = snapshot.data ?? [];
          if (modules.isEmpty) {
            return EmptyStateView(
              icon: Icons.view_module_rounded,
              title: 'No Modules Added',
              message: 'Add syllabus modules to structure lecture notes and study material.',
              actionLabel: 'Create Module',
              onActionPressed: _showAddModuleDialog,
            );
          }
          return ResponsiveContainer(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: modules.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final m = modules[index];
                return Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.midnightNavy.withValues(alpha: 0.85)
                        : AppColors.pearlWhite.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.royalGold.withValues(alpha: isDark ? 0.25 : 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : AppColors.deepNavy.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.royalGold.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.royalGold.withValues(alpha: 0.5),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'M${m.moduleNumber}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.goldLight : AppColors.royalGold,
                        ),
                      ),
                    ),
                    title: Text(
                      m.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.warmIvory : AppColors.deepNavy,
                      ),
                    ),
                    subtitle: Text(
                      'Linked Subject: ${m.subjectId} • ID: ${m.id}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _statusChip(m.isPublished, isDark),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.royalGold),
                          tooltip: 'Edit Module',
                          onPressed: () => _showEditModuleDialog(m),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                          tooltip: 'Delete Module',
                          onPressed: () => _confirmDeleteModule(m),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------
  // Tab 4: Study Materials
  // ----------------------------------------------------
  Widget _buildResourcesTab(bool isDark, ThemeData theme) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: _royalFab(
        icon: Icons.upload_file_rounded,
        label: 'Add Resource Entry',
        onPressed: _showAddResourceDialog,
      ),
      body: StreamBuilder<List<AcademicResourceModel>>(
        stream: _academicService.watchAllResources(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text('Error loading study materials: ${snapshot.error}'),
              ),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.royalGold));
          }
          final resources = snapshot.data ?? [];
          if (resources.isEmpty) {
            return EmptyStateView(
              icon: Icons.library_books_rounded,
              title: 'No Materials Published',
              message: 'Published notes, past papers, and assignments will be catalogued here.',
              actionLabel: 'Add First Resource Entry',
              onActionPressed: _showAddResourceDialog,
            );
          }
          return ResponsiveContainer(
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: resources.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final r = resources[index];
                return Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.midnightNavy.withValues(alpha: 0.85)
                        : AppColors.pearlWhite.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.royalGold.withValues(alpha: isDark ? 0.25 : 0.35),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.35)
                            : AppColors.deepNavy.withValues(alpha: 0.05),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.royalGold.withValues(alpha: isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.royalGold.withValues(alpha: 0.5),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.royalGold, size: 22),
                    ),
                    title: Text(
                      r.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.warmIvory : AppColors.deepNavy,
                      ),
                    ),
                    subtitle: Text(
                      '${r.type.displayName} • ${r.fileName.isNotEmpty ? r.fileName : "Pending Upload"} • Subject: ${r.subjectId}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _statusChip(r.isPublished, isDark),
                        if (r.fileUrl != null && r.fileUrl!.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.open_in_new_rounded, size: 20, color: AppColors.royalGold),
                            tooltip: 'Open PDF URL',
                            onPressed: () => launchUrl(Uri.parse(r.fileUrl!), mode: LaunchMode.externalApplication),
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.royalGold),
                          tooltip: 'Edit / Re-link Subject',
                          onPressed: () => _showEditResourceDialog(r),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
                          tooltip: 'Delete Resource Record',
                          onPressed: () => _confirmDeleteResource(r),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _royalFab({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.goldLight, AppColors.royalGold],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.royalGold.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: AppColors.midnightNavy, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.midnightNavy,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusChip(bool isPublished, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPublished
            ? (isDark ? const Color(0xFF064E3B).withValues(alpha: 0.6) : const Color(0xFFD1FAE5))
            : (isDark ? const Color(0xFF451A03).withValues(alpha: 0.6) : const Color(0xFFFEF3C7)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isPublished
              ? const Color(0xFF10B981).withValues(alpha: 0.5)
              : const Color(0xFFF59E0B).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPublished ? Icons.check_circle_rounded : Icons.pending_rounded,
            size: 11,
            color: isPublished
                ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                : (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309)),
          ),
          const SizedBox(width: 4),
          Text(
            isPublished ? 'Published' : 'Draft',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isPublished
                  ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                  : (isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309)),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // Dialog: Add Semester
  // ----------------------------------------------------
  Future<void> _showAddSemesterDialog() async {
    final numController = TextEditingController(text: '1');
    final titleController = TextEditingController(text: 'Semester 1');
    final descController = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    await showDialog(
      context: context,
      builder: (ctx) {
        String? dialogError;
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: AlertDialog(
                backgroundColor: isDark
                    ? AppColors.midnightNavy.withValues(alpha: 0.95)
                    : AppColors.pearlWhite.withValues(alpha: 0.98),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: AppColors.royalGold.withValues(alpha: isDark ? 0.35 : 0.45),
                  ),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.royalGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.calendar_month_rounded, color: AppColors.royalGold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Add Academic Semester'),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dialogError != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                          ),
                          child: Text(dialogError!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12.5)),
                        ),
                      TextField(
                        controller: numController,
                        keyboardType: TextInputType.number,
                        enabled: !isSaving,
                        decoration: _inputDecoration('Semester Number (1-12)', isDark),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: titleController,
                        enabled: !isSaving,
                        decoration: _inputDecoration('Title (e.g. Semester 1)', isDark),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descController,
                        enabled: !isSaving,
                        decoration: _inputDecoration('Description (Optional)', isDark),
                      ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? AppColors.champagne : AppColors.deepNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.royalGold,
                      foregroundColor: AppColors.midnightNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final numVal = int.tryParse(numController.text.trim()) ?? 1;
                            final titleVal = titleController.text.trim().isNotEmpty
                                ? titleController.text.trim()
                                : 'Semester $numVal';

                            if (numVal < 1 || numVal > 12) {
                              setDialogState(() => dialogError = 'Semester number must be between 1 and 12.');
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                              dialogError = null;
                            });

                            try {
                              await _academicService.createSemester(
                                SemesterModel(
                                  id: '',
                                  semesterNumber: numVal,
                                  title: titleVal,
                                  description: descController.text.trim(),
                                  isPublished: true,
                                  order: numVal,
                                ),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  _royalSnackBar('Semester created and published successfully!'),
                                );
                              }
                            } catch (e) {
                              developer.log('Error creating semester', error: e);
                              setDialogState(() {
                                isSaving = false;
                                dialogError = 'Failed to create semester: $e';
                              });
                            }
                          },
                    child: Text(
                      isSaving ? 'Saving...' : 'Save & Publish',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------
  // Dialog: Add Subject
  // ----------------------------------------------------
  Future<void> _showAddSubjectDialog() async {
    List<SemesterModel> semesters = [];
    try {
      semesters = await _academicService.watchAllSemesters().first;
    } catch (e) {
      developer.log('Error fetching semesters for subject creation', error: e);
    }

    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (semesters.isEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? AppColors.midnightNavy : AppColors.pearlWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.4)),
          ),
          title: const Text('No Semesters Found'),
          content: const Text(
            'You must create at least one Semester before adding course subjects. '
            'Please go to the Semesters tab and create a semester first.',
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.royalGold, foregroundColor: AppColors.midnightNavy),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      return;
    }

    final nameController = TextEditingController();
    final codeController = TextEditingController();
    String selectedSemesterId = semesters.first.id;

    await showDialog(
      context: context,
      builder: (ctx) {
        String? dialogError;
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: AlertDialog(
                backgroundColor: isDark
                    ? AppColors.midnightNavy.withValues(alpha: 0.95)
                    : AppColors.pearlWhite.withValues(alpha: 0.98),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: AppColors.royalGold.withValues(alpha: isDark ? 0.35 : 0.45),
                  ),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.royalGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.school_rounded, color: AppColors.royalGold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Add Course Subject'),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dialogError != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                          ),
                          child: Text(dialogError!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12.5)),
                        ),
                      TextField(
                        controller: nameController,
                        enabled: !isSaving,
                        decoration: _inputDecoration('Subject Name (e.g. Data Structures) *', isDark),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: codeController,
                        enabled: !isSaving,
                        decoration: _inputDecoration('Subject Code (e.g. CS201) *', isDark),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedSemesterId,
                        decoration: _inputDecoration('Select Parent Semester *', isDark),
                        dropdownColor: isDark ? AppColors.midnightNavy : AppColors.pearlWhite,
                        items: semesters.map((s) {
                          return DropdownMenuItem<String>(
                            value: s.id,
                            child: Text(
                              '${s.title} (Sem ${s.semesterNumber})',
                              style: TextStyle(color: isDark ? AppColors.warmIvory : AppColors.deepNavy),
                            ),
                          );
                        }).toList(),
                        onChanged: isSaving
                            ? null
                            : (val) {
                                if (val != null) {
                                  setDialogState(() => selectedSemesterId = val);
                                }
                              },
                      ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? AppColors.champagne : AppColors.deepNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.royalGold,
                      foregroundColor: AppColors.midnightNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final code = codeController.text.trim();

                            if (name.isEmpty) {
                              setDialogState(() => dialogError = 'Subject name cannot be empty.');
                              return;
                            }
                            if (code.isEmpty) {
                              setDialogState(() => dialogError = 'Subject code cannot be empty.');
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                              dialogError = null;
                            });

                            try {
                              await _academicService.createSubject(
                                SubjectModel(
                                  id: '',
                                  semesterId: selectedSemesterId,
                                  name: name,
                                  code: code,
                                  isPublished: true,
                                ),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  _royalSnackBar('Subject created and linked to semester successfully!'),
                                );
                              }
                            } catch (e) {
                              developer.log('Error creating subject', error: e);
                              setDialogState(() {
                                isSaving = false;
                                dialogError = 'Failed to create subject: $e';
                              });
                            }
                          },
                    child: Text(
                      isSaving ? 'Saving...' : 'Save Subject',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------
  // Dialog: Edit Subject / Re-link Semester
  // ----------------------------------------------------
  Future<void> _showEditSubjectDialog(SubjectModel subject) async {
    List<SemesterModel> semesters = [];
    try {
      semesters = await _academicService.watchAllSemesters().first;
    } catch (e) {
      developer.log('Error fetching semesters for subject edit', error: e);
    }

    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final nameController = TextEditingController(text: subject.name);
    final codeController = TextEditingController(text: subject.code);

    String? selectedSemesterId;
    if (semesters.any((s) => s.id == subject.semesterId)) {
      selectedSemesterId = subject.semesterId;
    } else if (semesters.any((s) => '${s.semesterNumber}' == subject.semesterId || s.title == subject.semesterId)) {
      final match = semesters.firstWhere(
        (s) => '${s.semesterNumber}' == subject.semesterId || s.title == subject.semesterId,
      );
      selectedSemesterId = match.id;
    } else if (semesters.isNotEmpty) {
      selectedSemesterId = semesters.first.id;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        String? dialogError;
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: AlertDialog(
                backgroundColor: isDark
                    ? AppColors.midnightNavy.withValues(alpha: 0.95)
                    : AppColors.pearlWhite.withValues(alpha: 0.98),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: AppColors.royalGold.withValues(alpha: isDark ? 0.35 : 0.45),
                  ),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.royalGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.edit_rounded, color: AppColors.royalGold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Edit "${subject.name}"',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dialogError != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                          ),
                          child: Text(dialogError!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12.5)),
                        ),
                      TextField(
                        controller: nameController,
                        enabled: !isSaving,
                        decoration: _inputDecoration('Subject Name *', isDark),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: codeController,
                        enabled: !isSaving,
                        decoration: _inputDecoration('Subject Code *', isDark),
                      ),
                      const SizedBox(height: 14),
                      if (semesters.isNotEmpty)
                        DropdownButtonFormField<String>(
                          initialValue: selectedSemesterId,
                          decoration: _inputDecoration('Linked Semester (Choose Parent) *', isDark),
                          dropdownColor: isDark ? AppColors.midnightNavy : AppColors.pearlWhite,
                          items: semesters.map((s) {
                            return DropdownMenuItem<String>(
                              value: s.id,
                              child: Text(
                                '${s.title} (Sem ${s.semesterNumber})',
                                style: TextStyle(color: isDark ? AppColors.warmIvory : AppColors.deepNavy),
                              ),
                            );
                          }).toList(),
                          onChanged: isSaving
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setDialogState(() => selectedSemesterId = val);
                                  }
                                },
                        ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? AppColors.champagne : AppColors.deepNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.royalGold,
                      foregroundColor: AppColors.midnightNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final name = nameController.text.trim();
                            final code = codeController.text.trim();

                            if (name.isEmpty) {
                              setDialogState(() => dialogError = 'Subject name cannot be empty.');
                              return;
                            }
                            if (code.isEmpty) {
                              setDialogState(() => dialogError = 'Subject code cannot be empty.');
                              return;
                            }
                            if (selectedSemesterId == null) {
                              setDialogState(() => dialogError = 'Please select a parent semester.');
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                              dialogError = null;
                            });

                            try {
                              await _academicService.updateSubject(
                                SubjectModel(
                                  id: subject.id,
                                  semesterId: selectedSemesterId!,
                                  name: name,
                                  code: code,
                                  description: subject.description,
                                  isPublished: subject.isPublished,
                                  order: subject.order,
                                ),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  _royalSnackBar('Subject updated and linked successfully!'),
                                );
                              }
                            } catch (e) {
                              developer.log('Error updating subject', error: e);
                              setDialogState(() {
                                isSaving = false;
                                dialogError = 'Failed to update subject: $e';
                              });
                            }
                          },
                    child: Text(
                      isSaving ? 'Updating...' : 'Save Changes',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------
  // Dialog: Add Module
  // ----------------------------------------------------
  Future<void> _showAddModuleDialog() async {
    List<SubjectModel> subjects = [];
    try {
      subjects = await _academicService.watchAllSubjects().first;
    } catch (e) {
      developer.log('Error fetching subjects for module dialog', error: e);
    }

    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (subjects.isEmpty) {
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: isDark ? AppColors.midnightNavy : AppColors.pearlWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.4)),
          ),
          title: const Text('No Subjects Found'),
          content: const Text(
            'You must create at least one Course Subject before adding syllabus modules. '
            'Please create a subject under the Subjects tab first.',
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: AppColors.royalGold, foregroundColor: AppColors.midnightNavy),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
      return;
    }

    final titleController = TextEditingController();
    final numController = TextEditingController(text: '1');
    final descController = TextEditingController();
    String selectedSubjectId = subjects.first.id;

    await showDialog(
      context: context,
      builder: (ctx) {
        String? dialogError;
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: AlertDialog(
                backgroundColor: isDark
                    ? AppColors.midnightNavy.withValues(alpha: 0.95)
                    : AppColors.pearlWhite.withValues(alpha: 0.98),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: AppColors.royalGold.withValues(alpha: isDark ? 0.35 : 0.45),
                  ),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.royalGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.view_module_rounded, color: AppColors.royalGold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    const Text('Add Syllabus Module'),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dialogError != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                          ),
                          child: Text(dialogError!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12.5)),
                        ),
                      DropdownButtonFormField<String>(
                        initialValue: selectedSubjectId,
                        decoration: _inputDecoration('Select Course Subject *', isDark),
                        dropdownColor: isDark ? AppColors.midnightNavy : AppColors.pearlWhite,
                        items: subjects.map((sub) {
                          return DropdownMenuItem<String>(
                            value: sub.id,
                            child: Text(
                              '${sub.name} (${sub.code.isNotEmpty ? sub.code : "No Code"})',
                              style: TextStyle(color: isDark ? AppColors.warmIvory : AppColors.deepNavy),
                            ),
                          );
                        }).toList(),
                        onChanged: isSaving
                            ? null
                            : (val) {
                                if (val != null) {
                                  setDialogState(() => selectedSubjectId = val);
                                }
                              },
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: numController,
                        keyboardType: TextInputType.number,
                        enabled: !isSaving,
                        decoration: _inputDecoration('Module Number (e.g. 1) *', isDark),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: titleController,
                        enabled: !isSaving,
                        decoration: _inputDecoration('Module Title *', isDark),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descController,
                        enabled: !isSaving,
                        decoration: _inputDecoration('Description / Topics (Optional)', isDark),
                      ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? AppColors.champagne : AppColors.deepNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.royalGold,
                      foregroundColor: AppColors.midnightNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            final modNum = int.tryParse(numController.text.trim()) ?? 1;

                            if (title.isEmpty) {
                              setDialogState(() => dialogError = 'Module title cannot be empty.');
                              return;
                            }
                            if (title.length > 150) {
                              setDialogState(() => dialogError = 'Module title must be 150 characters or less.');
                              return;
                            }
                            if (modNum < 1) {
                              setDialogState(() => dialogError = 'Module number must be at least 1.');
                              return;
                            }
                            if (selectedSubjectId.isEmpty) {
                              setDialogState(() => dialogError = 'Please select a course subject.');
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                              dialogError = null;
                            });

                            try {
                              await _academicService.createModule(
                                ModuleModel(
                                  id: '',
                                  subjectId: selectedSubjectId,
                                  moduleNumber: modNum,
                                  title: title,
                                  description: descController.text.trim(),
                                  isPublished: true,
                                  order: modNum,
                                ),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  _royalSnackBar('Module created and published successfully!'),
                                );
                              }
                            } catch (e) {
                              developer.log('Error creating module', error: e);
                              setDialogState(() {
                                isSaving = false;
                                dialogError = 'Failed to create module: $e';
                              });
                            }
                          },
                    child: Text(
                      isSaving ? 'Saving...' : 'Save Module',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------
  // Dialog: Edit Module
  // ----------------------------------------------------
  Future<void> _showEditModuleDialog(ModuleModel module) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => EditModuleDialog(
        subjectId: module.subjectId,
        module: module,
        academicService: _academicService,
      ),
    );

    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        _royalSnackBar('Module "${module.title}" updated successfully.'),
      );
    }
  }

  // ----------------------------------------------------
  // Dialog: Edit Resource / Re-link Subject
  // ----------------------------------------------------
  Future<void> _showEditResourceDialog(AcademicResourceModel resource) async {
    List<SubjectModel> subjects = [];
    try {
      subjects = await _academicService.watchAllSubjects().first;
    } catch (e) {
      developer.log('Error fetching subjects for resource edit', error: e);
    }

    if (!mounted) return;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleController = TextEditingController(text: resource.title);
    final descController = TextEditingController(text: resource.description);
    ResourceType selectedType = resource.type;

    String? selectedSubjectId;
    if (subjects.any((s) => s.id == resource.subjectId)) {
      selectedSubjectId = resource.subjectId;
    } else if (subjects.any((s) => s.name == resource.subjectId || s.semesterId == resource.subjectId)) {
      final match = subjects.firstWhere(
        (s) => s.name == resource.subjectId || s.semesterId == resource.subjectId,
      );
      selectedSubjectId = match.id;
    } else if (subjects.isNotEmpty) {
      selectedSubjectId = subjects.first.id;
    }

    await showDialog(
      context: context,
      builder: (ctx) {
        String? dialogError;
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: AlertDialog(
                backgroundColor: isDark
                    ? AppColors.midnightNavy.withValues(alpha: 0.95)
                    : AppColors.pearlWhite.withValues(alpha: 0.98),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                  side: BorderSide(
                    color: AppColors.royalGold.withValues(alpha: isDark ? 0.35 : 0.45),
                  ),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.royalGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.royalGold.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.edit_note_rounded, color: AppColors.royalGold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Edit "${resource.title}"',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (dialogError != null)
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.5)),
                          ),
                          child: Text(dialogError!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 12.5)),
                        ),
                      TextField(
                        controller: titleController,
                        enabled: !isSaving,
                        decoration: _inputDecoration('Resource Title *', isDark),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<ResourceType>(
                        initialValue: selectedType,
                        decoration: _inputDecoration('Category *', isDark),
                        dropdownColor: isDark ? AppColors.midnightNavy : AppColors.pearlWhite,
                        items: ResourceType.values
                            .map((t) => DropdownMenuItem(
                                  value: t,
                                  child: Text(
                                    t.displayName,
                                    style: TextStyle(color: isDark ? AppColors.warmIvory : AppColors.deepNavy),
                                  ),
                                ))
                            .toList(),
                        onChanged: isSaving
                            ? null
                            : (val) {
                                if (val != null) setDialogState(() => selectedType = val);
                              },
                      ),
                      const SizedBox(height: 14),
                      if (subjects.isNotEmpty)
                        DropdownButtonFormField<String>(
                          initialValue: selectedSubjectId,
                          decoration: _inputDecoration('Linked Course Subject *', isDark),
                          dropdownColor: isDark ? AppColors.midnightNavy : AppColors.pearlWhite,
                          items: subjects.map((sub) {
                            return DropdownMenuItem<String>(
                              value: sub.id,
                              child: Text(
                                '${sub.name} (${sub.code.isNotEmpty ? sub.code : "No Code"})',
                                style: TextStyle(color: isDark ? AppColors.warmIvory : AppColors.deepNavy),
                              ),
                            );
                          }).toList(),
                          onChanged: isSaving
                              ? null
                              : (val) {
                                  if (val != null) {
                                    setDialogState(() => selectedSubjectId = val);
                                  }
                                },
                        ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: descController,
                        enabled: !isSaving,
                        decoration: _inputDecoration('Description (Optional)', isDark),
                      ),
                    ],
                  ),
                ),
                actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                actions: [
                  TextButton(
                    onPressed: isSaving ? null : () => Navigator.pop(ctx),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? AppColors.champagne : AppColors.deepNavy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.royalGold,
                      foregroundColor: AppColors.midnightNavy,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            final title = titleController.text.trim();
                            if (title.isEmpty) {
                              setDialogState(() => dialogError = 'Title cannot be empty.');
                              return;
                            }
                            if (selectedSubjectId == null) {
                              setDialogState(() => dialogError = 'Please select a course subject.');
                              return;
                            }

                            setDialogState(() {
                              isSaving = true;
                              dialogError = null;
                            });

                            try {
                              final chosenSubject = subjects.firstWhere((s) => s.id == selectedSubjectId);
                              await _academicService.updateResource(
                                AcademicResourceModel(
                                  id: resource.id,
                                  title: title,
                                  semesterId: chosenSubject.semesterId,
                                  subjectId: chosenSubject.id,
                                  moduleId: resource.moduleId,
                                  description: descController.text.trim(),
                                  type: selectedType,
                                  fileUrl: resource.fileUrl,
                                  fileName: resource.fileName,
                                  fileSize: resource.fileSize,
                                  isPublished: resource.isPublished,
                                  createdAt: resource.createdAt,
                                ),
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  _royalSnackBar('Resource metadata updated successfully!'),
                                );
                              }
                            } catch (e) {
                              developer.log('Error updating resource', error: e);
                              setDialogState(() {
                                isSaving = false;
                                dialogError = 'Failed to update resource: $e';
                              });
                            }
                          },
                    child: Text(
                      isSaving ? 'Updating...' : 'Save Changes',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ----------------------------------------------------
  // Dialog: Add Resource Entry (Cloudinary Upload + Firestore)
  // ----------------------------------------------------
  Future<void> _showAddResourceDialog() async {
    final success = await showDialog<bool>(
      context: context,
      builder: (ctx) => UploadResourceDialog(
        academicService: _academicService,
      ),
    );

    if (!mounted) return;
    if (success == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        _royalSnackBar('Academic resource published with PDF successfully!'),
      );
    }
  }

  // ----------------------------------------------------
  // Delete Confirmations
  // ----------------------------------------------------
  Future<void> _confirmDeleteSemester(SemesterModel semester) async {
    final confirm = await _showDestructiveConfirmation(
      title: 'Delete Semester',
      message: 'Are you sure you want to permanently delete "${semester.title}" from the academic catalog?',
    );

    if (confirm == true && mounted) {
      try {
        await _academicService.deleteSemester(semester.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _royalSnackBar('Semester deleted.'),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteSubject(SubjectModel subject) async {
    final confirm = await _showDestructiveConfirmation(
      title: 'Delete Subject',
      message: 'Are you sure you want to delete "${subject.name}"? This removes the course subject from Firestore.',
    );

    if (confirm == true && mounted) {
      try {
        await _academicService.deleteSubject(subject.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _royalSnackBar('Subject deleted.'),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteModule(ModuleModel module) async {
    final confirm = await _showDestructiveConfirmation(
      title: 'Delete Module',
      message: 'Are you sure you want to delete "Module ${module.moduleNumber}: ${module.title}"?',
    );

    if (confirm == true && mounted) {
      try {
        await _academicService.deleteModule(module.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _royalSnackBar('Module deleted.'),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteResource(AcademicResourceModel resource) async {
    final confirm = await _showDestructiveConfirmation(
      title: 'Delete Resource Record',
      message: 'Are you sure you want to delete "${resource.title}" from Firestore?',
    );

    if (confirm == true && mounted) {
      try {
        await _academicService.deleteResource(resource.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            _royalSnackBar('Resource record removed from Firestore.'),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  Future<bool?> _showDestructiveConfirmation({
    required String title,
    required String message,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AlertDialog(
          backgroundColor: isDark
              ? AppColors.midnightNavy.withValues(alpha: 0.95)
              : AppColors.pearlWhite.withValues(alpha: 0.98),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: const Color(0xFFEF4444).withValues(alpha: 0.4),
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title)),
            ],
          ),
          content: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              height: 1.4,
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: isDark ? AppColors.champagne : AppColors.deepNavy,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        fontSize: 13,
      ),
      filled: true,
      fillColor: isDark
          ? AppColors.deepNavy.withValues(alpha: 0.45)
          : AppColors.champagne.withValues(alpha: 0.15),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.royalGold.withValues(alpha: isDark ? 0.3 : 0.4),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(
          color: AppColors.royalGold,
          width: 1.8,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  SnackBar _royalSnackBar(String message) {
    return SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.royalGold, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppColors.midnightNavy,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.5)),
      ),
    );
  }
}
