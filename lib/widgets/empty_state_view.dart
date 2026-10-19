import 'package:flutter/material.dart';
import 'package:study_deck/core/theme/royal_design_system.dart';

/// A reusable, aesthetically pleasing empty state widget for StudyDeck.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryGold = isDark ? RoyalColors.royalGold : const Color(0xFF8A6715);
    final borderColor = isDark ? RoyalColors.glassGoldBorder : const Color(0xFFC5A04A);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0x26C5A04A)
                    : const Color(0x1FC5A04A),
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.2),
              ),
              child: Icon(
                icon,
                size: 36,
                color: primaryGold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark
                    ? RoyalColors.pearlWhite
                    : RoyalColors.midnightNavy,
              ),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: isDark
                      ? const Color(0xFF8A99AD)
                      : const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onActionPressed,
                icon: Icon(Icons.refresh_rounded, size: 18, color: primaryGold),
                label: Text(actionLabel!),
                style: OutlinedButton.styleFrom(
                  foregroundColor: isDark
                      ? RoyalColors.pearlWhite
                      : RoyalColors.midnightNavy,
                  side: BorderSide(color: borderColor, width: 1.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
