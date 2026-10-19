import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:study_deck/core/constants/app_constants.dart';
import 'package:study_deck/core/theme/animated_glass_background.dart';
import 'package:study_deck/core/theme/royal_design_system.dart';
import 'package:study_deck/models/academic_resource_model.dart';
import 'package:study_deck/models/semester_model.dart';
import 'package:study_deck/screens/deck/module_list_screen.dart';
import 'package:study_deck/screens/deck/module_resources_screen.dart';
import 'package:study_deck/screens/downloads/downloads_semester_screen.dart';
import 'package:study_deck/screens/student/subject_list_screen.dart';
import 'package:study_deck/screens/viewer/pdf_viewer_screen.dart';
import 'package:study_deck/services/academic_search_service.dart';
import 'package:study_deck/services/academic_service.dart';
import 'package:study_deck/widgets/app_footer.dart';
import 'package:study_deck/widgets/empty_state_view.dart';
import 'package:study_deck/widgets/responsive_layout.dart';
import 'package:study_deck/widgets/study_deck_app_bar.dart';

/// The public home dashboard for students.
/// Upgraded with:
/// 1. Premium Animated Glass Background with drifting orbs and subtle gold particles.
/// 2. Full Light/Dark Theme responsiveness.
/// 3. Fully Functional Real-Time Academic Search across semesters, subjects, modules, and notes.
class StudentHomeScreen extends StatefulWidget {
  const StudentHomeScreen({
    super.key,
    this.academicService,
    this.searchService,
  });

  final AcademicService? academicService;
  final AcademicSearchService? searchService;

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  late final AcademicService _academicService;
  late final AcademicSearchService _searchService;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounceTimer;
  String _searchQuery = '';
  List<SearchResultItem> _searchResults = [];
  bool _isSearching = false;
  bool _hasSearchError = false;
  String? _searchErrorMessage;

  @override
  void initState() {
    super.initState();
    _academicService = widget.academicService ?? AcademicService();
    _searchService = widget.searchService ?? AcademicSearchService();
    _searchFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchQueryChanged(String query) {
    final trimmed = query.trim();
    setState(() {
      _searchQuery = trimmed;
    });

    _debounceTimer?.cancel();

    if (trimmed.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
        _hasSearchError = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _hasSearchError = false;
    });

    _debounceTimer = Timer(const Duration(milliseconds: 280), () async {
      try {
        final results = await _searchService.search(trimmed);
        if (!mounted) return;
        setState(() {
          _searchResults = results;
          _isSearching = false;
          _hasSearchError = false;
        });
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSearching = false;
          _hasSearchError = true;
          _searchErrorMessage = 'Search failed. Please try again.';
        });
      }
    });
  }

  void _clearSearch() {
    _debounceTimer?.cancel();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _searchResults = [];
      _isSearching = false;
      _hasSearchError = false;
    });
  }

  void _showSearchNavigationError(String message) {
    if (!mounted) return;
    _searchFocusNode.unfocus();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: RoyalColors.royalGold,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: RoyalColors.pearlWhite,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: RoyalColors.midnightNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: RoyalColors.royalGold.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _navigateToSearchResult(SearchResultItem item) {
    switch (item.resultType) {
      case SearchResultType.semester:
        if (item.semester != null) {
          _clearSearch();
          _searchFocusNode.unfocus();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SubjectListScreen(
                semester: item.semester!,
                academicService: _academicService,
              ),
            ),
          );
          return;
        }
        _showSearchNavigationError(
          'Unable to open semester. Semester details could not be resolved.',
        );
        break;

      case SearchResultType.subject:
        if (item.subject != null && item.semester != null) {
          _clearSearch();
          _searchFocusNode.unfocus();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ModuleListScreen(
                semester: item.semester!,
                subject: item.subject!,
                academicService: _academicService,
              ),
            ),
          );
          return;
        }
        if (item.semester == null) {
          _showSearchNavigationError(
            'Unable to open subject. Associated semester could not be resolved.',
          );
        } else {
          _showSearchNavigationError(
            'Unable to open subject. Subject details could not be resolved.',
          );
        }
        break;

      case SearchResultType.module:
        if (item.module != null && item.subject != null && item.semester != null) {
          _clearSearch();
          _searchFocusNode.unfocus();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ModuleResourcesScreen(
                semester: item.semester!,
                subject: item.subject!,
                module: item.module!,
                academicService: _academicService,
              ),
            ),
          );
          return;
        }
        if (item.subject == null) {
          _showSearchNavigationError(
            'Unable to open module. Associated subject could not be resolved.',
          );
        } else if (item.semester == null) {
          _showSearchNavigationError(
            'Unable to open module. Associated semester could not be resolved.',
          );
        } else {
          _showSearchNavigationError(
            'Unable to open module. Module details could not be resolved.',
          );
        }
        break;

      case SearchResultType.resource:
        final res = item.resource;
        if (res == null) {
          _showSearchNavigationError(
            'Unable to open resource. Document details could not be resolved.',
          );
          break;
        }

        int initialTab = 0;
        if (res.type == ResourceType.pyq) {
          initialTab = 1;
        } else if (res.type == ResourceType.assignment ||
            res.type == ResourceType.syllabus ||
            res.type == ResourceType.other) {
          initialTab = 2;
        }

        if (item.module != null && item.subject != null && item.semester != null) {
          _clearSearch();
          _searchFocusNode.unfocus();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ModuleResourcesScreen(
                semester: item.semester!,
                subject: item.subject!,
                module: item.module!,
                initialTabIndex: initialTab,
                academicService: _academicService,
              ),
            ),
          );
          return;
        }

        if (res.fileUrl != null && res.fileUrl!.trim().isNotEmpty) {
          _clearSearch();
          _searchFocusNode.unfocus();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PdfViewerScreen(
                title: res.title,
                fileUrl: res.fileUrl,
                fileName: res.fileName,
                documentId: res.id,
              ),
            ),
          );
          return;
        }

        if (item.subject != null && item.semester != null) {
          _clearSearch();
          _searchFocusNode.unfocus();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ModuleListScreen(
                semester: item.semester!,
                subject: item.subject!,
                academicService: _academicService,
              ),
            ),
          );
          return;
        }

        if (item.subject == null) {
          _showSearchNavigationError(
            'Unable to open "${res.title}". Associated subject could not be resolved.',
          );
        } else if (item.semester == null) {
          _showSearchNavigationError(
            'Unable to open "${res.title}". Associated semester could not be resolved.',
          );
        } else {
          _showSearchNavigationError(
            'Unable to open "${res.title}". Resource destination could not be resolved.',
          );
        }
        break;
    }
  }

  void _openDirectPdfViewer(SearchResultItem item) {
    final res = item.resource;
    if (res?.fileUrl != null && res!.fileUrl!.trim().isNotEmpty) {
      _clearSearch();
      _searchFocusNode.unfocus();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(
            title: res.title,
            fileUrl: res.fileUrl,
            fileName: res.fileName,
            documentId: res.id,
          ),
        ),
      );
    } else {
      _showSearchNavigationError('PDF document URL is unavailable.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent, // Displays animated glass background
      appBar: const StudyDeckAppBar(),
      body: PremiumAnimatedGlassBackground(
        isDark: isDark,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ResponsiveContainer(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Grand Futuristic Hero Section: "Your Notes, Simplified."
                    const SizedBox(height: 12),
                    SubtleEntranceAnimation(
                      delayMs: 50,
                      child: _buildRevampedHeroSection(context, isDark),
                    ),
                    const SizedBox(height: 20),

                    // Classy Animated Credit Line: "Developed by : HAMDAN"
                    SubtleEntranceAnimation(
                      delayMs: 120,
                      child: const Center(
                        child: ClassyAnimatedCredit(
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Liquid Glass Academic Search Bar with Multi-Entity Capabilities
                    SubtleEntranceAnimation(
                      delayMs: 180,
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 680),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              LiquidGlassSearchBar(
                                controller: _searchController,
                                focusNode: _searchFocusNode,
                                isDark: isDark,
                                isLoading: _isSearching,
                                hintText: 'Search for notes...',
                                onChanged: _onSearchQueryChanged,
                                onClear: _clearSearch,
                              ),

                              // Real-Time Academic Search Results Panel
                              if (_searchQuery.isNotEmpty) ...[
                                const SizedBox(height: 10),
                                _buildSearchResultsPanel(isDark),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick Offline Downloads Bar
                    SubtleEntranceAnimation(
                      delayMs: 240,
                      child: _buildDownloadsRow(context),
                    ),
                    const SizedBox(height: 28),

                    // Section Title: Academic Semesters
                    SubtleEntranceAnimation(
                      delayMs: 280,
                      child: _buildSectionHeader(theme, isDark),
                    ),
                    const SizedBox(height: 16),

                    // Semester Cards Stream
                    SubtleEntranceAnimation(
                      delayMs: 320,
                      child: StreamBuilder<List<SemesterModel>>(
                        stream: _academicService.watchPublishedSemesters(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return _buildErrorState(snapshot.error.toString(), isDark);
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return _buildLoadingState(isDark);
                          }

                          final allSemesters = snapshot.data ?? [];
                          if (allSemesters.isEmpty) {
                            return const EmptyStateView(
                              icon: Icons.school_outlined,
                              title: 'Academic Content Preparing',
                              message:
                                  'No semesters are published in the database yet. Course notes, previous question papers, and assignments will appear here once released by the academic office.',
                            );
                          }

                          return LayoutBuilder(
                            builder: (context, constraints) {
                              int crossAxisCount = 2;
                              double aspectRatio = 1.05;

                              if (constraints.maxWidth >= 1050) {
                                crossAxisCount = 4;
                                aspectRatio = 1.15;
                              } else if (constraints.maxWidth >= 650) {
                                crossAxisCount = 3;
                                aspectRatio = 1.10;
                              }

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: aspectRatio,
                                ),
                                itemCount: allSemesters.length,
                                itemBuilder: (context, index) {
                                  final semester = allSemesters[index];
                                  return RoyalSemesterCard(
                                    semester: semester,
                                    isDark: isDark,
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => SubjectListScreen(
                                            semester: semester,
                                            academicService: _academicService,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 24),

                    // App Footer with Open Access notice and HAMDAN credits
                    const AppFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Grand futuristic hero section directly showcasing:
  /// "Your Notes,
  ///  Simplified."
  Widget _buildRevampedHeroSection(BuildContext context, bool isDark) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // App Tagline Sub-Badge
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories_rounded,
                size: 16,
                color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF8A6715),
              ),
              const SizedBox(width: 8),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  color: isDark ? const Color(0xFFD4AF37) : const Color(0xFF0B1120),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                ' • ',
                style: TextStyle(
                  color: isDark ? const Color(0xFF8A99AD) : const Color(0xFF64748B),
                ),
              ),
              Text(
                AppConstants.appTagline,
                style: TextStyle(
                  color: isDark ? const Color(0xFFE5CCA0) : const Color(0xFF8A6715),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Big, Bold Hero Headline: "Your Notes, Simplified."
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Your Notes,\n',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
              WidgetSpan(
                child: ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) {
                    return LinearGradient(
                      colors: isDark
                          ? const [
                              Color(0xFFFFE082), // Soft bright gold
                              Color(0xFFD4AF37), // Metallic gold
                              Color(0xFFE5CCA0), // Champagne
                            ]
                          : const [
                              Color(0xFFD4AF37),
                              Color(0xFFA88434),
                              Color(0xFF8C6D26),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds);
                  },
                  child: Text(
                    'Simplified.',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -1.2,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: const Color(0xFFC5A04A)
                              .withValues(alpha: isDark ? 0.4 : 0.25),
                          blurRadius: 28,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Prompt Subtitle
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Text(
            'All the best for your studies! Pick a semester below to get started with curated notes and resources.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w500,
              color: isDark ? const Color(0xFFB0BDD4) : const Color(0xFF4A5568),
              letterSpacing: 0.1,
            ),
          ),
        ),
      ],
    );
  }

  /// Real-Time Academic Search Results Panel
  Widget _buildSearchResultsPanel(bool isDark) {
    final panelBg = isDark ? const Color(0xF2091124) : const Color(0xF7FFFFFF);
    final borderColor = isDark ? const Color(0x59C5A04A) : const Color(0x66C5A04A);

    return Container(
      constraints: const BoxConstraints(maxHeight: 380),
      decoration: BoxDecoration(
        color: panelBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: _buildSearchResultsContent(isDark),
        ),
      ),
    );
  }

  Widget _buildSearchResultsContent(bool isDark) {
    if (_isSearching) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36.0, horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                color: RoyalColors.royalGold,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Searching academic decks, modules & notes...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFB0BDD4) : const Color(0xFF4A5568),
              ),
            ),
          ],
        ),
      );
    }

    if (_hasSearchError) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 28, color: Color(0xFFDC2626)),
            const SizedBox(height: 10),
            Text(
              _searchErrorMessage ?? 'Search error occurred',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 12),
            RoyalLiquidGlassButton(
              label: 'Retry Search',
              icon: Icons.refresh_rounded,
              onPressed: () => _onSearchQueryChanged(_searchQuery),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 36,
              color: isDark ? const Color(0xFF6B7A90) : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 10),
            Text(
              'No academic materials found for "$_searchQuery"',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try searching by subject code (e.g. TC101), semester ("Sem 1"), module title, or "notes".',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF8A99AD) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _searchResults.length,
      separatorBuilder: (context, index) => Divider(
        height: 1,
        color: isDark ? const Color(0x1AFFFFFF) : const Color(0x14000000),
      ),
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return _buildSearchResultTile(item, isDark);
      },
    );
  }

  Widget _buildSearchResultTile(SearchResultItem item, bool isDark) {
    IconData icon;
    Color iconColor;

    switch (item.resultType) {
      case SearchResultType.semester:
        icon = Icons.school_rounded;
        iconColor = const Color(0xFFD4AF37);
        break;
      case SearchResultType.subject:
        icon = Icons.auto_stories_rounded;
        iconColor = const Color(0xFF38BDF8);
        break;
      case SearchResultType.module:
        icon = Icons.layers_rounded;
        iconColor = const Color(0xFF34D399);
        break;
      case SearchResultType.resource:
        icon = Icons.description_rounded;
        iconColor = const Color(0xFFF59E0B);
        break;
    }

    final hasPdf = item.resource?.fileUrl != null &&
        item.resource!.fileUrl!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToSearchResult(item),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              // Type Icon
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.15 : 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 14),

              // Title, Category & Breadcrumb context trail
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Category Pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0x2EC5A04A)
                                : const Color(0x1FC5A04A),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.typeLabel,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? const Color(0xFFE5CCA0)
                                  : const Color(0xFFA88434),
                            ),
                          ),
                        ),
                        if (item.contextTrail.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.contextTrail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark
                                    ? const Color(0xFF8A99AD)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? RoyalColors.pearlWhite
                            : RoyalColors.midnightNavy,
                      ),
                    ),
                    if (item.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xFF8A99AD)
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Direct PDF Viewing Chip or arrow
              if (hasPdf) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _openDirectPdfViewer(item),
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 14),
                  label: const Text('View PDF', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: const Color(0xFF38BDF8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  ),
                ),
              ] else ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: isDark ? const Color(0xFF6B7A90) : const Color(0xFF94A3B8),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Quick downloads button
  Widget _buildDownloadsRow(BuildContext context) {
    return Center(
      child: RoyalLiquidGlassButton(
        label: 'Offline Downloads',
        icon: Icons.download_for_offline_rounded,
        isGold: true,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 11),
        borderRadius: 24,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const DownloadsSemesterScreen(),
            ),
          );
        },
      ),
    );
  }

  /// Academic Semesters Section Header
  Widget _buildSectionHeader(ThemeData theme, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                gradient: RoyalGradients.metallicGold,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Academic Semesters',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.4,
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              ),
            ),
          ],
        ),
        Flexible(
          child: Text(
            'Select your deck to begin',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF8A99AD) : const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Refined Loading State with Royal Gold styling
  Widget _buildLoadingState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      child: Center(
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
              'Loading academic decks...',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF8A99AD) : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Refined Error State with Antique Gold icon and Liquid Glass retry action
  Widget _buildErrorState(String error, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
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
                'Unable to Load Semesters',
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
      ),
    );
  }
}

/// Interactive, liquid-glass Semester Card responding dynamically to both
/// Dark and Light themes.
class RoyalSemesterCard extends StatefulWidget {
  const RoyalSemesterCard({
    super.key,
    required this.semester,
    required this.isDark,
    required this.onTap,
  });

  final SemesterModel semester;
  final bool isDark;
  final VoidCallback onTap;

  @override
  State<RoyalSemesterCard> createState() => _RoyalSemesterCardState();
}

class _RoyalSemesterCardState extends State<RoyalSemesterCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    final cardBg = isDark
        ? const Color(0xE60B1224) // Frosted obsidian dark navy
        : const Color(0xF2FFFFFF); // Frosted pearl ivory

    final borderColor = _isHovered
        ? (isDark ? const Color(0xFF38BDF8) : RoyalColors.royalGold)
        : (isDark ? const Color(0x33C5A04A) : const Color(0x40C5A04A));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.025 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: borderColor,
              width: _isHovered ? 1.6 : 1.0,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: (isDark ? const Color(0xFF38BDF8) : RoyalColors.royalGold)
                      .withValues(alpha: isDark ? 0.28 : 0.20),
                  blurRadius: 20,
                  spreadRadius: 1,
                  offset: const Offset(0, 6),
                )
              else
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top Row: Status Pill with Glowing Dot + Glowing Book Icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Status Pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? const Color(0x26000000)
                                    : const Color(0x14C5A04A),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0x3310B981),
                                  width: 0.8,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Color(0xFF10B981),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x9910B981),
                                          blurRadius: 5,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Available',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                      color: isDark
                                          ? const Color(0xFFE5CCA0)
                                          : const Color(0xFFA88434),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Glowing Book / Deck Silhouette Icon
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: _isHovered
                                    ? (isDark
                                        ? const Color(0x3338BDF8)
                                        : RoyalColors.paleGold)
                                    : (isDark
                                        ? const Color(0x1A101B3B)
                                        : const Color(0x14C5A04A)),
                                borderRadius: BorderRadius.circular(10),
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
                                child: Icon(
                                  Icons.menu_book_rounded,
                                  size: 20,
                                  color: _isHovered
                                      ? (isDark
                                          ? const Color(0xFF38BDF8)
                                          : RoyalColors.royalGold)
                                      : (isDark
                                          ? const Color(0xFF60A5FA)
                                          : RoyalColors.antiqueGold),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Center: Title & Syllabus Subtitle
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Semester ${widget.semester.semesterNumber}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 20,
                                letterSpacing: -0.4,
                                color: isDark
                                    ? RoyalColors.pearlWhite
                                    : RoyalColors.midnightNavy,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.semester.title.isNotEmpty &&
                                      widget.semester.title !=
                                          'Semester ${widget.semester.semesterNumber}'
                                  ? widget.semester.title
                                  : 'Current Syllabus',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? const Color(0xFF8A99AD)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),

                        // Bottom Row: VIEW NOTES -> Action with animated hover shift
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'VIEW NOTES',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: _isHovered
                                    ? (isDark
                                        ? const Color(0xFF38BDF8)
                                        : RoyalColors.royalGold)
                                    : (isDark
                                        ? const Color(0xFF8A99AD)
                                        : const Color(0xFF64748B)),
                              ),
                            ),
                            AnimatedPadding(
                              duration: const Duration(milliseconds: 180),
                              padding:
                                  EdgeInsets.only(left: _isHovered ? 6.0 : 0.0),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 15,
                                color: _isHovered
                                    ? (isDark
                                        ? const Color(0xFF38BDF8)
                                        : RoyalColors.royalGold)
                                    : (isDark
                                        ? const Color(0xFF8A99AD)
                                        : const Color(0xFF64748B)),
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
