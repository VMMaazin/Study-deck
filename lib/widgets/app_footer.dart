import 'package:flutter/material.dart';
import 'package:study_deck/core/constants/app_constants.dart';
import 'package:study_deck/core/theme/app_theme.dart';
import 'package:study_deck/screens/admin/admin_login_screen.dart';

/// Application footer for StudyDeck displaying open-access notice
/// and a discreet portal access for administrators.
class AppFooter extends StatelessWidget {
  const AppFooter({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(top: 40.0, bottom: 24.0),
      child: Column(
        children: [
          Divider(
            color: isDark ? AppColors.slateBorderDark : AppColors.slateBorder,
            height: 1,
          ),
          const SizedBox(height: 20),
          // Classy Creator Credit Line
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x1FC5A04A) : const Color(0x14C5A04A),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0x4DC5A04A),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.auto_awesome,
                  size: 14,
                  color: Color(0xFFD4AF37),
                ),
                const SizedBox(width: 8),
                Text(
                  'Developed by : HAMDAN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: isDark ? const Color(0xFFE5CCA0) : const Color(0xFFA88434),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_open_rounded,
                size: 14,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
              const SizedBox(width: 6),
              Text(
                'Public Academic Hub • Open Access',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Open Student Access — No Login Required',
            style: theme.textTheme.labelSmall?.copyWith(
              color: isDark
                  ? AppColors.textSecondaryDark.withValues(alpha: 0.8)
                  : AppColors.textSecondaryLight.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppConstants.appName,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark.withValues(alpha: 0.7)
                      : AppColors.textSecondaryLight.withValues(alpha: 0.7),
                ),
              ),
              Text(
                ' • ',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark.withValues(alpha: 0.7)
                      : AppColors.textSecondaryLight.withValues(alpha: 0.7),
                ),
              ),
              Text(
                AppConstants.appTagline,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark
                      ? AppColors.textSecondaryDark.withValues(alpha: 0.7)
                      : AppColors.textSecondaryLight.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Discreet Admin Portal entry point
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminLoginScreen(),
                ),
              );
            },
            icon: Icon(
              Icons.admin_panel_settings_outlined,
              size: 15,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
            label: Text(
              'Admin Portal',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                decoration: TextDecoration.underline,
              ),
            ),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
