import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/theme/app_colors.dart';
import '../../../providers/bible_provider.dart';

class ReadingSettingsPanel extends StatefulWidget {
  const ReadingSettingsPanel({super.key});

  @override
  State<ReadingSettingsPanel> createState() => _ReadingSettingsPanelState();
}

class _ReadingSettingsPanelState extends State<ReadingSettingsPanel> {
  final List<String> _builtInFonts = [
    'Default',
    'Serif',
    'Sans Serif',
    'Roboto',
    'Noto Sans',
    'Noto Serif',
  ];

  final Map<double, String> _scrollSpeedLabels = {
    0.5: 'Very Slow',
    1.0: 'Slow',
    2.0: 'Medium',
    3.0: 'Fast',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<BibleProvider>();
    final prefs = provider.preferences;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reading Settings',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Settings content
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Font Size
                _buildSectionTitle('Font Size'),
                const SizedBox(height: 12),
                _buildFontSizeControl(provider, prefs),

                const SizedBox(height: 32),

                // Font Family
                _buildSectionTitle('Font Family'),
                const SizedBox(height: 12),
                _buildFontFamilySelector(provider, prefs),

                const SizedBox(height: 32),

                // Custom Fonts
                _buildSectionTitle('Custom Fonts'),
                const SizedBox(height: 12),
                _buildCustomFontsSection(provider),

                const SizedBox(height: 32),

                // Auto-Scroll
                _buildSectionTitle('Auto-Scroll'),
                const SizedBox(height: 12),
                _buildAutoScrollSection(provider, prefs),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        fontFamily: 'Poppins',
      ),
    );
  }

  Widget _buildFontSizeControl(BibleProvider provider, prefs) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Size: ${prefs.fontSize.toInt()}',
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              'Preview',
              style: TextStyle(
                fontSize: prefs.fontSize,
                fontFamily: prefs.fontFamily == 'Default'
                    ? 'Poppins'
                    : prefs.fontFamily,
              ),
            ),
          ],
        ),
        Slider(
          value: prefs.fontSize,
          min: 12,
          max: 36,
          divisions: 24,
          label: prefs.fontSize.toInt().toString(),
          onChanged: (value) => provider.updateFontSize(value),
        ),
      ],
    );
  }

  Widget _buildFontFamilySelector(BibleProvider provider, prefs) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allFonts = [..._builtInFonts, ...provider.customFonts];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allFonts.map((font) {
        final isSelected = prefs.fontFamily == font;
        return GestureDetector(
          onTap: () => provider.updateFontFamily(font),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              gradient: isSelected ? AppColors.primaryGradient : null,
              color: isSelected
                  ? null
                  : (isDark ? AppColors.darkSurface : AppColors.lightSurface),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected
                    ? Colors.transparent
                    : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
              ),
            ),
            child: Text(
              font,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.textPrimary : AppColors.textDark),
                fontFamily: 'Poppins',
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCustomFontsSection(BibleProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton.icon(
          onPressed: () => _importCustomFont(provider),
          icon: const Icon(Icons.upload_file),
          label: const Text('Import Font (.ttf/.otf)'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
        ),
        if (provider.customFonts.isNotEmpty) ...[
          const SizedBox(height: 12),
          ...provider.customFonts.map((font) => ListTile(
                leading:
                    const Icon(Icons.font_download, color: AppColors.primary),
                title: Text(font),
                trailing: IconButton(
                  icon:
                      const Icon(Icons.delete_outline, color: AppColors.error),
                  onPressed: () => _removeCustomFont(provider, font),
                ),
                contentPadding: EdgeInsets.zero,
              )),
        ],
      ],
    );
  }

  Widget _buildAutoScrollSection(BibleProvider provider, prefs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Scroll Speed',
              style: TextStyle(
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              _scrollSpeedLabels[prefs.autoScrollSpeed] ?? 'Medium',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
        Slider(
          value: prefs.autoScrollSpeed,
          min: 0.5,
          max: 3.0,
          divisions: 3,
          label: _scrollSpeedLabels[prefs.autoScrollSpeed],
          onChanged: (value) => provider.updateAutoScrollSpeed(value),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tap the play button below to start auto-scrolling through the chapter.',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontFamily: 'Poppins',
          ),
        ),
      ],
    );
  }

  Future<void> _importCustomFont(BibleProvider provider) async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['ttf', 'otf'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        await provider.addCustomFont(file);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Font imported successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to import font: $e')),
        );
      }
    }
  }

  Future<void> _removeCustomFont(
      BibleProvider provider, String fontName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Font'),
        content: Text('Are you sure you want to remove "$fontName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Remove', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await provider.removeCustomFont(fontName);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Font removed')),
        );
      }
    }
  }
}
