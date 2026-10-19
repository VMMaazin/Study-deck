import 'package:flutter/material.dart';
import 'package:study_deck/core/theme/app_theme.dart';
import 'package:study_deck/models/downloaded_resource_model.dart';
import 'package:study_deck/screens/downloads/downloads_subject_screen.dart';
import 'package:study_deck/services/offline_storage_service.dart';
import 'package:study_deck/widgets/empty_state_view.dart';
import 'package:study_deck/widgets/responsive_layout.dart';
import 'package:study_deck/widgets/study_deck_app_bar.dart';

/// Top-level offline Downloads destination.
/// Uses purely locally stored metadata without requiring Firestore or internet.
class DownloadsSemesterScreen extends StatefulWidget {
  const DownloadsSemesterScreen({
    super.key,
    this.offlineStorageService,
  });

  final OfflineStorageService? offlineStorageService;

  @override
  State<DownloadsSemesterScreen> createState() => _DownloadsSemesterScreenState();
}

class _DownloadsSemesterScreenState extends State<DownloadsSemesterScreen> {
  late final OfflineStorageService _storageService;
  bool _isLoading = true;
  List<DownloadedResourceModel> _allDownloads = [];

  @override
  void initState() {
    super.initState();
    _storageService = widget.offlineStorageService ?? OfflineStorageService.instance;
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    setState(() => _isLoading = true);
    try {
      final list = await _storageService.getAllDownloadedResources();
      if (mounted) {
        setState(() {
          _allDownloads = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Group downloads by semesterId
    final Map<String, List<DownloadedResourceModel>> groupedBySemester = {};
    for (final doc in _allDownloads) {
      final key = doc.semesterId.isNotEmpty ? doc.semesterId : doc.semesterTitle;
      groupedBySemester.putIfAbsent(key, () => []).add(doc);
    }

    final semesterKeys = groupedBySemester.keys.toList();

    return Scaffold(
      appBar: const StudyDeckAppBar(
        title: 'Offline Downloads',
        subtitle: 'Browse your locally saved study materials',
        showBackButton: true,
        showDownloadsButton: false,
      ),
      body: PremiumAnimatedGlassBackground(
        isDark: isDark,
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (semesterKeys.isEmpty
                  ? Center(
                      child: EmptyStateView(
                        icon: Icons.download_done_rounded,
                        title: 'No Offline Downloads Yet',
                        message:
                            'Download lecture notes or question banks using the "Download in App" action to study anywhere without internet.',
                      ),
                    )
                  : SingleChildScrollView(
                      child: ResponsiveContainer(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Royal Info Card
                              Container(
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0x66162248) : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isDark ? RoyalColors.glassGoldBorder : const Color(0x40C5A04A),
                                    width: 1.2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: RoyalGradients.metallicGold,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: RoyalColors.royalGold.withValues(alpha: 0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 3),
                                          ),
                                        ],
                                      ),
                                      child: const Icon(
                                        Icons.offline_pin_rounded,
                                        color: RoyalColors.midnightNavy,
                                        size: 26,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '${_allDownloads.length} ${_allDownloads.length == 1 ? "document" : "documents"} saved offline',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 15,
                                              color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            'All saved files can be viewed seamlessly without internet access.',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark ? RoyalColors.textMutedDark : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),

                              Text(
                                'Select Semester',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                                ),
                              ),
                              const SizedBox(height: 14),

                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: semesterKeys.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final key = semesterKeys[index];
                                  final docs = groupedBySemester[key]!;
                                  final semTitle = docs.first.semesterTitle;

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
                                              builder: (_) => DownloadsSubjectScreen(
                                                semesterId: key,
                                                semesterTitle: semTitle,
                                                resources: docs,
                                                offlineStorageService: _storageService,
                                              ),
                                            ),
                                          );
                                          _loadDownloads();
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
                                                  Icons.school_rounded,
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
                                                      semTitle,
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.w700,
                                                        fontSize: 16,
                                                        color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${docs.length} saved ${docs.length == 1 ? "document" : "documents"}',
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
                    )),
        ),
      ),
    );
  }
}
