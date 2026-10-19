import 'package:flutter/material.dart';
import 'package:study_deck/core/constants/app_constants.dart';
import 'package:study_deck/core/theme/app_theme.dart';
import 'package:study_deck/widgets/responsive_layout.dart';

/// The foundational overview screen for StudyDeck with royal styling.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: PremiumAnimatedGlassBackground(
        isDark: isDark,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              child: ResponsiveContainer(
                maxWidth: 600,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Royal App Icon Emblem
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDark
                              ? [
                                  AppColors.royalGold.withValues(alpha: 0.35),
                                  AppColors.deepNavy,
                                ]
                              : [
                                  AppColors.goldLight.withValues(alpha: 0.4),
                                  AppColors.royalGold.withValues(alpha: 0.2),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.royalGold.withValues(alpha: 0.6),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.royalGold.withValues(alpha: 0.25),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.style_rounded,
                        size: 44,
                        color: AppColors.royalGold,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Foundation Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.deepNavy.withValues(alpha: 0.7)
                            : AppColors.warmIvory,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.royalGold.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.royalGold,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Academic Deck Ready',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                              color: isDark
                                  ? AppColors.champagne
                                  : AppColors.deepNavy,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Application Name
                    Text(
                      AppConstants.appName,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark
                            ? AppColors.warmIvory
                            : AppColors.deepNavy,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Tagline
                    Text(
                      AppConstants.appTagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 36),

                    // Overview Information Card
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.midnightNavy.withValues(alpha: 0.8)
                            : AppColors.pearlWhite.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: AppColors.royalGold.withValues(alpha: isDark ? 0.3 : 0.4),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.4)
                                : AppColors.deepNavy.withValues(alpha: 0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.hub_rounded,
                                size: 20,
                                color: AppColors.royalGold,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Cross-Platform Academic Deck',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? AppColors.warmIvory : AppColors.deepNavy,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'StudyDeck connects college students to verified academic resources — including lecture notes, previous-year question papers, and assignments — with a seamless experience across all your devices.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Divider(
                            height: 1,
                            color: AppColors.royalGold.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 16),
                          const Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _PlatformBadge(
                                icon: Icons.android_rounded,
                                label: 'Android APK',
                              ),
                              _PlatformBadge(
                                icon: Icons.language_rounded,
                                label: 'Web Browser',
                              ),
                              _PlatformBadge(
                                icon: Icons.apple_rounded,
                                label: 'iOS Ready',
                              ),
                            ],
                          ),
                        ],
                      ),
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

class _PlatformBadge extends StatelessWidget {
  const _PlatformBadge({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.deepNavy.withValues(alpha: 0.5)
            : AppColors.warmIvory,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.royalGold.withValues(alpha: isDark ? 0.3 : 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.royalGold,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.warmIvory
                  : AppColors.deepNavy,
            ),
          ),
        ],
      ),
    );
  }
}
