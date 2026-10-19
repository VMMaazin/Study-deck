import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:study_deck/core/constants/app_constants.dart';
import 'package:study_deck/core/theme/royal_design_system.dart';
import 'package:study_deck/screens/student/student_home_screen.dart';
import 'package:study_deck/services/academic_service.dart';

/// A premium animated welcome intro screen for StudyDeck featuring the official
/// study owl mascot. Inspired by the playful personality and delightful motion of
/// modern apps, crafted natively with Flutter animation curves, royal gold accents,
/// and midnight-navy aesthetics.
class WelcomeIntroScreen extends StatefulWidget {
  const WelcomeIntroScreen({
    super.key,
    this.academicService,
    this.onFinished,
    this.duration = const Duration(milliseconds: 1600),
  });

  final AcademicService? academicService;
  final VoidCallback? onFinished;
  final Duration duration;

  @override
  State<WelcomeIntroScreen> createState() => _WelcomeIntroScreenState();
}

class _WelcomeIntroScreenState extends State<WelcomeIntroScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Owl flight & character animations
  late final Animation<double> _owlEntryX;
  late final Animation<double> _owlEntryY;
  late final Animation<double> _owlRotation;
  late final Animation<double> _owlScale;

  // Welcome text animations
  late final Animation<double> _titleOpacity;
  late final Animation<Offset> _titleSlide;
  late final Animation<double> _subtitleOpacity;
  late final Animation<Offset> _subtitleSlide;

  // Ambient gold glow & settle animations
  late final Animation<double> _glowPulse;
  late final Animation<double> _settleShimmer;

  Timer? _safetyTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    // 1. Owl Curved Entry Animation (0.0 -> 0.60)
    // Horizontal sweep from offscreen left into center
    _owlEntryX = Tween<double>(
      begin: -1.8,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.58, curve: Curves.easeOutCubic),
      ),
    );

    // Vertical swoop: glides slightly down then bobs up gracefully into place
    _owlEntryY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -45.0, end: 18.0)
            .chain(CurveTween(curve: Curves.easeInQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 18.0, end: -8.0)
            .chain(CurveTween(curve: Curves.easeOutQuad)),
        weight: 35,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -8.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeInOutSine)),
        weight: 30,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65),
      ),
    );

    // Rotation: gentle banking turn during flight that rebounds and levels
    _owlRotation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.16, end: 0.08)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.08, end: -0.03)
            .chain(CurveTween(curve: Curves.easeInOutQuad)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.03, end: 0.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 25,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.72),
      ),
    );

    // Scale / Bounce: slight expansion on landing for character squash-and-stretch
    _owlScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.82, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.06, end: 0.98)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.98, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.78),
      ),
    );

    // 2. Title Reveal: "Welcome to StudyDeck" (0.32 -> 0.70)
    _titleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.32, 0.62, curve: Curves.easeOut),
    );
    _titleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.35),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.32, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    // 3. Subtitle Reveal: "All the best for your studies!" (0.50 -> 0.88)
    _subtitleOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 0.80, curve: Curves.easeOut),
    );
    _subtitleSlide = Tween<Offset>(
      begin: const Offset(0.0, 0.40),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    // 4. Subtle ambient gold glow and settle shimmer (0.60 -> 1.0)
    _glowPulse = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.40, 0.95, curve: Curves.easeInOut),
      ),
    );
    _settleShimmer = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.80, 1.0, curve: Curves.easeOut),
    );

    // Transition on completion
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _navigateToHome();
      }
    });

    // Run animation or handle reduced motion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final reduceMotion =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduceMotion) {
        _controller.value = 1.0;
        _navigateToHome();
      } else {
        _controller.forward();
      }
    });

    // Safety fallback timer to prevent infinite blocking under any circumstance
    _safetyTimer = Timer(widget.duration + const Duration(milliseconds: 600), () {
      if (mounted && !_hasNavigated) {
        _navigateToHome();
      }
    });
  }

  @override
  void dispose() {
    _safetyTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    _safetyTimer?.cancel();

    if (widget.onFinished != null) {
      widget.onFinished!();
      return;
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            StudentHomeScreen(academicService: widget.academicService),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOut,
            ),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    final bgColor = isDark
        ? RoyalColors.midnightNavyDark
        : RoyalColors.warmIvory;

    return Scaffold(
      backgroundColor: bgColor,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _navigateToHome, // Tap anywhere to skip immediately
        child: Stack(
          children: [
            // Ambient subtle background gradient
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? const RadialGradient(
                          center: Alignment(0.0, -0.15),
                          radius: 1.1,
                          colors: [
                            Color(0xFF162550),
                            Color(0xFF101B3B),
                            Color(0xFF090F22),
                          ],
                        )
                      : const RadialGradient(
                          center: Alignment(0.0, -0.15),
                          radius: 1.1,
                          colors: [
                            Color(0xFFFFFFFF),
                            Color(0xFFFAF7F0),
                            Color(0xFFF7F3E9),
                          ],
                        ),
                ),
              ),
            ),

            // Top-right accessible "Skip" action
            Positioned(
              top: MediaQuery.of(context).padding.top + 12,
              right: 16,
              child: AnimatedBuilder(
                animation: _titleOpacity,
                builder: (context, child) {
                  return Opacity(
                    opacity: _titleOpacity.value.clamp(0.0, 1.0),
                    child: child,
                  );
                },
                child: TextButton.icon(
                  onPressed: _navigateToHome,
                  style: TextButton.styleFrom(
                    foregroundColor: isDark
                        ? RoyalColors.champagne
                        : RoyalColors.antiqueGold,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text(
                    'Skip',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),

            // Center content area
            Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Mascot Stage
                      SizedBox(
                        width: math.min(size.width * 0.85, 320),
                        height: 230,
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, child) {
                            final double xTranslation =
                                _owlEntryX.value * (size.width * 0.5 + 160);
                            final double yTranslation = _owlEntryY.value;
                            final double rotation = _owlRotation.value;
                            final double scale = _owlScale.value;

                            return Transform.translate(
                              offset: Offset(xTranslation, yTranslation),
                              child: Transform.rotate(
                                angle: rotation,
                                child: Transform.scale(
                                  scale: scale,
                                  child: child,
                                ),
                              ),
                            );
                          },
                          child: _buildMascotAvatar(isDark),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Welcome Title: "Welcome to StudyDeck"
                      SlideTransition(
                        position: _titleSlide,
                        child: FadeTransition(
                          opacity: _titleOpacity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Small royal badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? RoyalColors.glassGoldFill
                                      : const Color(0x1FC5A04A),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isDark
                                        ? RoyalColors.glassGoldBorder
                                        : const Color(0x66C5A04A),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 13,
                                      color: RoyalColors.royalGold,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'OFFICIAL ACADEMIC COMPANION',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                        color: isDark
                                            ? RoyalColors.champagne
                                            : RoyalColors.antiqueGold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Main headline
                              Text.rich(
                                TextSpan(
                                  style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 27,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.4,
                                    color: isDark
                                        ? RoyalColors.pearlWhite
                                        : RoyalColors.textNavy,
                                  ),
                                  children: const [
                                    TextSpan(text: 'Welcome to '),
                                    TextSpan(
                                      text: 'StudyDeck',
                                      style: TextStyle(
                                        color: RoyalColors.royalGold,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Subtitle: "All the best for your studies!"
                      SlideTransition(
                        position: _subtitleSlide,
                        child: FadeTransition(
                          opacity: _subtitleOpacity,
                          child: AnimatedBuilder(
                            animation: _settleShimmer,
                            builder: (context, child) {
                              return Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.menu_book_rounded,
                                    size: 16,
                                    color: isDark
                                        ? RoyalColors.champagne
                                        : RoyalColors.antiqueGold,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'All the best for your studies!',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.2,
                                      color: isDark
                                          ? RoyalColors.textChampagne
                                          : RoyalColors.textNavyMuted,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the owl mascot avatar with soft golden glow, squircle framing,
  /// and graceful fallback if asset loading is ever impeded.
  Widget _buildMascotAvatar(bool isDark) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Ambient soft radial gold glow
          AnimatedBuilder(
            animation: _glowPulse,
            builder: (context, _) {
              final double glow = _glowPulse.value;
              return Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: RoyalColors.royalGold.withValues(
                        alpha: (isDark ? 0.28 : 0.18) * glow,
                      ),
                      blurRadius: 36 * glow + 4,
                      spreadRadius: 8 * glow,
                    ),
                  ],
                ),
              );
            },
          ),

          // Mascot illustration container
          Container(
            width: 175,
            height: 175,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              border: Border.all(
                color: isDark
                    ? RoyalColors.glassGoldBorder
                    : const Color(0x66C5A04A),
                width: 2,
              ),
              boxShadow: isDark
                  ? RoyalShadows.midnightAmbient
                  : RoyalShadows.subtleCard,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: Image.asset(
                AppConstants.owlMascotAsset,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  // Fallback: try solid asset or styled vector avatar
                  return Image.asset(
                    AppConstants.owlMascotSolidAsset,
                    fit: BoxFit.contain,
                    errorBuilder: (context, fallbackError, fallbackStackTrace) {
                      return Container(
                        color: isDark
                            ? RoyalColors.midnightNavySurface
                            : RoyalColors.creamCard,
                        child: const Icon(
                          Icons.school_rounded,
                          size: 72,
                          color: RoyalColors.royalGold,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
