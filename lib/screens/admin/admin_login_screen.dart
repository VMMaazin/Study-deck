import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:study_deck/core/session/admin_session.dart';
import 'package:study_deck/core/theme/app_theme.dart';
import 'package:study_deck/core/theme/theme_controller.dart';
import 'package:study_deck/screens/student/student_home_screen.dart';
import 'package:study_deck/services/auth_service.dart';
import 'package:study_deck/widgets/responsive_layout.dart';

/// Screen for staff administrators to sign in using Firebase Authentication.
/// Validates both credentials and Firestore administrative authorization.
class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({
    super.key,
    this.authService,
  });

  final AuthService? authService;

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  late final AuthService _authService;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final adminUser = await _authService.signInAdmin(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;

      // Update global AdminSession so the entire app reflects admin mode
      AdminSession.instance.setAdmin(adminUser);

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(adminUser);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const StudentHomeScreen(),
          ),
        );
      }

      final adminName = (adminUser.displayName != null && adminUser.displayName!.isNotEmpty)
          ? adminUser.displayName!
          : adminUser.email;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.royalGold, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Welcome, $adminName! Admin privileges activated.')),
            ],
          ),
          backgroundColor: AppColors.midnightNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AppColors.royalGold.withValues(alpha: 0.5)),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.warmIvory : AppColors.deepNavy,
            size: 20,
          ),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
              );
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? AppColors.goldLight : AppColors.royalGold,
              size: 22,
            ),
            onPressed: () => ThemeScope.of(context).toggleTheme(),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: PremiumAnimatedGlassBackground(
        isDark: isDark,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: ResponsiveContainer(
                maxWidth: 480,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.midnightNavy.withValues(alpha: 0.85)
                            : AppColors.pearlWhite.withValues(alpha: 0.90),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: isDark
                              ? AppColors.royalGold.withValues(alpha: 0.35)
                              : AppColors.goldMuted.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: isDark
                                ? Colors.black.withValues(alpha: 0.5)
                                : AppColors.deepNavy.withValues(alpha: 0.08),
                            blurRadius: 32,
                            offset: const Offset(0, 16),
                          ),
                          BoxShadow(
                            color: AppColors.royalGold.withValues(alpha: isDark ? 0.08 : 0.05),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Admin Royal Icon Emblem
                            Center(
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            AppColors.royalGold.withValues(alpha: 0.3),
                                            AppColors.goldMuted.withValues(alpha: 0.15),
                                          ]
                                        : [
                                            AppColors.goldLight.withValues(alpha: 0.35),
                                            AppColors.royalGold.withValues(alpha: 0.2),
                                          ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: AppColors.royalGold.withValues(alpha: 0.6),
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.royalGold.withValues(alpha: 0.25),
                                      blurRadius: 18,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  size: 38,
                                  color: AppColors.royalGold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Title & Subtitle
                            Text(
                              'Administrator Sign In',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3,
                                color: isDark ? AppColors.warmIvory : AppColors.deepNavy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Enter your authorized credentials to manage academic resources.',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Student Reassurance Alert Banner
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.deepNavy.withValues(alpha: 0.5)
                                    : AppColors.warmIvory.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.royalGold.withValues(alpha: isDark ? 0.3 : 0.4),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    size: 18,
                                    color: AppColors.royalGold,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Are you a student? You do not need to sign in to access course notes or question papers.',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                        color: isDark ? AppColors.warmIvory : AppColors.deepNavy,
                                        height: 1.35,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),

                            // Error message banner
                            if (_errorMessage != null) ...[
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? const Color(0xFF450A0A).withValues(alpha: 0.6)
                                      : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFEF4444),
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: const TextStyle(
                                          color: Color(0xFFDC2626),
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                            ],

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              style: TextStyle(
                                color: isDark ? AppColors.warmIvory : AppColors.deepNavy,
                                fontSize: 14.5,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Administrator Email',
                                hintText: 'admin@college.edu',
                                labelStyle: TextStyle(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                                prefixIcon: const Icon(Icons.email_outlined, size: 20, color: AppColors.royalGold),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.deepNavy.withValues(alpha: 0.4)
                                    : AppColors.champagne.withValues(alpha: 0.15),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.royalGold.withValues(alpha: 0.25)
                                        : AppColors.goldMuted.withValues(alpha: 0.4),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppColors.royalGold,
                                    width: 1.8,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your administrator email.';
                                }
                                if (!value.contains('@') || !value.contains('.')) {
                                  return 'Please enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.password],
                              style: TextStyle(
                                color: isDark ? AppColors.warmIvory : AppColors.deepNavy,
                                fontSize: 14.5,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                ),
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.royalGold),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    size: 20,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                                  ),
                                  onPressed: () {
                                    setState(() => _obscurePassword = !_obscurePassword);
                                  },
                                ),
                                filled: true,
                                fillColor: isDark
                                    ? AppColors.deepNavy.withValues(alpha: 0.4)
                                    : AppColors.champagne.withValues(alpha: 0.15),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: BorderSide(
                                    color: isDark
                                        ? AppColors.royalGold.withValues(alpha: 0.25)
                                        : AppColors.goldMuted.withValues(alpha: 0.4),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(
                                    color: AppColors.royalGold,
                                    width: 1.8,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFEF4444)),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.8),
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password.';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 26),

                            // Sign In Button (Liquid metallic gold)
                            Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isLoading
                                      ? [
                                          AppColors.royalGold.withValues(alpha: 0.5),
                                          AppColors.goldMuted.withValues(alpha: 0.5),
                                        ]
                                      : [
                                          AppColors.goldLight,
                                          AppColors.royalGold,
                                        ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  if (!_isLoading)
                                    BoxShadow(
                                      color: AppColors.royalGold.withValues(alpha: 0.35),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                    ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(14),
                                  onTap: _isLoading ? null : _handleLogin,
                                  child: Center(
                                    child: _isLoading
                                        ? const SizedBox(
                                            height: 22,
                                            width: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.2,
                                              color: AppColors.midnightNavy,
                                            ),
                                          )
                                        : const Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 12),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.login_rounded,
                                                  color: AppColors.midnightNavy,
                                                  size: 20,
                                                ),
                                                SizedBox(width: 8),
                                                Flexible(
                                                  child: Text(
                                                    'Sign In as Administrator',
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: AppColors.midnightNavy,
                                                      fontSize: 14.5,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 0.2,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Back to Student Home
                            TextButton.icon(
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).pop();
                                } else {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
                                  );
                                }
                              },
                              icon: Icon(
                                Icons.school_outlined,
                                size: 18,
                                color: isDark ? AppColors.champagne : AppColors.royalGold,
                              ),
                              label: Text(
                                'Back to Student Academic Hub',
                                style: TextStyle(
                                  color: isDark ? AppColors.champagne : AppColors.royalGold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
