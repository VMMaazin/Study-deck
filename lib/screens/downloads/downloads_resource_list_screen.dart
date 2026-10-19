import 'package:flutter/material.dart';
import 'package:study_deck/core/theme/app_theme.dart';
import 'package:study_deck/models/downloaded_resource_model.dart';
import 'package:study_deck/screens/viewer/pdf_viewer_screen.dart';
import 'package:study_deck/services/offline_storage_service.dart';
import 'package:study_deck/widgets/empty_state_view.dart';
import 'package:study_deck/widgets/responsive_layout.dart';
import 'package:study_deck/widgets/study_deck_app_bar.dart';

/// Screen displaying the locally saved PDF resources for a specific module.
/// Provides offline viewing, device export, and safe local deletion.
class DownloadsResourceListScreen extends StatefulWidget {
  const DownloadsResourceListScreen({
    super.key,
    required this.semesterTitle,
    required this.subjectTitle,
    required this.moduleId,
    required this.moduleTitle,
    required this.resources,
    this.offlineStorageService,
  });

  final String semesterTitle;
  final String subjectTitle;
  final String moduleId;
  final String moduleTitle;
  final List<DownloadedResourceModel> resources;
  final OfflineStorageService? offlineStorageService;

  @override
  State<DownloadsResourceListScreen> createState() => _DownloadsResourceListScreenState();
}

class _DownloadsResourceListScreenState extends State<DownloadsResourceListScreen> {
  late List<DownloadedResourceModel> _items;
  late final OfflineStorageService _storageService;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.resources);
    _storageService = widget.offlineStorageService ?? OfflineStorageService.instance;
  }

  void _openOfflineViewer(DownloadedResourceModel item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(
          title: item.title,
          documentId: item.id,
          fileName: item.fileName,
          fileUrl: item.fileUrl,
          localFilePath: item.localPath,
          isOffline: true,
        ),
      ),
    );
  }

  Future<void> _exportToDevice(DownloadedResourceModel item) async {
    try {
      final bytes = await _storageService.getResourceBytes(item.id);
      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot export: local PDF bytes are missing on this device.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final success = await _storageService.exportToDevice(
        fileName: item.fileName.isNotEmpty ? item.fileName : '${item.title}.pdf',
        bytes: bytes,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Exported "${item.title}" to device successfully.' : 'Device export was cancelled or unconfirmed.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(DownloadedResourceModel item) async {
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
          'Are you sure you want to remove the offline copy of "${item.title}"? '
          'This will only remove the file from this device. The original document in StudyDeck remains unaffected.',
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
      await _storageService.deleteResource(item.id);
      if (mounted) {
        setState(() {
          _items.removeWhere((i) => i.id == item.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed offline copy of "${item.title}".'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: StudyDeckAppBar(
        title: widget.moduleTitle,
        subtitle: '${widget.subjectTitle} • Offline PDFs',
        showBackButton: true,
        showDownloadsButton: false,
      ),
      body: PremiumAnimatedGlassBackground(
        isDark: isDark,
        child: SafeArea(
          child: _items.isEmpty
              ? Center(
                  child: EmptyStateView(
                    icon: Icons.folder_open_rounded,
                    title: 'No Offline Documents Left',
                    message: 'All saved documents in this module have been removed from local storage.',
                    actionLabel: 'Go Back',
                    onActionPressed: () => Navigator.of(context).pop(),
                  ),
                )
              : SingleChildScrollView(
                  child: ResponsiveContainer(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Available Offline',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                            ),
                          ),
                          const SizedBox(height: 14),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _items.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final sizeMb = item.fileSize != null
                                  ? (item.fileSize! / 1024 / 1024).toStringAsFixed(2)
                                  : null;

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
                                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.04),
                                      blurRadius: 12,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(18.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // PDF emblem container
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              color: isDark ? const Color(0x26C5A04A) : const Color(0x14C5A04A),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isDark ? RoyalColors.glassGoldBorder : const Color(0x4DC5A04A),
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.picture_as_pdf_rounded,
                                              color: Color(0xFFDC2626),
                                              size: 24,
                                            ),
                                          ),
                                          const SizedBox(width: 14),

                                          // Metadata
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                      decoration: BoxDecoration(
                                                        color: isDark ? const Color(0x33C5A04A) : const Color(0x1FC5A04A),
                                                        borderRadius: BorderRadius.circular(6),
                                                        border: Border.all(
                                                          color: isDark ? const Color(0x33C5A04A) : const Color(0x26C5A04A),
                                                        ),
                                                      ),
                                                      child: Text(
                                                        item.resourceType.displayName,
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight: FontWeight.w700,
                                                          color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                                        borderRadius: BorderRadius.circular(4),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize: MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.offline_pin_rounded, size: 10, color: Color(0xFF10B981)),
                                                          SizedBox(width: 3),
                                                          Text(
                                                            'Saved Offline',
                                                            style: TextStyle(
                                                              fontSize: 9,
                                                              fontWeight: FontWeight.w700,
                                                              color: Color(0xFF10B981),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  item.title,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 15,
                                                    color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  '${item.fileName.isNotEmpty ? item.fileName : "Document"}${sizeMb != null ? " • $sizeMb MB" : ""}',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: isDark ? RoyalColors.textMutedDark : const Color(0xFF64748B),
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
                                        color: isDark ? const Color(0x26C5A04A) : const Color(0x1AC5A04A),
                                      ),
                                      const SizedBox(height: 12),

                                      // Action row: View Offline, Export to Device, Delete
                                      Row(
                                        children: [
                                          // View Offline PDF
                                          FilledButton.icon(
                                            icon: const Icon(Icons.visibility_rounded, size: 16),
                                            label: const Text('View PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                            style: FilledButton.styleFrom(
                                              backgroundColor: RoyalColors.royalGold,
                                              foregroundColor: RoyalColors.midnightNavy,
                                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            onPressed: () => _openOfflineViewer(item),
                                          ),
                                          const SizedBox(width: 8),

                                          // Export to Device
                                          OutlinedButton.icon(
                                            icon: const Icon(Icons.save_alt_rounded, size: 16),
                                            label: const Text('Export', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                                              side: BorderSide(
                                                color: isDark ? RoyalColors.glassGoldBorder : const Color(0x66C5A04A),
                                              ),
                                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                              visualDensity: VisualDensity.compact,
                                            ),
                                            onPressed: () => _exportToDevice(item),
                                          ),

                                          const Spacer(),

                                          // Remove Local Copy
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFDC2626)),
                                            tooltip: 'Remove offline copy',
                                            onPressed: () => _handleDelete(item),
                                          ),
                                        ],
                                      ),
                                    ],
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
