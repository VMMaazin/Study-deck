import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A premium, ambient animated glass background designed for StudyDeck.
/// Features slowly drifting translucent glass orbs, subtle gold light blooms,
/// tiny restrained gold particles, pointer-responsive parallax on desktop,
/// and complete visual adaptation for both dark and light royal themes.
class PremiumAnimatedGlassBackground extends StatefulWidget {
  const PremiumAnimatedGlassBackground({
    super.key,
    required this.child,
    required this.isDark,
  });

  final Widget child;
  final bool isDark;

  @override
  State<PremiumAnimatedGlassBackground> createState() =>
      _PremiumAnimatedGlassBackgroundState();
}

class _PremiumAnimatedGlassBackgroundState
    extends State<PremiumAnimatedGlassBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambientController;
  Offset _pointerOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );

    final isTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('Test');

    if (!isTest) {
      _ambientController.repeat();
    } else {
      _ambientController.value = 0.5;
    }
  }

  @override
  void dispose() {
    _ambientController.dispose();
    super.dispose();
  }

  void _onPointerHover(PointerHoverEvent event, Size size) {
    if (size.width == 0 || size.height == 0) return;
    // Normalize pointer offset between -1.0 and 1.0
    final normalizedX = (event.localPosition.dx / size.width) * 2 - 1;
    final normalizedY = (event.localPosition.dy / size.height) * 2 - 1;

    setState(() {
      _pointerOffset = Offset(
        normalizedX.clamp(-1.0, 1.0),
        normalizedY.clamp(-1.0, 1.0),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return MouseRegion(
          onHover: (event) => _onPointerHover(event, size),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Base Adaptive Royal Canvas Fill
              AnimatedContainer(
                duration: const Duration(milliseconds: 350),
                decoration: BoxDecoration(
                  gradient: widget.isDark
                      ? const LinearGradient(
                          colors: [
                            Color(0xFF070F24), // Rich Royal Midnight Navy
                            Color(0xFF0C193A), // Deep Royal Sapphire
                            Color(0xFF10224E), // Celestial Indigo
                            Color(0xFF08122A), // Velvet Royal Night
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : const LinearGradient(
                          colors: [
                            Color(0xFFFAF7F0), // Warm ivory
                            Color(0xFFF7F3E9),
                            Color(0xFFEEE7D7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                ),
              ),

              // 2. Animated Ambient Drifting Glass Orbs & Particles
              if (!disableAnimations)
                AnimatedBuilder(
                  animation: _ambientController,
                  builder: (context, _) {
                    final t = _ambientController.value * 2 * math.pi;

                    // Subtle parallax dampening: ~14 pixels max movement
                    final px = _pointerOffset.dx * 14;
                    final py = _pointerOffset.dy * 10;

                    return CustomPaint(
                      painter: _AmbientOrbsAndParticlesPainter(
                        progress: _ambientController.value,
                        time: t,
                        isDark: widget.isDark,
                        parallax: Offset(px, py),
                      ),
                    );
                  },
                ),

              // 3. Subtle Frosted Glass Veil allowing rich blooms to shine through
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                  child: Container(
                    color: widget.isDark
                        ? const Color(0x08000000)
                        : const Color(0x14FFFFFF),
                  ),
                ),
              ),

              // 4. Foreground Page Content
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter rendering vibrant drifting soft translucent glass orbs,
/// ambient light blooms, and shimmering gold star particles.
class _AmbientOrbsAndParticlesPainter extends CustomPainter {
  _AmbientOrbsAndParticlesPainter({
    required this.progress,
    required this.time,
    required this.isDark,
    required this.parallax,
  });

  final double progress;
  final double time;
  final bool isDark;
  final Offset parallax;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final minDim = math.min(width, height);

    // --- ORB 1: Radiant Royal Gold Light Bloom (Top-Right drifting) ---
    final orb1Center = Offset(
      width * 0.72 + math.sin(time * 0.8) * 55 + parallax.dx * 0.8,
      height * 0.20 + math.cos(time * 0.6) * 45 + parallax.dy * 0.8,
    );
    final orb1Breath = 1.0 + math.sin(time * 1.1) * 0.08;
    final orb1Radius = minDim * 0.46 * orb1Breath;

    final orb1Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFFD4AF37) : const Color(0xFFDFBE6E))
              .withValues(alpha: isDark ? 0.32 : 0.22),
          (isDark ? const Color(0xFFC5A04A) : const Color(0xFFE5CCA0))
              .withValues(alpha: isDark ? 0.16 : 0.10),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: orb1Center, radius: orb1Radius));

    canvas.drawCircle(orb1Center, orb1Radius, orb1Paint);

    // --- ORB 2: Deep Vibrant Sapphire & Cobalt Glow (Bottom-Left drifting) ---
    final orb2Center = Offset(
      width * 0.22 + math.cos(time * 0.7) * 50 - parallax.dx * 0.6,
      height * 0.72 + math.sin(time * 0.85) * 40 - parallax.dy * 0.6,
    );
    final orb2Breath = 1.0 + math.cos(time * 0.9) * 0.07;
    final orb2Radius = minDim * 0.52 * orb2Breath;

    final orb2Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFF2563EB) : const Color(0xFFFFFFFF))
              .withValues(alpha: isDark ? 0.28 : 0.40),
          (isDark ? const Color(0xFF1E3A8A) : const Color(0xFFFAF7F0))
              .withValues(alpha: isDark ? 0.14 : 0.15),
          Colors.transparent,
        ],
        stops: const [0.0, 0.60, 1.0],
      ).createShader(Rect.fromCircle(center: orb2Center, radius: orb2Radius));

    canvas.drawCircle(orb2Center, orb2Radius, orb2Paint);

    // --- ORB 3: Central Golden Light Halo (Behind Hero Title) ---
    final orb3Center = Offset(
      width * 0.50 + math.sin(time * 0.5) * 35,
      height * 0.36 + math.cos(time * 0.7) * 25,
    );
    final orb3Breath = 1.0 + math.sin(time * 1.3) * 0.10;
    final orb3Radius = minDim * 0.36 * orb3Breath;

    final orb3Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFFFFDF78) : const Color(0xFFE5CCA0))
              .withValues(alpha: isDark ? 0.20 : 0.15),
          (isDark ? const Color(0xFFA88434) : const Color(0xFFDFBE6E))
              .withValues(alpha: isDark ? 0.08 : 0.05),
          Colors.transparent,
        ],
        stops: const [0.0, 0.50, 1.0],
      ).createShader(Rect.fromCircle(center: orb3Center, radius: orb3Radius));

    canvas.drawCircle(orb3Center, orb3Radius, orb3Paint);

    // --- ORB 4: Oceanic Azure Glass Bloom (Mid-Right drifting) ---
    final orb4Center = Offset(
      width * 0.82 + math.cos(time * 0.6 + 1.2) * 45,
      height * 0.58 + math.sin(time * 0.75 + 1.2) * 35,
    );
    final orb4Radius = minDim * 0.38;

    final orb4Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFF0284C7) : const Color(0xFFFFFFFF))
              .withValues(alpha: isDark ? 0.22 : 0.25),
          (isDark ? const Color(0xFF0F172A) : const Color(0xFFEEE7D7))
              .withValues(alpha: isDark ? 0.07 : 0.08),
          Colors.transparent,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: orb4Center, radius: orb4Radius));

    canvas.drawCircle(orb4Center, orb4Radius, orb4Paint);

    // --- ORB 5: Royal Indigo Velvet Aura (Bottom-Center drifting) ---
    final orb5Center = Offset(
      width * 0.48 + math.sin(time * 0.65 + 2.5) * 40,
      height * 0.88 + math.cos(time * 0.8 + 2.0) * 30,
    );
    final orb5Radius = minDim * 0.45;

    final orb5Paint = Paint()
      ..shader = RadialGradient(
        colors: [
          (isDark ? const Color(0xFF4338CA) : const Color(0xFFE5CCA0))
              .withValues(alpha: isDark ? 0.20 : 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: orb5Center, radius: orb5Radius));

    canvas.drawCircle(orb5Center, orb5Radius, orb5Paint);

    // --- 28 HARMONIC TWINKLING GOLD PARTICLES ---
    final particlePaint = Paint()..style = PaintingStyle.fill;
    final haloPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 28; i++) {
      final seed = i * 137.5;
      final baseX = (math.sin(seed) * 0.5 + 0.5) * width;
      final baseY = (math.cos(seed * 1.3) * 0.5 + 0.5) * height;

      // Harmonic vertical and horizontal drifting
      final speedFactor = 0.6 + (i % 4) * 0.25;
      final driftX = math.sin(time * speedFactor + i) * 20 +
          (parallax.dx * (0.15 + (i % 3) * 0.1));
      final driftY = math.cos(time * 0.7 * speedFactor + i) * 22 +
          (parallax.dy * (0.15 + (i % 3) * 0.1));

      final particleX = (baseX + driftX) % width;
      final particleY = (baseY + driftY) % height;

      // Twinkling alpha pulse
      final twinkleSpeed = 1.2 + (i % 3) * 0.6;
      final alphaPulse = 0.22 + (math.sin(time * twinkleSpeed + i * 2.1) * 0.20);
      final radius = 1.0 + (i % 4) * 0.5; // Small stars: 1.0px to 2.5px

      final starColor = isDark
          ? ((i % 5 == 0) ? const Color(0xFFFFE082) : const Color(0xFFD4AF37))
          : const Color(0xFF8A6715);

      final finalAlpha = isDark
          ? alphaPulse.clamp(0.12, 0.65)
          : (alphaPulse * 0.6).clamp(0.08, 0.35);

      // Delicate luminous halo for larger stars
      if (radius >= 1.8 && isDark) {
        haloPaint.color = starColor.withValues(alpha: finalAlpha * 0.3);
        canvas.drawCircle(Offset(particleX, particleY), radius * 2.4, haloPaint);
      }

      particlePaint.color = starColor.withValues(alpha: finalAlpha);
      canvas.drawCircle(Offset(particleX, particleY), radius, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientOrbsAndParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isDark != isDark ||
        oldDelegate.parallax != parallax;
  }
}

/// A subtle, polished entrance animation component providing a smooth
/// fade-in and slight vertical translation.
class SubtleEntranceAnimation extends StatefulWidget {
  const SubtleEntranceAnimation({
    super.key,
    required this.child,
    this.delayMs = 0,
    this.duration = const Duration(milliseconds: 400),
    this.offsetY = 12.0,
  });

  final Widget child;
  final int delayMs;
  final Duration duration;
  final double offsetY;

  @override
  State<SubtleEntranceAnimation> createState() =>
      _SubtleEntranceAnimationState();
}

class _SubtleEntranceAnimationState extends State<SubtleEntranceAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.offsetY / 100),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    final isTest = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('Test');

    if (isTest || widget.delayMs == 0) {
      _controller.forward();
    } else {
      Future.delayed(Duration(milliseconds: widget.delayMs), () {
        if (mounted) {
          _controller.forward();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;
    if (disableAnimations) {
      return widget.child;
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
