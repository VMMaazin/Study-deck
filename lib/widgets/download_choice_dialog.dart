import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:study_deck/core/theme/app_theme.dart';
import 'package:study_deck/models/academic_resource_model.dart';
import 'package:study_deck/models/downloaded_resource_model.dart';
import 'package:study_deck/models/module_model.dart';
import 'package:study_deck/models/semester_model.dart';
import 'package:study_deck/models/subject_model.dart';
import 'package:study_deck/screens/viewer/pdf_viewer_screen.dart';
import 'package:study_deck/services/offline_storage_service.dart';

/// Modal dialog presenting students with a clear choice between:
/// 1. Download in app (for persistent offline viewing inside StudyDeck)
/// 2. Download to device (user-accessible device storage)
class DownloadChoiceDialog extends StatefulWidget {
  const DownloadChoiceDialog({
    super.key,
    required this.resource,
    required this.semester,
    required this.subject,
    required this.module,
    this.offlineStorageService,
    this.httpClient,
  });

  final AcademicResourceModel resource;
  final SemesterModel semester;
  final SubjectModel subject;
  final ModuleModel module;
  final OfflineStorageService? offlineStorageService;
  final http.Client? httpClient;

  static Future<void> show(
    BuildContext context, {
    required AcademicResourceModel resource,
    required SemesterModel semester,
    required SubjectModel subject,
    required ModuleModel module,
    OfflineStorageService? offlineStorageService,
    http.Client? httpClient,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => DownloadChoiceDialog(
        resource: resource,
        semester: semester,
        subject: subject,
        module: module,
        offlineStorageService: offlineStorageService,
        httpClient: httpClient,
      ),
    );
  }

  @override
  State<DownloadChoiceDialog> createState() => _DownloadChoiceDialogState();
}

class _DownloadChoiceDialogState extends State<DownloadChoiceDialog> {
  late final OfflineStorageService _storageService;
  bool _isCheckingStatus = true;
  bool _isAlreadySaved = false;
  DownloadedResourceModel? _savedMetadata;

  bool _isDownloadingInApp = false;

  bool _isExportingToDevice = false;

  @override
  void initState() {
    super.initState();
    _storageService = widget.offlineStorageService ?? OfflineStorageService.instance;
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    try {
      final isSaved = await _storageService.isResourceSaved(widget.resource.id);
      DownloadedResourceModel? meta;
      if (isSaved) {
        meta = await _storageService.getMetadata(widget.resource.id);
      }
      if (mounted) {
        setState(() {
          _isAlreadySaved = isSaved;
          _savedMetadata = meta;
          _isCheckingStatus = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isCheckingStatus = false;
        });
      }
    }
  }

  Future<Uint8List?> _fetchBytesFromNetwork(String url) async {
    final client = widget.httpClient ?? http.Client();
    try {
      final uri = Uri.parse(url);
      final response = await client.get(uri);
      if (response.statusCode == 200) {
        return response.bodyBytes;
      }
      return null;
    } catch (e) {
      debugPrint('Failed to fetch bytes from Cloudinary: $e');
      return null;
    }
  }

  Future<void> _handleDownloadInApp() async {
    final url = widget.resource.fileUrl?.trim() ?? '';
    if (url.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Document file URL is missing.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isDownloadingInApp = true;
    });

    try {
      final bytes = await _fetchBytesFromNetwork(url);
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Failed to download document from Cloudinary. Check network connectivity.');
      }

      final metadata = DownloadedResourceModel(
        id: widget.resource.id,
        title: widget.resource.title,
        fileName: widget.resource.fileName.isNotEmpty ? widget.resource.fileName : '${widget.resource.title}.pdf',
        fileSize: bytes.lengthInBytes,
        fileUrl: url,
        semesterId: widget.semester.id,
        semesterTitle: widget.semester.title,
        subjectId: widget.subject.id,
        subjectTitle: widget.subject.name,
        subjectCode: widget.subject.code,
        moduleId: widget.module.id,
        moduleTitle: widget.module.title,
        resourceType: widget.resource.type,
        savedAt: DateTime.now(),
      );

      await _storageService.saveResource(metadata: metadata, bytes: bytes);

      if (!mounted) return;

      setState(() {
        _isDownloadingInApp = false;
        _isAlreadySaved = true;
        _savedMetadata = metadata;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "${widget.resource.title}" for offline viewing.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloadingInApp = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not save document in app: $e'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleRemoveLocalCopy() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).brightness == Brightness.dark
            ? RoyalColors.midnightNavySurface
            : RoyalColors.pearlWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: Theme.of(ctx).brightness == Brightness.dark
                ? RoyalColors.glassGoldBorder
                : const Color(0x33C5A04A),
          ),
        ),
        title: Text(
          'Remove Offline Copy?',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Theme.of(ctx).brightness == Brightness.dark
                ? RoyalColors.pearlWhite
                : RoyalColors.midnightNavy,
          ),
        ),
        content: Text(
          'This will remove the offline copy of "${widget.resource.title}" from this device. '
          'The document remains safely stored on StudyDeck.',
          style: TextStyle(
            color: Theme.of(ctx).brightness == Brightness.dark
                ? RoyalColors.textMutedDark
                : const Color(0xFF4A5568),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: Theme.of(ctx).brightness == Brightness.dark
                    ? RoyalColors.champagne
                    : const Color(0xFF64748B),
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _storageService.deleteResource(widget.resource.id);
      if (mounted) {
        setState(() {
          _isAlreadySaved = false;
          _savedMetadata = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed offline copy of "${widget.resource.title}".'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleDownloadToDevice() async {
    setState(() {
      _isExportingToDevice = true;
    });

    try {
      Uint8List? bytes;

      // Device Export optimization: If already saved locally, use local bytes without fetching from Cloudinary!
      if (_isAlreadySaved) {
        bytes = await _storageService.getResourceBytes(widget.resource.id);
      }

      // Otherwise fetch from Cloudinary
      if (bytes == null || bytes.isEmpty) {
        final url = widget.resource.fileUrl?.trim() ?? '';
        if (url.isEmpty) {
          throw Exception('File link is missing.');
        }
        bytes = await _fetchBytesFromNetwork(url);
      }

      if (bytes == null || bytes.isEmpty) {
        throw Exception('Could not retrieve PDF data.');
      }

      final fileName = widget.resource.fileName.isNotEmpty
          ? widget.resource.fileName
          : '${widget.resource.title}.pdf';

      final success = await _storageService.exportToDevice(
        fileName: fileName,
        bytes: bytes,
      );

      if (!mounted) return;

      setState(() {
        _isExportingToDevice = false;
      });

      if (success) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved "$fileName" to device successfully.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Device save was cancelled or could not be completed.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExportingToDevice = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save to device: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _openOfflineViewer() {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          title: widget.resource.title,
          documentId: widget.resource.id,
          fileName: widget.resource.fileName,
          fileUrl: widget.resource.fileUrl,
          isOffline: true,
        ),
      ),
    );
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
      elevation: 16,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Title and Close Icon
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
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
                      Icons.download_for_offline_rounded,
                      color: RoyalColors.midnightNavy,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Download Resource',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                            color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.resource.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? RoyalColors.champagne : const Color(0xFF4A5568),
                          ),
                          maxLines: 2,
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Divider(
                height: 1,
                color: isDark ? const Color(0x33C5A04A) : const Color(0x26C5A04A),
              ),
              const SizedBox(height: 18),

              if (_isCheckingStatus) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
              ] else ...[
                // Option 1: Download in App
                _buildOptionCard(
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.phone_android_rounded,
                  iconColor: const Color(0xFF10B981),
                  iconBgColor: isDark ? const Color(0xFF064E3B) : const Color(0xFFECFDF5),
                  title: 'Download in App',
                  subtitle: _isAlreadySaved
                      ? 'Already saved offline on this device (${((_savedMetadata?.fileSize ?? 0) / 1024 / 1024).toStringAsFixed(2)} MB).'
                      : 'Store locally for fast in-app offline viewing without internet access.',
                  actionWidget: _isDownloadingInApp
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : (_isAlreadySaved
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                                    side: BorderSide(
                                      color: isDark ? RoyalColors.glassGoldBorder : const Color(0x66C5A04A),
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: _openOfflineViewer,
                                  child: const Text('View Offline', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFDC2626)),
                                  tooltip: 'Remove offline copy',
                                  onPressed: _handleRemoveLocalCopy,
                                ),
                              ],
                            )
                          : FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF10B981),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: _handleDownloadInApp,
                              child: const Text('Save in App', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            )),
                ),
                const SizedBox(height: 12),

                // Option 2: Download to Device
                _buildOptionCard(
                  theme: theme,
                  isDark: isDark,
                  icon: Icons.folder_copy_rounded,
                  iconColor: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                  iconBgColor: isDark ? const Color(0x26C5A04A) : const Color(0x1FC5A04A),
                  title: 'Download to Device',
                  subtitle: kIsWeb
                      ? 'Save to your computer\'s standard browser downloads folder.'
                      : 'Save file directly to your phone storage / Downloads folder.',
                  actionWidget: _isExportingToDevice
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : FilledButton.tonal(
                          style: FilledButton.styleFrom(
                            backgroundColor: isDark ? const Color(0x33C5A04A) : const Color(0x26C5A04A),
                            foregroundColor: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            visualDensity: VisualDensity.compact,
                          ),
                          onPressed: _handleDownloadToDevice,
                          child: const Text('Save File', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required ThemeData theme,
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required Widget actionWidget,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0x66162248) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0x33C5A04A) : const Color(0x26C5A04A),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? RoyalColors.textMutedDark : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          actionWidget,
        ],
      ),
    );
  }
}
