import 'package:flutter/material.dart';
import 'package:study_deck/core/theme/app_theme.dart';
import 'package:study_deck/models/downloaded_resource_model.dart';
import 'package:study_deck/screens/downloads/downloads_resource_list_screen.dart';
import 'package:study_deck/services/offline_storage_service.dart';
import 'package:study_deck/widgets/empty_state_view.dart';
import 'package:study_deck/widgets/responsive_layout.dart';
import 'package:study_deck/widgets/study_deck_app_bar.dart';

/// Screen listing saved modules within a downloaded subject.
/// Driven entirely by offline metadata.
class DownloadsModuleScreen extends StatefulWidget {
  const DownloadsModuleScreen({
    super.key,
    required this.semesterTitle,
    required this.subjectId,
    required this.subjectTitle,
    required this.resources,
    this.offlineStorageService,
  });

  final String semesterTitle;
  final String subjectId;
  final String subjectTitle;
  final List<DownloadedResourceModel> resources;
  final OfflineStorageService? offlineStorageService;

  @override
  State<DownloadsModuleScreen> createState() => _DownloadsModuleScreenState();
}

class _DownloadsModuleScreenState extends State<DownloadsModuleScreen> {
  late List<DownloadedResourceModel> _currentResources;
  late final OfflineStorageService _storageService;

  @override
  void initState() {
    super.initState();
    _currentResources = List.from(widget.resources);
    _storageService = widget.offlineStorageService ?? OfflineStorageService.instance;
  }

  Future<void> _refresh() async {
    final all = await _storageService.getAllDownloadedResources();
    if (mounted) {
      setState(() {
        _currentResources = all.where((r) => r.subjectId == widget.subjectId).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final Map<String, List<DownloadedResourceModel>> groupedByModule = {};
    for (final doc in _currentResources) {
      final key = doc.moduleId.isNotEmpty ? doc.moduleId : doc.moduleTitle;
      groupedByModule.putIfAbsent(key, () => []).add(doc);
    }

    final moduleKeys = groupedByModule.keys.toList();

    return Scaffold(
      appBar: StudyDeckAppBar(
        title: widget.subjectTitle,
        subtitle: 'Offline Modules',
        showBackButton: true,
        showDownloadsButton: false,
      ),
      body: PremiumAnimatedGlassBackground(
        isDark: isDark,
        child: SafeArea(
          child: moduleKeys.isEmpty
              ? Center(
                  child: EmptyStateView(
                    icon: Icons.folder_open_rounded,
                    title: 'No Offline Modules',
                    message: 'No saved documents remain in ${widget.subjectTitle}.',
                  ),
                )
              : SingleChildScrollView(
                  child: ResponsiveContainer(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Select Module',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: moduleKeys.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final key = moduleKeys[index];
                              final docs = groupedByModule[key]!;
                              final moduleTitle = docs.first.moduleTitle;

                              return Container(
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0x66162248) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? const Color(0x33C5A04A) : const Color(0x26C5A04A),
                                    width: 1.1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(16),
                                    onTap: () async {
                                      await Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => DownloadsResourceListScreen(
                                            semesterTitle: widget.semesterTitle,
                                            subjectTitle: widget.subjectTitle,
                                            moduleId: key,
                                            moduleTitle: moduleTitle,
                                            resources: docs,
                                            offlineStorageService: _storageService,
                                          ),
                                        ),
                                      );
                                      _refresh();
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0x33C5A04A) : const Color(0x1FC5A04A),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isDark ? RoyalColors.glassGoldBorder : const Color(0x40C5A04A),
                                              ),
                                            ),
                                            child: Icon(
                                              Icons.layers_rounded,
                                              color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                                              size: 22,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  moduleTitle,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                    color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${docs.length} saved ${docs.length == 1 ? "PDF" : "PDFs"}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isDark ? RoyalColors.champagne.withValues(alpha: 0.8) : const Color(0xFF64748B),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Icon(
                                            Icons.arrow_forward_ios_rounded,
                                            size: 16,
                                            color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
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
