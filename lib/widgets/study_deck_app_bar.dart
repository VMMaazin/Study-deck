import 'package:flutter/material.dart';
import 'package:study_deck/core/constants/app_constants.dart';
import 'package:study_deck/core/session/admin_session.dart';
import 'package:study_deck/core/theme/app_theme.dart';
import 'package:study_deck/core/theme/theme_controller.dart';
import 'package:study_deck/screens/downloads/downloads_semester_screen.dart';
import 'package:study_deck/widgets/admin_login_dialog.dart';

/// Unified app bar providing consistent branding and admin sign-in/sign-out controls
/// across all screens.
class StudyDeckAppBar extends StatelessWidget implements PreferredSizeWidget {
  const StudyDeckAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.bottom,
    this.showBackButton = false,
    this.showDownloadsButton = true,
    this.onBack,
  });

  final String? title;
  final String? subtitle;
  final PreferredSizeWidget? bottom;
  final bool showBackButton;
  final bool showDownloadsButton;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final session = AdminSessionScope.of(context);
    final canPop = showBackButton || Navigator.of(context).canPop();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isNarrow = screenWidth < 400;

    return AppBar(
      backgroundColor: isDark
          ? const Color(0xE60A1124)
          : const Color(0xF2F7F3E9),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      titleSpacing: canPop ? (isNarrow ? 4.0 : 8.0) : NavigationToolbar.kMiddleSpacing,
      leading: canPop
          ? IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 18,
                color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
              ),
              tooltip: 'Back',
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: title != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title!,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isNarrow ? 15 : 16,
                    color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: isNarrow ? 10 : 11,
                      fontWeight: FontWeight.normal,
                      color: isDark
                          ? RoyalColors.champagne.withValues(alpha: 0.8)
                          : const Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: RoyalGradients.metallicGold,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: RoyalColors.royalGold.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_stories_rounded,
                    size: 18,
                    color: RoyalColors.midnightNavy,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  AppConstants.appName,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                    letterSpacing: -0.3,
                    color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                  ),
                ),
              ],
            ),
      actions: [
        if (session.isAdmin) ...[
          // Active Admin status badge with royal styling
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            padding: EdgeInsets.symmetric(
              horizontal: isNarrow ? 6 : 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x33C5A04A) : const Color(0x26C5A04A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? RoyalColors.glassGoldBorder : const Color(0xFFC5A04A),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  'Admin',
                  style: TextStyle(
                    fontSize: isNarrow ? 10 : 12,
                    fontWeight: FontWeight.w700,
                    color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: isNarrow ? 2 : 6),
          // Clear logout action
          IconButton(
            tooltip: 'Sign Out Admin',
            visualDensity: isNarrow ? VisualDensity.compact : VisualDensity.standard,
            icon: Icon(
              Icons.logout_rounded,
              size: isNarrow ? 18 : 20,
              color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: isDark ? RoyalColors.midnightNavySurface : RoyalColors.pearlWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: BorderSide(
                      color: isDark ? RoyalColors.glassGoldBorder : const Color(0x33C5A04A),
                    ),
                  ),
                  title: Text(
                    'Exit Admin Mode?',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                    ),
                  ),
                  content: Text(
                    'You will be returned to normal student mode.',
                    style: TextStyle(
                      color: isDark ? RoyalColors.textMutedDark : const Color(0xFF4A5568),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? RoyalColors.champagne : const Color(0xFF64748B),
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
                      child: const Text('Sign Out'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await session.signOut();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Signed out. Student mode active.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ] else ...[
          // Responsive Admin Login button: compact icon on narrow screens, labeled button on wider screens
          if (isNarrow)
            IconButton(
              tooltip: 'Admin Login',
              visualDensity: VisualDensity.compact,
              icon: Icon(
                Icons.admin_panel_settings_outlined,
                size: 20,
                color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
              ),
              onPressed: () => AdminLoginDialog.show(context),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: OutlinedButton.icon(
                icon: Icon(
                  Icons.admin_panel_settings_outlined,
                  size: 16,
                  color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                ),
                label: Text(
                  'Admin Login',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? RoyalColors.champagne : RoyalColors.midnightNavy,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(
                    color: isDark ? RoyalColors.glassGoldBorder : const Color(0x66C5A04A),
                    width: 1.2,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => AdminLoginDialog.show(context),
              ),
            ),
        ],
        if (showDownloadsButton) ...[
          IconButton(
            tooltip: 'Offline Downloads',
            visualDensity: isNarrow ? VisualDensity.compact : VisualDensity.standard,
            icon: Icon(
              Icons.download_for_offline_rounded,
              size: isNarrow ? 20 : 22,
              color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
            ),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const DownloadsSemesterScreen(),
                ),
              );
            },
          ),
        ],
        // Sun/Moon theme toggle button
        IconButton(
          tooltip: isDark ? 'Switch to Light Theme' : 'Switch to Dark Theme',
          visualDensity: isNarrow ? VisualDensity.compact : VisualDensity.standard,
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: isNarrow ? 18 : 20,
            color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
          ),
          onPressed: () {
            ThemeScope.of(context).toggleTheme();
          },
        ),
        SizedBox(width: isNarrow ? 4 : 8),
      ],
      bottom: bottom,
    );
  }
}
