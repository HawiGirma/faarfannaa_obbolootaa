import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString(AppConstants.languageKey) ?? 'en';
    });
  }

  Future<void> _setLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.languageKey, code);
    setState(() => _selectedLanguage = code);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? AppColors.textPrimary : AppColors.textDark,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(title: 'Appearance', isDark: isDark),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            title: 'Theme',
            subtitle: isDark ? 'Dark Mode' : 'Light Mode',
            isDark: isDark,
            trailing: Switch(
              value: isDark,
              onChanged: (_) => themeProvider.toggleTheme(),
              activeThumbColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 20),
          _SectionTitle(title: 'Language', isDark: isDark),
          const SizedBox(height: 8),
          _LanguageTile(
            code: 'en',
            label: 'English',
            flag: '🇬🇧',
            isSelected: _selectedLanguage == 'en',
            isDark: isDark,
            onTap: () => _setLanguage('en'),
          ),
          const SizedBox(height: 8),
          _LanguageTile(
            code: 'om',
            label: 'Afaan Oromo',
            flag: '🇪🇹',
            isSelected: _selectedLanguage == 'om',
            isDark: isDark,
            onTap: () => _setLanguage('om'),
          ),
          const SizedBox(height: 20),
          _SectionTitle(title: 'About', isDark: isDark),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            title: 'Version',
            subtitle: '1.0.0',
            isDark: isDark,
          ),
          _SettingsTile(
            icon: Icons.music_note_rounded,
            title: 'App Name',
            subtitle: 'Faarfanna Obbolootaa',
            isDark: isDark,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionTitle({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.primary,
        fontSize: 13,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textDarkSecondary,
              size: 22,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color:
                          isDark ? AppColors.textPrimary : AppColors.textDark,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark
                          ? AppColors.textSecondary
                          : AppColors.textDarkSecondary,
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String code;
  final String label;
  final String flag;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.code,
    required this.label,
    required this.flag,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.12)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(14),
          border: isSelected
              ? Border.all(color: AppColors.primary.withOpacity(0.5))
              : null,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.textPrimary : AppColors.textDark),
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}
