import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../settings/settings_screen.dart';
import '../admin/admin_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        gradient: auth.isAdmin
                            ? AppColors.primaryGradient
                            : const LinearGradient(
                                colors: [
                                  AppColors.darkCardElevated,
                                  AppColors.darkCard,
                                ],
                              ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: auth.isAdmin
                            ? const Icon(
                                Icons.admin_panel_settings_rounded,
                                color: Colors.white,
                                size: 40,
                              )
                            : Icon(
                                Icons.person_rounded,
                                color: Colors.white.withValues(alpha: 0.5),
                                size: 40,
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      auth.isAdmin ? 'Admin' : 'Guest',
                      style: TextStyle(
                        color:
                            isDark ? AppColors.textPrimary : AppColors.textDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      auth.isAdmin
                          ? auth.user?.email ?? ''
                          : 'Browse & listen freely',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textDarkSecondary,
                        fontSize: 13,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    if (auth.isAdmin) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 5),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_rounded,
                                color: Colors.white, size: 14),
                            SizedBox(width: 6),
                            Text(
                              'Admin Access',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Menu ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    // Admin dashboard — only visible when signed in as admin
                    if (auth.isAdmin)
                      _MenuItem(
                        icon: Icons.dashboard_rounded,
                        label: 'Admin Dashboard',
                        color: AppColors.primary,
                        isDark: isDark,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const AdminScreen()),
                        ),
                      ),

                    _MenuItem(
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                      color: AppColors.textMuted,
                      isDark: isDark,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SettingsScreen()),
                      ),
                    ),

                    // Theme toggle
                    _MenuItem(
                      icon: isDark
                          ? Icons.light_mode_rounded
                          : Icons.dark_mode_rounded,
                      label: isDark ? 'Light Mode' : 'Dark Mode',
                      color: AppColors.accent,
                      isDark: isDark,
                      onTap: () => themeProvider.toggleTheme(),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.primary,
                      ),
                    ),

                    _MenuItem(
                      icon: Icons.info_outline_rounded,
                      label: 'About',
                      color: AppColors.info,
                      isDark: isDark,
                      onTap: () => _showAbout(context, isDark),
                    ),

                    const SizedBox(height: 8),

                    // Admin sign-in / sign-out
                    if (auth.isAdmin)
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        label: 'Sign Out Admin',
                        color: AppColors.error,
                        isDark: isDark,
                        onTap: () => auth.signOut(),
                      )
                    else
                      _MenuItem(
                        icon: Icons.admin_panel_settings_rounded,
                        label: 'Admin Login',
                        color: AppColors.primary,
                        isDark: isDark,
                        onTap: () => _showAdminLoginDialog(context, isDark),
                      ),

                    const SizedBox(height: 32),
                    Text(
                      'Faarfanna Obbolootaa v1.0.0',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textMuted
                            : AppColors.textDarkSecondary,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Admin Login Dialog ─────────────────────────────────────────────
  void _showAdminLoginDialog(BuildContext context, bool isDark) {
    final usernameCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    bool obscure = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            final auth = ctx.read<AuthProvider>();
            return Dialog(
              backgroundColor:
                  isDark ? AppColors.darkCard : AppColors.lightCard,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Admin Login',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textDark,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enter admin credentials to continue',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.textDarkSecondary,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // Username field
                      _DialogField(
                        controller: usernameCtrl,
                        hint: 'Username',
                        icon: Icons.person_outline_rounded,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),

                      // Password field
                      _DialogField(
                        controller: passwordCtrl,
                        hint: 'Password',
                        icon: Icons.lock_outline_rounded,
                        isDark: isDark,
                        obscure: obscure,
                        onToggleObscure: () =>
                            setDialogState(() => obscure = !obscure),
                      ),
                      const SizedBox(height: 8),

                      // Error message
                      Consumer<AuthProvider>(
                        builder: (_, a, __) => a.errorMessage != null
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  a.errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 8),

                      // Sign in button
                      Consumer<AuthProvider>(
                        builder: (_, a, __) => SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: TextButton(
                              onPressed: a.isLoading
                                  ? null
                                  : () async {
                                      final success = await a.adminSignIn(
                                        usernameCtrl.text,
                                        passwordCtrl.text,
                                      );
                                      if (success && ctx.mounted) {
                                        Navigator.pop(ctx);
                                      }
                                    },
                              child: a.isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textSecondary
                                : AppColors.textDarkSecondary,
                            fontFamily: 'Poppins',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showAbout(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Faarfanna Obbolootaa',
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : AppColors.textDark,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'A gospel song platform for Afaan Oromo and English worship songs.\n\nVersion 1.0.0\n\nBuilt with ❤️ for the worship community.',
          style: TextStyle(
            color:
                isDark ? AppColors.textSecondary : AppColors.textDarkSecondary,
            fontFamily: 'Poppins',
            height: 1.6,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Close',
              style: TextStyle(color: AppColors.primary, fontFamily: 'Poppins'),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Reusable dialog text field ─────────────────────────────────────────
class _DialogField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isDark;
  final bool obscure;
  final VoidCallback? onToggleObscure;

  const _DialogField({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.isDark,
    this.obscure = false,
    this.onToggleObscure,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(
        color: isDark ? AppColors.textPrimary : AppColors.textDark,
        fontFamily: 'Poppins',
        fontSize: 14,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? AppColors.textMuted : AppColors.textDarkSecondary,
          fontFamily: 'Poppins',
          fontSize: 14,
        ),
        prefixIcon: Icon(icon,
            color: isDark ? AppColors.textMuted : AppColors.textDarkSecondary,
            size: 20),
        suffixIcon: onToggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: isDark
                      ? AppColors.textMuted
                      : AppColors.textDarkSecondary,
                  size: 20,
                ),
                onPressed: onToggleObscure,
              )
            : null,
        filled: true,
        fillColor:
            isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

// ── Menu item tile ─────────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool isDark;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.isDark,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : AppColors.textDark,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark
                      ? AppColors.textMuted
                      : AppColors.textDarkSecondary,
                  size: 20,
                ),
          ],
        ),
      ),
    );
  }
}
