import 'package:flutter/material.dart';
import 'package:study_deck/core/constants/app_constants.dart';

/// A utility widget that provides responsive padding and constraints
/// suitable for both mobile screens and wide desktop/web displays.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = AppConstants.maxContentWidth,
    this.padding,
  });

  /// The child widget to be rendered inside the responsive container.
  final Widget child;

  /// The maximum logical width allowed for the content.
  final double maxWidth;

  /// Optional custom padding; if null, defaults to responsive adaptive padding.
  final EdgeInsetsGeometry? padding;

  /// Determines if the current screen width is considered mobile.
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < AppConstants.mobileBreakpoint;

  /// Determines if the current screen width is considered tablet.
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= AppConstants.mobileBreakpoint &&
        width < AppConstants.desktopBreakpoint;
  }

  /// Determines if the current screen width is considered desktop.
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= AppConstants.desktopBreakpoint;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final defaultHorizontalPadding = screenWidth < AppConstants.mobileBreakpoint
        ? 20.0
        : 32.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(
                horizontal: defaultHorizontalPadding,
                vertical: 24.0,
              ),
          child: child,
        ),
      ),
    );
  }
}
