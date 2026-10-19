import 'package:flutter/material.dart';
import 'package:study_deck/core/theme/app_theme.dart';
import 'package:study_deck/models/academic_resource_model.dart';
import 'package:study_deck/models/module_model.dart';
import 'package:study_deck/models/semester_model.dart';
import 'package:study_deck/models/subject_model.dart';
import 'package:study_deck/services/academic_service.dart';
import 'package:study_deck/widgets/empty_state_view.dart';
import 'package:study_deck/widgets/responsive_layout.dart';
import 'package:url_launcher/url_launcher.dart';

/// Screen displaying syllabus modules and study materials for a subject with royal styling.
class ModuleAndResourcesScreen extends StatefulWidget {
  const ModuleAndResourcesScreen({
    super.key,
    required this.semester,
    required this.subject,
    this.academicService,
  });

  final SemesterModel semester;
  final SubjectModel subject;
  final AcademicService? academicService;

  @override
  State<ModuleAndResourcesScreen> createState() =>
      _ModuleAndResourcesScreenState();
}

class _ModuleAndResourcesScreenState extends State<ModuleAndResourcesScreen>
    with SingleTickerProviderStateMixin {
  late final AcademicService _academicService;
  late final TabController _tabController;
  ResourceType? _selectedTypeFilter;
  String? _selectedModuleId;

  @override
  void initState() {
    super.initState();
    _academicService = widget.academicService ?? AcademicService();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              widget.subject.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.semester.title} • ${widget.subject.code.isNotEmpty ? widget.subject.code : "Academic Resources"}',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.champagne
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: isDark ? AppColors.goldLight : AppColors.royalGold,
          unselectedLabelColor: isDark
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          indicatorColor: AppColors.royalGold,
          indicatorWeight: 3,
          tabs: const [
            Tab(icon: Icon(Icons.view_module_rounded, size: 20), text: 'Modules'),
            Tab(icon: Icon(Icons.description_rounded, size: 20), text: 'Study Materials'),
          ],
        ),
      ),
      body: PremiumAnimatedGlassBackground(
        isDark: isDark,
        child: TabBarView(
          controller: _tabController,
          children: [
            // Tab 1: Syllabus Modules
            _buildModulesTab(isDark, theme),
            // Tab 2: Study Materials
            _buildResourcesTab(isDark, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildModulesTab(bool isDark, ThemeData theme) {
    return StreamBuilder<List<ModuleModel>>(
      stream: _academicService.watchPublishedModules(
        widget.subject.id,
        subject: widget.subject,
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline_rounded, size: 48, color: Colors.amber),
                  const SizedBox(height: 16),
                  const Text('Unable to Load Modules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.royalGold));
        }

        final modules = snapshot.data ?? [];
        if (modules.isEmpty) {
          return const EmptyStateView(
            icon: Icons.layers_clear_rounded,
            title: 'No Modules Published Yet',
            message:
                'Modules for this course are being prepared by the department. Published syllabus units will appear here.',
          );
        }

        return ResponsiveContainer(
          child: ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: modules.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final module = modules[index];
              return Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.midnightNavy.withValues(alpha: 0.8)
                      : AppColors.pearlWhite.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.royalGold.withValues(alpha: isDark ? 0.25 : 0.35),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.3)
                          : AppColors.deepNavy.withValues(alpha: 0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
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
                      'M${module.moduleNumber}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.goldLight
                            : AppColors.royalGold,
                      ),
                    ),
                  ),
                  title: Text(
                    module.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.warmIvory : AppColors.deepNavy,
                    ),
                  ),
                  subtitle: module.description.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                            module.description,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        )
                      : null,
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: isDark
                        ? AppColors.champagne
                        : AppColors.royalGold,
                  ),
                  onTap: () {
                    // Switch to materials tab filtered to this module
                    setState(() {
                      _selectedModuleId = module.id;
                      _tabController.animateTo(1);
                    });
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildResourcesTab(bool isDark, ThemeData theme) {
    return Column(
      children: [
        // Category and Module filter row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 400),
            child: Row(
              children: [
                if (_selectedModuleId != null) ...[
                  InputChip(
                    label: const Text('Module Filter Active'),
                    onDeleted: () => setState(() => _selectedModuleId = null),
                    deleteIcon: const Icon(Icons.close_rounded, size: 16),
                  ),
                  const SizedBox(width: 8),
                ],
                _filterChip('All Types', null, isDark),
                const SizedBox(width: 8),
                _filterChip('Notes', ResourceType.notes, isDark),
                const SizedBox(width: 8),
                _filterChip('PYQs', ResourceType.pyq, isDark),
                const SizedBox(width: 8),
                _filterChip('Assignments', ResourceType.assignment, isDark),
                const SizedBox(width: 8),
                _filterChip('Syllabus', ResourceType.syllabus, isDark),
              ],
            ),
          ),
        ),
        Expanded(
          child: StreamBuilder<List<AcademicResourceModel>>(
            stream: _academicService.watchPublishedResources(
              subjectId: widget.subject.id,
              subject: widget.subject,
              moduleId: _selectedModuleId,
              type: _selectedTypeFilter,
            ),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 48, color: Colors.amber),
                        const SizedBox(height: 16),
                        const Text('Unable to Load Resources', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('${snapshot.error}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => setState(() {}),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: AppColors.royalGold));
              }

              final resources = snapshot.data ?? [];
              if (resources.isEmpty) {
                return const EmptyStateView(
                  icon: Icons.folder_open_rounded,
                  title: 'No Resources Published Yet',
                  message:
                      'No study materials or question papers are published under this selection yet.',
                );
              }

              return ResponsiveContainer(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  itemCount: resources.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final res = resources[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.midnightNavy.withValues(alpha: 0.8)
                            : AppColors.pearlWhite.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.royalGold.withValues(alpha: isDark ? 0.25 : 0.35),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.3)
                                : AppColors.deepNavy.withValues(alpha: 0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.royalGold.withValues(alpha: isDark ? 0.2 : 0.12),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: AppColors.royalGold.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Icon(
                                    _iconForResourceType(res.type),
                                    color: isDark
                                        ? AppColors.goldLight
                                        : AppColors.royalGold,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        res.title,
                                        style: theme.textTheme.titleSmall
                                            ?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.warmIvory : AppColors.deepNavy,
                                        ),
                                      ),
                                      if (res.description.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          res.description,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? AppColors.deepNavy
                                        : AppColors.warmIvory,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: AppColors.royalGold.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: Text(
                                    res.type.displayName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark
                                          ? AppColors.goldLight
                                          : AppColors.deepNavy,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Divider(
                              color: AppColors.royalGold.withValues(alpha: 0.2),
                              height: 1,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.insert_drive_file_outlined,
                                      size: 14,
                                      color: isDark
                                          ? AppColors.champagne
                                          : AppColors.textSecondaryLight,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      res.fileName.isNotEmpty
                                          ? res.fileName
                                          : 'Document ready',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.warmIvory
                                            : AppColors.textSecondaryLight,
                                      ),
                                    ),
                                  ],
                                ),
                                if (res.fileUrl != null &&
                                    res.fileUrl!.isNotEmpty)
                                  FilledButton.tonalIcon(
                                    onPressed: () async {
                                      final uri = Uri.tryParse(res.fileUrl!);
                                      if (uri != null) {
                                        final launched = await launchUrl(
                                          uri,
                                          mode: LaunchMode.externalApplication,
                                        );
                                        if (!launched && context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Could not open file: ${res.fileUrl}'),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                        }
                                      }
                                    },
                                    icon: const Icon(
                                      Icons.open_in_new_rounded,
                                      size: 16,
                                    ),
                                    label: const Text('View / Download PDF'),
                                  )
                                else
                                  Text(
                                    'PDF document pending',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                              ],
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
        ),
      ],
    );
  }

  Widget _filterChip(String label, ResourceType? type, bool isDark) {
    final isSelected = _selectedTypeFilter == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _selectedTypeFilter = type;
        });
      },
      selectedColor: isDark
          ? AppColors.royalGold.withValues(alpha: 0.3)
          : AppColors.champagne.withValues(alpha: 0.3),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        color: isSelected
            ? (isDark ? AppColors.goldLight : AppColors.deepNavy)
            : (isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight),
      ),
    );
  }

  IconData _iconForResourceType(ResourceType type) {
    switch (type) {
      case ResourceType.notes:
        return Icons.menu_book_rounded;
      case ResourceType.pyq:
        return Icons.history_edu_rounded;
      case ResourceType.assignment:
        return Icons.assignment_outlined;
      case ResourceType.syllabus:
        return Icons.list_alt_rounded;
      case ResourceType.other:
        return Icons.insert_drive_file_outlined;
    }
  }
}
