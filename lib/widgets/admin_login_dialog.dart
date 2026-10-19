import 'package:flutter/material.dart';
import 'package:study_deck/core/session/admin_session.dart';
import 'package:study_deck/core/theme/app_theme.dart';
import 'package:study_deck/models/admin_user_model.dart';
import 'package:study_deck/services/auth_service.dart';

/// A compact modal login dialog for administrators.
/// Enables seamless login without navigating away from the current browsing flow.
class AdminLoginDialog extends StatefulWidget {
  const AdminLoginDialog({
    super.key,
    this.session,
  });

  final AdminSession? session;

  static Future<AdminUserModel?> show(BuildContext context) {
    return showDialog<AdminUserModel>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const AdminLoginDialog(),
    );
  }

  @override
  State<AdminLoginDialog> createState() => _AdminLoginDialogState();
}

class _AdminLoginDialogState extends State<AdminLoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final session = widget.session ?? AdminSessionScope.of(context);
      final admin = await session.signIn(
        _emailController.text,
        _passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop(admin);

      final adminName = (admin.displayName != null && admin.displayName!.isNotEmpty)
          ? admin.displayName!
          : admin.email;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.royalGold, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text('Welcome, $adminName! Admin controls enabled.')),
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
        _errorMessage = e is AdminAuthException ? e.message : e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: isDark ? RoyalColors.glassGoldBorder : const Color(0x33C5A04A),
          width: 1.2,
        ),
      ),
      backgroundColor: isDark ? const Color(0xF2101B3B) : const Color(0xF7FAF7F0),
      elevation: 20,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(26.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header row with Icon and Title
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: RoyalGradients.metallicGold,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: RoyalColors.royalGold.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: RoyalColors.midnightNavy,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Administrator Login',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: isDark ? RoyalColors.pearlWhite : RoyalColors.midnightNavy,
                            ),
                          ),
                          Text(
                            'Academic Admin Access',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? RoyalColors.champagne.withValues(alpha: 0.8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: isDark ? RoyalColors.textMutedDark : const Color(0xFF64748B),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Student reassurance tip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x33C5A04A) : const Color(0x1FC5A04A),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0x33C5A04A) : const Color(0x26C5A04A),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 16,
                        color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Students do not need to log in. Course notes are publicly open.',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? RoyalColors.champagne : const Color(0xFF5A4510),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Error message banner
                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF450A0A) : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, color: Color(0xFFDC2626), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  decoration: InputDecoration(
                    labelText: 'Admin Email',
                    hintText: 'admin@college.edu',
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      size: 18,
                      color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? RoyalColors.royalGold : const Color(0xFF8A6715),
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Please enter your email.';
                    if (!v.contains('@')) return 'Enter a valid email.';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(
                      Icons.lock_outline_rounded,
                      size: 18,
                      color: isDark ? RoyalColors.champagne : const Color(0xFF8A6715),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? RoyalColors.royalGold : const Color(0xFF8A6715),
                        width: 1.5,
                      ),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please enter your password.';
                    return null;
                  },
                  onFieldSubmitted: (_) => _handleSignIn(),
                ),
                const SizedBox(height: 22),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? RoyalColors.textMutedDark : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _isLoading ? null : _handleSignIn,
                      style: FilledButton.styleFrom(
                        backgroundColor: RoyalColors.royalGold,
                        foregroundColor: RoyalColors.midnightNavy,
                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: RoyalColors.midnightNavy,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
