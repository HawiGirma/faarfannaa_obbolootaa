import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/song_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/song_provider.dart';
import '../../services/storage_service.dart';
import '../../widgets/custom_button.dart';

class UploadSongScreen extends StatefulWidget {
  const UploadSongScreen({super.key});

  @override
  State<UploadSongScreen> createState() => _UploadSongScreenState();
}

class _UploadSongScreenState extends State<UploadSongScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _artistController = TextEditingController();
  final _lyricsController = TextEditingController();
  final _albumController = TextEditingController();

  String _selectedLanguage = AppConstants.langAfaanOromo;
  File? _audioFile;
  File? _imageFile;
  Uint8List? _audioBytes; // web only
  Uint8List? _imageBytes; // web only
  String? _audioFileName;
  String? _imageFileName;
  bool _isFeatured = false;
  bool _isUploading = false;
  double _uploadProgress = 0;
  String _uploadStatus = '';

  final StorageService _storageService = StorageService();
  final _uuid = const Uuid();

  @override
  void dispose() {
    _titleController.dispose();
    _artistController.dispose();
    _lyricsController.dispose();
    _albumController.dispose();
    super.dispose();
  }

  Future<void> _pickAudio() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
      allowMultiple: false,
      withData: kIsWeb, // on web we need bytes; on mobile path is enough
    );
    if (result != null && result.files.isNotEmpty) {
      final picked = result.files.single;
      setState(() {
        _audioFileName = picked.name;
        if (kIsWeb) {
          _audioBytes = picked.bytes;
          _audioFile = null;
        } else {
          _audioFile = picked.path != null ? File(picked.path!) : null;
          _audioBytes = null;
        }
      });
    }
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // image_picker web support is limited; use file_picker for consistency
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final picked = result.files.single;
        setState(() {
          _imageFileName = picked.name;
          _imageBytes = picked.bytes;
          _imageFile = null;
        });
      }
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          _imageFileName = picked.name;
          _imageBytes = null;
        });
      }
    }
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;

    final bool hasAudio = kIsWeb
        ? (_audioBytes != null && _audioBytes!.isNotEmpty)
        : (_audioFile != null);
    if (!hasAudio) {
      _showError('Please select an audio file');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadStatus = 'Uploading audio...';
    });

    try {
      // Capture context-dependent values before any await
      final auth = context.read<AuthProvider>();
      final songProvider = context.read<SongProvider>();
      final uploadedBy = auth.user?.uid;
      final songId = _uuid.v4();

      // ── Upload audio ──────────────────────────────────────────────────
      final audioUrl = await _storageService.uploadAudioWithProgress(
        '$songId.mp3',
        file: kIsWeb ? null : _audioFile,
        bytes: kIsWeb ? _audioBytes : null,
        onProgress: (p) {
          if (!mounted) return;
          setState(() => _uploadProgress = p * 0.5);
        },
      );

      // ── Upload image (optional) ───────────────────────────────────────
      String imageUrl = '';
      final bool hasImage = kIsWeb
          ? (_imageBytes != null && _imageBytes!.isNotEmpty)
          : (_imageFile != null);

      if (hasImage) {
        if (!mounted) return;
        setState(() => _uploadStatus = 'Uploading cover image...');

        imageUrl = await _storageService.uploadImageWithProgress(
          '$songId.jpg',
          file: kIsWeb ? null : _imageFile,
          bytes: kIsWeb ? _imageBytes : null,
          onProgress: (p) {
            if (!mounted) return;
            setState(() => _uploadProgress = 0.5 + p * 0.4);
          },
        );
      }

      if (!mounted) return;
      setState(() {
        _uploadStatus = 'Saving song data...';
        _uploadProgress = 0.9;
      });

      // ── Save to Firestore ─────────────────────────────────────────────
      final song = SongModel(
        id: songId,
        title: _titleController.text.trim(),
        artist: _artistController.text.trim(),
        language: _selectedLanguage,
        lyrics: _lyricsController.text.trim(),
        audioUrl: audioUrl,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        featured: _isFeatured,
        albumName: _albumController.text.trim().isNotEmpty
            ? _albumController.text.trim()
            : null,
        uploadedBy: uploadedBy,
      );

      await songProvider.addSong(song);

      if (!mounted) return;
      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = 'Done!';
      });

      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Song uploaded successfully!'),
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
      if (!mounted) return;
      setState(() => _isUploading = false);
      _showError('Upload failed: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Upload Song'),
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
      body: _isUploading
          ? _UploadingView(
              progress: _uploadProgress,
              status: _uploadStatus,
              isDark: isDark,
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Audio file picker
                    _FilePicker(
                      label: 'Audio File *',
                      hint: 'Select MP3 File',
                      icon: Icons.audio_file_rounded,
                      fileName: _audioFileName,
                      isDark: isDark,
                      onTap: _pickAudio,
                    ),
                    const SizedBox(height: 16),

                    // Image picker
                    _FilePicker(
                      label: 'Cover Image',
                      hint: 'Select Image (optional)',
                      icon: Icons.image_rounded,
                      fileName: _imageFileName,
                      isDark: isDark,
                      onTap: _pickImage,
                      imageFile: kIsWeb ? null : _imageFile,
                      imageBytes: kIsWeb ? _imageBytes : null,
                    ),
                    const SizedBox(height: 20),

                    // Title
                    _buildField(
                      controller: _titleController,
                      label: 'Song Title *',
                      hint: 'Enter song title',
                      isDark: isDark,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Artist
                    _buildField(
                      controller: _artistController,
                      label: 'Artist / Group Name *',
                      hint: 'Enter artist or group name',
                      isDark: isDark,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Artist is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Album
                    _buildField(
                      controller: _albumController,
                      label: 'Album Name (optional)',
                      hint: 'Enter album name',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),

                    // Language
                    _buildLabel('Language *', isDark),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.darkCard : AppColors.lightCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkDivider
                              : AppColors.lightDivider,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLanguage,
                          isExpanded: true,
                          dropdownColor:
                              isDark ? AppColors.darkCard : AppColors.lightCard,
                          style: TextStyle(
                            color: isDark
                                ? AppColors.textPrimary
                                : AppColors.textDark,
                            fontFamily: 'Poppins',
                            fontSize: 15,
                          ),
                          items: AppConstants.languages
                              .map(
                                (lang) => DropdownMenuItem(
                                  value: lang,
                                  child: Text(lang),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedLanguage = v!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Lyrics
                    _buildLabel('Lyrics', isDark),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _lyricsController,
                      maxLines: 8,
                      style: TextStyle(
                        color:
                            isDark ? AppColors.textPrimary : AppColors.textDark,
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        height: 1.6,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter song lyrics here...',
                        hintStyle: TextStyle(
                          color: isDark
                              ? AppColors.textMuted
                              : AppColors.textDarkSecondary,
                          fontFamily: 'Poppins',
                        ),
                        filled: true,
                        fillColor:
                            isDark ? AppColors.darkCard : AppColors.lightCard,
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

                    // Featured toggle
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.darkCard : AppColors.lightCard,
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
                              'Mark as Featured',
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

                    GradientButton(text: 'Publish Song', onPressed: _upload),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        color: isDark ? AppColors.textSecondary : AppColors.textDarkSecondary,
        fontSize: 13,
        fontWeight: FontWeight.w500,
        fontFamily: 'Poppins',
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
        _buildLabel(label, isDark),
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

class _FilePicker extends StatelessWidget {
  final String label;
  final String hint;
  final IconData icon;
  final String? fileName;
  final bool isDark;
  final VoidCallback onTap;
  final File? imageFile;
  final Uint8List? imageBytes; // web preview

  const _FilePicker({
    required this.label,
    required this.hint,
    required this.icon,
    required this.fileName,
    required this.isDark,
    required this.onTap,
    this.imageFile,
    this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if we have an image to preview
    final bool hasImagePreview =
        (imageBytes != null && imageBytes!.isNotEmpty) || (imageFile != null);

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
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: fileName != null
                    ? AppColors.primary.withValues(alpha: 0.5)
                    : (isDark ? AppColors.darkDivider : AppColors.lightDivider),
                width: fileName != null ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                if (hasImagePreview)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: imageBytes != null
                        ? Image.memory(
                            imageBytes!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            imageFile!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                          ),
                  )
                else
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: AppColors.primary, size: 24),
                  ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName ?? hint,
                        style: TextStyle(
                          color: fileName != null
                              ? (isDark
                                  ? AppColors.textPrimary
                                  : AppColors.textDark)
                              : (isDark
                                  ? AppColors.textMuted
                                  : AppColors.textDarkSecondary),
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: fileName != null
                              ? FontWeight.w500
                              : FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (fileName != null)
                        const Text(
                          'Tap to change',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11,
                            fontFamily: 'Poppins',
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.upload_rounded,
                  color: isDark
                      ? AppColors.textMuted
                      : AppColors.textDarkSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UploadingView extends StatelessWidget {
  final double progress;
  final String status;
  final bool isDark;

  const _UploadingView({
    required this.progress,
    required this.status,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_upload_rounded,
                color: AppColors.primary,
                size: 50,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              status,
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : AppColors.textDark,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 24),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor:
                    isDark ? AppColors.darkCard : AppColors.lightCard,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.primary,
                ),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
