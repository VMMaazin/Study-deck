import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:study_deck/core/theme/app_theme.dart';
import 'package:study_deck/services/offline_storage_service.dart';
import 'package:study_deck/widgets/study_deck_app_bar.dart';
import 'package:url_launcher/url_launcher.dart';

/// Dedicated in-app PDF viewer screen for students and faculty.
/// Supports both online streaming from Cloudinary and genuine offline viewing
/// from locally persisted IndexedDB bytes (Web) or application-private storage (Android).
class PdfViewerScreen extends StatefulWidget {
  const PdfViewerScreen({
    super.key,
    required this.title,
    this.fileUrl,
    this.fileName,
    this.documentId,
    this.localBytes,
    this.localFilePath,
    this.isOffline = false,
  });

  final String title;
  final String? fileUrl;
  final String? fileName;
  final String? documentId;
  final Uint8List? localBytes;
  final String? localFilePath;
  final bool isOffline;

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late final PdfViewerController _controller;
  int _currentPage = 1;
  int _pageCount = 0;
  bool _hasError = false;
  String? _errorMessage;
  int _loadKey = 0;

  Uint8List? _resolvedBytes;
  String? _resolvedFilePath;
  bool _isLoadingOfflineData = false;
  bool _offlineDataMissing = false;

  @override
  void initState() {
    super.initState();
    _controller = PdfViewerController();
    _controller.addListener(_onViewerUpdate);

    _resolvedBytes = widget.localBytes;
    _resolvedFilePath = widget.localFilePath;

    if (widget.isOffline && _resolvedBytes == null && _resolvedFilePath == null) {
      _loadOfflineData();
    }
  }

  Future<void> _loadOfflineData() async {
    final docId = widget.documentId;
    if (docId == null || docId.isEmpty) {
      setState(() {
        _offlineDataMissing = true;
      });
      return;
    }

    setState(() {
      _isLoadingOfflineData = true;
      _offlineDataMissing = false;
    });

    try {
      final storage = OfflineStorageService.instance;
      final bytes = await storage.getResourceBytes(docId);
      final path = await storage.getResourceFilePath(docId);

      if (!mounted) return;

      if ((bytes == null || bytes.isEmpty) && (path == null || path.isEmpty)) {
        setState(() {
          _isLoadingOfflineData = false;
          _offlineDataMissing = true;
        });
      } else {
        setState(() {
          _resolvedBytes = bytes;
          _resolvedFilePath = path;
          _isLoadingOfflineData = false;
          _offlineDataMissing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingOfflineData = false;
          _offlineDataMissing = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onViewerUpdate);
    super.dispose();
  }

  void _onViewerUpdate() {
    if (!mounted) return;
    final page = _controller.pageNumber ?? 1;
    final total = _controller.pageCount;
    if (page != _currentPage || total != _pageCount) {
      setState(() {
        _currentPage = page;
        _pageCount = total;
      });
    }
  }

  Future<void> _handleDownloadOrExport() async {
    // If offline or local bytes are already loaded, export directly to device without network!
    if (_resolvedBytes != null && _resolvedBytes!.isNotEmpty) {
      final name = widget.fileName?.isNotEmpty == true ? widget.fileName! : '${widget.title}.pdf';
      final success = await OfflineStorageService.instance.exportToDevice(
        fileName: name,
        bytes: _resolvedBytes!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'File exported to device storage successfully.' : 'Export was cancelled or could not be completed.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    // Otherwise, fallback to remote Cloudinary URL launch
    final url = widget.fileUrl?.trim() ?? '';
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Download URL is not available for this document.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    try {
      final uri = Uri.parse(url);
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not download document: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _zoomIn() {
    _controller.zoomUp();
  }

  void _zoomOut() {
    _controller.zoomDown();
  }

  void _resetZoom() {
    if (_controller.isReady) {
      _controller.setZoom(_controller.centerPosition, 1.0);
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 1) {
      _controller.goToPage(pageNumber: _currentPage - 1);
    }
  }

  void _goToNextPage() {
    if (_pageCount > 0 && _currentPage < _pageCount) {
      _controller.goToPage(pageNumber: _currentPage + 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final trimmedUrl = widget.fileUrl?.trim() ?? '';
    final isOnlineValid = trimmedUrl.isNotEmpty &&
        (trimmedUrl.startsWith('http://') || trimmedUrl.startsWith('https://'));

    return Scaffold(
      appBar: StudyDeckAppBar(
        title: widget.title,
        subtitle: widget.isOffline
            ? 'Offline Document • ${widget.fileName ?? ""}'
            : (widget.fileName?.isNotEmpty == true ? widget.fileName! : 'StudyDeck PDF Viewer'),
        showBackButton: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Viewer Utility Bar: Page Info, Zoom In/Out, and Download / Export Action
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xE6101B3B) : const Color(0xF2FAF7F0),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? RoyalColors.glassGoldBorder : const Color(0x33C5A04A),
                    width: 1,
                  ),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Page Tracker Chip
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x66162248) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? const Color(0x4DC5A04A) : const Color(0x40C5A04A),
                        ),
                      ),
                      child: Text(
                        _pageCount > 0
                            ? 'Page $_currentPage of $_pageCount'
                            : (_isLoadingOfflineData ? 'Loading offline data...' : 'Loading pages...'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                        ),
                      ),
                    ),

                    if (widget.isOffline) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.offline_pin_rounded, size: 13, color: Color(0xFF10B981)),
                            SizedBox(width: 4),
                            Text(
                              'Offline Copy',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(width: 16),

                    // Zoom In / Out Buttons
                    IconButton(
                      icon: Icon(
                        Icons.zoom_out_rounded,
                        size: 20,
                        color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                      ),
                      tooltip: 'Zoom Out',
                      onPressed: _hasError ? null : _zoomOut,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.zoom_in_rounded,
                        size: 20,
                        color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                      ),
                      tooltip: 'Zoom In',
                      onPressed: _hasError ? null : _zoomIn,
                      visualDensity: VisualDensity.compact,
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.fit_screen_rounded,
                        size: 20,
                        color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                      ),
                      tooltip: 'Reset Zoom',
                      onPressed: _hasError ? null : _resetZoom,
                      visualDensity: VisualDensity.compact,
                    ),

                    const SizedBox(width: 8),
                    Container(
                      height: 18,
                      width: 1,
                      color: isDark ? const Color(0x33C5A04A) : const Color(0x33C5A04A),
                    ),
                    const SizedBox(width: 8),

                    // Dedicated Download / Device Export Button
                    FilledButton.icon(
                      icon: Icon(
                        widget.isOffline ? Icons.save_alt_rounded : Icons.download_rounded,
                        size: 16,
                      ),
                      label: Text(
                        widget.isOffline ? 'Export to Device' : 'Download',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: RoyalColors.royalGold,
                        foregroundColor: RoyalColors.midnightNavy,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: _handleDownloadOrExport,
                    ),
                  ],
                ),
              ),
            ),

            // In-app Viewer Area
            Expanded(
              child: _buildViewerContent(theme, isDark, isOnlineValid, trimmedUrl),
            ),

            // Bottom Navigation Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xE6101B3B) : const Color(0xF2FAF7F0),
                border: Border(
                  top: BorderSide(
                    color: isDark ? RoyalColors.glassGoldBorder : const Color(0x33C5A04A),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: Icon(
                      Icons.arrow_back_ios_rounded,
                      size: 14,
                      color: _currentPage > 1
                          ? (isDark ? RoyalColors.champagne : const Color(0xFF8A6715))
                          : (isDark ? RoyalColors.textMutedDark.withValues(alpha: 0.4) : Colors.black26),
                    ),
                    label: Text(
                      'Previous Page',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _currentPage > 1
                            ? (isDark ? RoyalColors.champagne : const Color(0xFF8A6715))
                            : (isDark ? RoyalColors.textMutedDark.withValues(alpha: 0.4) : Colors.black26),
                      ),
                    ),
                    onPressed: _currentPage > 1 ? _goToPreviousPage : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0x33C5A04A) : const Color(0x1FC5A04A),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _pageCount > 0 ? '$_currentPage / $_pageCount' : '--',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: _pageCount > 0 && _currentPage < _pageCount
                          ? (isDark ? RoyalColors.champagne : const Color(0xFF8A6715))
                          : (isDark ? RoyalColors.textMutedDark.withValues(alpha: 0.4) : Colors.black26),
                    ),
                    label: Text(
                      'Next Page',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _pageCount > 0 && _currentPage < _pageCount
                            ? (isDark ? RoyalColors.champagne : const Color(0xFF8A6715))
                            : (isDark ? RoyalColors.textMutedDark.withValues(alpha: 0.4) : Colors.black26),
                      ),
                    ),
                    onPressed: _pageCount > 0 && _currentPage < _pageCount ? _goToNextPage : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewerContent(
    ThemeData theme,
    bool isDark,
    bool isOnlineValid,
    String trimmedUrl,
  ) {
    if (_isLoadingOfflineData) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading offline PDF from local storage...',
              style: TextStyle(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.isOffline) {
      if (_offlineDataMissing || (_resolvedBytes == null && _resolvedFilePath == null)) {
        return _buildOfflineMissingState(theme, isDark);
      }

      // Render genuine offline data
      if (_resolvedBytes != null) {
        return PdfViewer.data(
          _resolvedBytes!,
          key: ValueKey('local_data_$_loadKey'),
          sourceName: widget.fileName ?? widget.title,
          controller: _controller,
          params: _buildViewerParams(theme, isDark, isOfflineSource: true),
        );
      } else {
        return PdfViewer.file(
          _resolvedFilePath!,
          key: ValueKey('local_file_$_loadKey'),
          controller: _controller,
          params: _buildViewerParams(theme, isDark, isOfflineSource: true),
        );
      }
    }

    // Online viewer flow
    if (!isOnlineValid) {
      return _buildInvalidUrlState(theme, isDark);
    }

    return PdfViewer.uri(
      key: ValueKey('${trimmedUrl}_$_loadKey'),
      Uri.parse(trimmedUrl),
      controller: _controller,
      params: _buildViewerParams(theme, isDark, isOfflineSource: false),
    );
  }

  PdfViewerParams _buildViewerParams(
    ThemeData theme,
    bool isDark, {
    required bool isOfflineSource,
  }) {
    return PdfViewerParams(
      backgroundColor: isDark ? const Color(0xFF090F22) : const Color(0xFFEDE7D9),
      loadingBannerBuilder: (context, bytesDownloaded, totalBytes) {
        final progress = totalBytes != null && totalBytes > 0
            ? bytesDownloaded / totalBytes
            : null;
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 3,
                  color: RoyalColors.royalGold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                isOfflineSource
                    ? 'Rendering local PDF...'
                    : (progress != null
                        ? 'Loading PDF (${(progress * 100).toInt()}%)...'
                        : 'Fetching document from Cloudinary...'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                ),
              ),
            ],
          ),
        );
      },
      errorBannerBuilder: (context, error, stackTrace, documentRef) {
        _hasError = true;
        _errorMessage = error.toString();
        return _buildErrorState(theme, isDark);
      },
      onViewerReady: (document, controller) {
        if (mounted) {
          setState(() {
            _pageCount = document.pages.length;
          });
        }
      },
      onPageChanged: (pageNumber) {
        if (mounted && pageNumber != null) {
          setState(() {
            _currentPage = pageNumber;
          });
        }
      },
      enableKeyboardNavigation: true,
    );
  }

  Widget _buildOfflineMissingState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.file_download_off_rounded,
                  color: Color(0xFFDC2626),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Offline Document Not Found or Corrupted',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'The locally saved copy of "${widget.title}" is missing or unreadable on this device. You can re-download this document when connected to the internet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? RoyalColors.textMutedDark : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                      side: BorderSide(
                        color: isDark ? RoyalColors.glassGoldBorder : const Color(0x66C5A04A),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Go Back'),
                  ),
                  if (widget.fileUrl != null && widget.fileUrl!.isNotEmpty)
                    FilledButton.icon(
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Try Re-download'),
                      style: FilledButton.styleFrom(
                        backgroundColor: RoyalColors.royalGold,
                        foregroundColor: RoyalColors.midnightNavy,
                      ),
                      onPressed: () {
                        // Switch to online viewing if user explicitly requests re-download
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => PdfViewerScreen(
                              title: widget.title,
                              fileUrl: widget.fileUrl,
                              fileName: widget.fileName,
                              isOffline: false,
                            ),
                          ),
                        );
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvalidUrlState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0x33C5A04A) : const Color(0x1FC5A04A),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark ? RoyalColors.glassGoldBorder : const Color(0x33C5A04A),
                ),
              ),
              child: const Icon(Icons.link_off_rounded, size: 36, color: Color(0xFFD97706)),
            ),
            const SizedBox(height: 16),
            Text(
              'Invalid Document URL',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The file link for "${widget.title}" is missing or improperly formed.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? RoyalColors.textMutedDark : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                side: BorderSide(
                  color: isDark ? RoyalColors.glassGoldBorder : const Color(0x66C5A04A),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.picture_as_pdf_rounded,
                  color: Color(0xFFDC2626),
                  size: 36,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to Render PDF Inline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage != null && _errorMessage!.contains('CORS')
                    ? 'Browser cross-origin security prevented inline rendering. You can still open or download the PDF directly.'
                    : 'The PDF document could not be rendered in-app. Network conditions or browser restrictions may prevent inline display.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? RoyalColors.textMutedDark : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Retry'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                      side: BorderSide(
                        color: isDark ? RoyalColors.glassGoldBorder : const Color(0x66C5A04A),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _hasError = false;
                        _errorMessage = null;
                        _loadKey++;
                      });
                    },
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Download / Open PDF'),
                    style: FilledButton.styleFrom(
                      backgroundColor: RoyalColors.royalGold,
                      foregroundColor: RoyalColors.midnightNavy,
                    ),
                    onPressed: _handleDownloadOrExport,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
