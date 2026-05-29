import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/song_model.dart';
import '../../providers/song_provider.dart';
import '../../widgets/custom_button.dart';

class EditSongScreen extends StatefulWidget {
  final SongModel song;
  const EditSongScreen({super.key, required this.song});

  @override
  State<EditSongScreen> createState() => _EditSongScreenState();
}

class _EditSongScreenState extends State<EditSongScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _artistController;
  late TextEditingController _lyricsController;
  late TextEditingController _albumController;
  late String _selectedLanguage;
  late bool _isFeatured;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.song.title);
    _artistController = TextEditingController(text: widget.song.artist);
    _lyricsController = TextEditingController(text: widget.song.lyrics);
    _albumController = TextEditingController(text: widget.song.albumName ?? '');
    _selectedLanguage = widget.song.language;
    _isFeatured = widget.song.featured;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _lyricsController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final updated = widget.song.copyWith(
      title: _titleController.text.trim(),
      artist: _artistController.text.trim(),
      language: _selectedLanguage,
      lyrics: _lyricsController.text.trim(),
      albumName: _albumController.text.trim().isNotEmpty
          ? _albumController.text.trim()
          : null,
      featured: _isFeatured,
    );

    try {
      await context.read<SongProvider>().updateSong(updated);
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Song updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update song: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Edit Song'),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildField(
                controller: _titleController,
                label: 'Song Title',
                hint: 'Enter song title',
                isDark: isDark,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _artistController,
                label: 'Artist / Group Name',
                hint: 'Enter artist name',
                isDark: isDark,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Artist is required' : null,
              ),
              const SizedBox(height: 16),
              _buildField(
                controller: _albumController,
                label: 'Album Name (optional)',
                hint: 'Enter album name',
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              // Language
              Text(
                'Language',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textDarkSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    isExpanded: true,
                    dropdownColor:
                        isDark ? AppColors.darkCard : AppColors.lightCard,
                    style: TextStyle(
                      color:
                          isDark ? AppColors.textPrimary : AppColors.textDark,
                      fontFamily: 'Poppins',
                      fontSize: 15,
                    ),
                    items: AppConstants.languages
                        .map(
                          (lang) =>
                              DropdownMenuItem(value: lang, child: Text(lang)),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedLanguage = v!),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Lyrics
              Text(
                'Lyrics',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textDarkSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _lyricsController,
                maxLines: 8,
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : AppColors.textDark,
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  height: 1.6,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter song lyrics...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppColors.textMuted
                        : AppColors.textDarkSecondary,
                    fontFamily: 'Poppins',
                  ),
                  filled: true,
                  fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: isDark
                          ? AppColors.darkDivider
                          : AppColors.lightDivider,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              // Featured
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star_rounded,
                      color: AppColors.accent,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Featured Song',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textPrimary
                              : AppColors.textDark,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Switch(
                      value: _isFeatured,
                      onChanged: (v) => setState(() => _isFeatured = v),
                      activeThumbColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              GradientButton(
                text: 'Save Changes',
                onPressed: _save,
                isLoading: _isSaving,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool isDark,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color:
                isDark ? AppColors.textSecondary : AppColors.textDarkSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontFamily: 'Poppins',
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : AppColors.textDark,
            fontFamily: 'Poppins',
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? AppColors.textMuted : AppColors.textDarkSecondary,
              fontFamily: 'Poppins',
            ),
            filled: true,
            fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: isDark ? AppColors.darkDivider : AppColors.lightDivider,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
