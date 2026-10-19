import 'dart:ui';
import 'package:flutter/material.dart';

/// Royal, elegant, and sophisticated color palette for StudyDeck.
/// Inspired strictly by deep royal midnight navy, antique metallic gold,
/// warm ivory, and pearl white.
class RoyalColors {
  RoyalColors._();

  // Midnight Navy Spectrum
  static const Color midnightNavy = Color(0xFF101B3B); // Deep royal midnight navy
  static const Color midnightNavyDark = Color(0xFF090F22); // Deepest abyss background
  static const Color midnightNavySurface = Color(0xFF162248); // Card/surface on navy
  static const Color midnightNavySubtle = Color(0xFF1D2C5A); // Elevated layer

  // Royal & Antique Gold Spectrum
  static const Color royalGold = Color(0xFFC5A04A); // Signature antique gold
  static const Color antiqueGold = Color(0xFFA88434); // Deep burnished gold
  static const Color metallicGold = Color(0xFFD4AF37); // Luminous metallic gold
  static const Color lightGold = Color(0xFFDFBE6E); // Soft gold highlight
  static const Color champagne = Color(0xFFE5CCA0); // Refined champagne tint
  static const Color champagneLight = Color(0xFFF3EBD8); // Frosted champagne veil
  static const Color paleGold = Color(0xFFFAF4E6); // Delicate gold container

  // Warm Ivory & Pearl White Spectrum
  static const Color warmIvory = Color(0xFFF7F3E9); // Primary warm ivory background
  static const Color creamCard = Color(0xFFFAF7F0); // Subtle cream surface
  static const Color pearlWhite = Color(0xFFFFFFFF); // Pure pearl white
  static const Color ivoryBorder = Color(0xFFE6DFC9); // Delicate warm ivory border
  static const Color ivoryBorderSubtle = Color(0xFFEEE8D8);

  // Typography Palette
  static const Color textNavy = Color(0xFF101B3B); // Primary text on light surfaces
  static const Color textNavyMuted = Color(0xFF4A5568); // Secondary text on light surfaces
  static const Color textNavySubtle = Color(0xFF718096); // Tertiary text on light surfaces
  static const Color textWhite = Color(0xFFFFFFFF); // Primary text on navy
  static const Color textChampagne = Color(0xFFE5CCA0); // Golden text on navy
  static const Color textMutedDark = Color(0xFFB8C2D8); // Subdued text on navy

  // Glassmorphism Transparency Tokens
  static const Color glassWhite = Color(0x1AFFFFFF); // 10% translucent white
  static const Color glassWhiteDense = Color(0x33FFFFFF); // 20% frosted white
  static const Color glassNavy = Color(0xB3101B3B); // 70% midnight navy
  static const Color glassNavyDense = Color(0xE6101B3B); // 90% midnight navy
  static const Color glassGoldFill = Color(0x1AC5A04A); // 10% gold glow
  static const Color glassGoldBorder = Color(0x59C5A04A); // 35% antique gold rim
  static const Color glassWhiteBorder = Color(0x33FFFFFF); // 20% pearl rim
}

/// Curated gradient definitions for metallic gold, royal navy, and liquid glass.
class RoyalGradients {
  RoyalGradients._();

  /// Rich metallic gold linear gradient for badges, emblems, and borders.
  static const LinearGradient metallicGold = LinearGradient(
    colors: [
      Color(0xFFE5CCA0), // Champagne highlight
      Color(0xFFC5A04A), // Signature gold
      Color(0xFFA88434), // Antique gold
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Luminous gold sheen for fine borders and interactive rims.
  static const LinearGradient goldBorderGradient = LinearGradient(
    colors: [
      Color(0x99DFBE6E),
      Color(0x4DC5A04A),
      Color(0x99A88434),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Deep midnight navy hero gradient with layered atmospheric depth.
  static const LinearGradient midnightHero = LinearGradient(
    colors: [
      Color(0xFF0A1124),
      Color(0xFF101B3B),
      Color(0xFF162550),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Subtle ivory-to-cream gradient for student cards.
  static const LinearGradient ivoryCard = LinearGradient(
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFFAF7F0),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Translucent liquid glass highlight gradient.
  static const LinearGradient liquidGlassLight = LinearGradient(
    colors: [
      Color(0x38FFFFFF),
      Color(0x12FFFFFF),
      Color(0x05FFFFFF),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Liquid glass button gradient with champagne tint.
  static const LinearGradient liquidGlassGold = LinearGradient(
    colors: [
      Color(0x33E5CCA0),
      Color(0x1AC5A04A),
      Color(0x0FA88434),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Refined shadow tokens providing gentle, ambient depth without clutter.
class RoyalShadows {
  RoyalShadows._();

  /// Soft metallic gold glow for active/hovered elements.
  static const List<BoxShadow> goldGlow = [
    BoxShadow(
      color: Color(0x2BC5A04A),
      blurRadius: 20,
      spreadRadius: -2,
      offset: Offset(0, 8),
    ),
  ];

  /// Deep midnight ambient shadow for large hero cards.
  static const List<BoxShadow> midnightAmbient = [
    BoxShadow(
      color: Color(0x33090F22),
      blurRadius: 30,
      offset: Offset(0, 14),
    ),
    BoxShadow(
      color: Color(0x1AC5A04A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  /// Subtle card shadow for ivory surfaces.
  static const List<BoxShadow> subtleCard = [
    BoxShadow(
      color: Color(0x0A101B3B),
      blurRadius: 16,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x05C5A04A),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Liquid glass button elevation shadow.
  static const List<BoxShadow> glassButton = [
    BoxShadow(
      color: Color(0x1A101B3B),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}

/// Reusable frosted glass container with optional backdrop blur,
/// delicate border, and inner glossy highlight.
class RoyalGlassContainer extends StatelessWidget {
  const RoyalGlassContainer({
    super.key,
    required this.child,
    this.borderRadius = 18.0,
    this.padding = const EdgeInsets.all(16.0),
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.blurSigma = 12.0,
    this.boxShadow,
    this.gradient,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double blurSigma;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderColor = borderColor ?? RoyalColors.glassGoldBorder;
    final effectiveBgColor = backgroundColor ?? RoyalColors.glassWhite;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: boxShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: effectiveBgColor,
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: effectiveBorderColor,
                width: borderWidth,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Liquid-glass-inspired interactive button with translucent fill,
/// subtle glossy highlight, and refined hover/tap states.
class RoyalLiquidGlassButton extends StatefulWidget {
  const RoyalLiquidGlassButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isGold = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
    this.borderRadius = 12.0,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isGold;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  State<RoyalLiquidGlassButton> createState() => _RoyalLiquidGlassButtonState();
}

class _RoyalLiquidGlassButtonState extends State<RoyalLiquidGlassButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final baseBorder = widget.isGold
        ? (_isHovered
            ? (isDark ? RoyalColors.royalGold : const Color(0xFF8A6715))
            : (isDark ? RoyalColors.glassGoldBorder : const Color(0xFFC5A04A)))
        : (_isHovered
            ? (isDark ? RoyalColors.pearlWhite : const Color(0xFF0B1120))
            : (isDark ? RoyalColors.glassWhiteBorder : const Color(0x33000000)));

    final baseFill = widget.isGold
        ? (isDark
            ? (_isHovered ? const Color(0x33C5A04A) : const Color(0x1AC5A04A))
            : (_isHovered ? const Color(0x26C5A04A) : const Color(0x14C5A04A)))
        : (isDark
            ? (_isHovered ? const Color(0x33FFFFFF) : const Color(0x1AFFFFFF))
            : (_isHovered ? const Color(0x1A000000) : const Color(0x0D000000)));

    final textColor = widget.isGold
        ? (isDark
            ? (_isHovered ? RoyalColors.pearlWhite : RoyalColors.champagne)
            : (_isHovered ? const Color(0xFF000000) : const Color(0xFF0B1120)))
        : (isDark ? RoyalColors.pearlWhite : const Color(0xFF0B1120));

    final iconColor = widget.isGold && !isDark
        ? (_isHovered ? const Color(0xFF8A6715) : const Color(0xFF0B1120))
        : textColor;

    final shadow = _isHovered
        ? (isDark
            ? RoyalShadows.goldGlow
            : [
                BoxShadow(
                  color: const Color(0xFFC5A04A).withValues(alpha: 0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 3),
                )
              ])
        : (isDark
            ? RoyalShadows.glassButton
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                )
              ]);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _isPressed ? 0.97 : (_isHovered ? 1.02 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: widget.padding,
            decoration: BoxDecoration(
              color: baseFill,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(color: baseBorder, width: 1.2),
              boxShadow: shadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 16,
                    color: iconColor,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A classy, animated credit widget showcasing "Developed by : HAMDAN"
/// with a continuous golden shimmer sweep and ambient pulsating glow.
class ClassyAnimatedCredit extends StatefulWidget {
  const ClassyAnimatedCredit({
    super.key,
    this.fontSize = 13.0,
    this.compact = false,
  });

  final double fontSize;
  final bool compact;

  @override
  State<ClassyAnimatedCredit> createState() => _ClassyAnimatedCreditState();
}

class _ClassyAnimatedCreditState extends State<ClassyAnimatedCredit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    final isTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('Test');
    if (!isTest) {
      _shimmerController.repeat();
    } else {
      _shimmerController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final pillBg = isDark
        ? (_isHovered ? const Color(0x33101B3B) : const Color(0x1F101B3B))
        : (_isHovered ? const Color(0x1A0B1120) : const Color(0x0F0B1120));

    final borderColor = isDark
        ? Color.lerp(
            const Color(0x4DC5A04A),
            const Color(0xFFD4AF37),
            ((_shimmerController.value * 2 - 1).abs()),
          )!
        : Color.lerp(
            const Color(0xFFB8860B),
            const Color(0xFF8A6715),
            ((_shimmerController.value * 2 - 1).abs()),
          )!;

    final glowColor = isDark
        ? const Color(0xFFC5A04A).withValues(
            alpha: _isHovered ? 0.35 : 0.18,
          )
        : const Color(0xFF8A6715).withValues(
            alpha: _isHovered ? 0.22 : 0.10,
          );

    final iconColor = isDark ? const Color(0xFFD4AF37) : const Color(0xFF8A6715);

    final shimmerColors = isDark
        ? const [
            Color(0xFFE5CCA0), // Champagne
            Color(0xFFFFFFFF), // Pure Pearl Shine
            Color(0xFFFFDF78), // Rich Gold
            Color(0xFFC5A04A), // Antique Gold
            Color(0xFFE5CCA0), // Champagne
          ]
        : const [
            Color(0xFF0B1120), // Deep Midnight Navy (high-contrast legibility)
            Color(0xFF8A6715), // Rich Antique Gold
            Color(0xFF0B1120), // Deep Midnight Navy
            Color(0xFF8A6715), // Rich Antique Gold
            Color(0xFF0B1120), // Deep Midnight Navy
          ];

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.basic,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          final animValue = _shimmerController.value;

          return Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 14 : 20,
              vertical: widget.compact ? 6 : 9,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: pillBg,
              border: Border.all(
                color: borderColor,
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: glowColor,
                  blurRadius: _isHovered ? 20 : 12,
                  spreadRadius: _isHovered ? 1 : 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Classy Animated Sparkle Emblem
                    Transform.rotate(
                      angle: animValue * 0.4 - 0.2,
                      child: Icon(
                        Icons.auto_awesome,
                        size: widget.fontSize + 2,
                        color: iconColor,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Shimmering Golden Typography with theme-adaptive contrast
                    ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: shimmerColors,
                          stops: [
                            0.0,
                            (animValue - 0.15).clamp(0.0, 1.0),
                            animValue,
                            (animValue + 0.15).clamp(0.0, 1.0),
                            1.0,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ).createShader(bounds);
                      },
                      child: Text(
                        'Developed by : HAMDAN',
                        style: TextStyle(
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Ambient secondary sparkle
                    Icon(
                      Icons.star_rounded,
                      size: widget.fontSize - 1,
                      color: iconColor.withValues(alpha: 0.8),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// An interactive, futuristic liquid-glass search bar with frosted blur,
/// glowing specular outline, and dynamic focus state.
class LiquidGlassSearchBar extends StatefulWidget {
  const LiquidGlassSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.onClear,
    this.onSubmitted,
    this.focusNode,
    this.isDark = true,
    this.isLoading = false,
    this.hintText = "Search for notes...",
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final ValueChanged<String>? onSubmitted;
  final FocusNode? focusNode;
  final bool isDark;
  final bool isLoading;
  final String hintText;

  @override
  State<LiquidGlassSearchBar> createState() => _LiquidGlassSearchBarState();
}

class _LiquidGlassSearchBarState extends State<LiquidGlassSearchBar> {
  late final FocusNode _internalFocusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? _internalFocusNode;

  bool _isFocused = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _internalFocusNode = FocusNode();
    _effectiveFocusNode.addListener(_handleFocusChanged);
  }

  void _handleFocusChanged() {
    setState(() => _isFocused = _effectiveFocusNode.hasFocus);
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_handleFocusChanged);
    _internalFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = _isFocused || _isHovered;
    final isDark = widget.isDark;

    final bgColor = isDark
        ? (active ? const Color(0xE60D152A) : const Color(0xCC0B1120))
        : (active ? const Color(0xF2FFFFFF) : const Color(0xD9FFFFFF));

    final borderColor = active
        ? (isDark ? const Color(0xFFC5A04A) : const Color(0xFFC5A04A))
        : (isDark ? const Color(0x33C5A04A) : const Color(0x40C5A04A));

    final textColor = isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy;
    final hintColor = isDark ? const Color(0xFF6B7A90) : const Color(0xFF7A8A9E);
    final iconColor = active
        ? const Color(0xFFD4AF37)
        : (isDark ? const Color(0xFF8A99AD) : const Color(0xFF7A8A9E));

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: bgColor,
          border: Border.all(
            color: borderColor,
            width: active ? 1.4 : 1.0,
          ),
          boxShadow: [
            if (active)
              BoxShadow(
                color: const Color(0xFFC5A04A).withValues(alpha: isDark ? 0.25 : 0.18),
                blurRadius: 18,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              )
            else if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: iconColor,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      focusNode: _effectiveFocusNode,
                      controller: widget.controller,
                      onChanged: widget.onChanged,
                      onSubmitted: widget.onSubmitted,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: const Color(0xFFD4AF37),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: widget.hintText,
                        hintStyle: TextStyle(
                          color: hintColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  if (widget.isLoading) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFFD4AF37),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (widget.controller.text.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: isDark ? const Color(0xFF8A99AD) : const Color(0xFF7A8A9E),
                      ),
                      onPressed: () {
                        widget.controller.clear();
                        widget.onChanged('');
                        widget.onClear?.call();
                      },
                      splashRadius: 18,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

