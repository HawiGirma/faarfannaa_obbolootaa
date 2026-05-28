import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/song_provider.dart';
import '../../models/song_model.dart';
import 'upload_song_screen.dart';
import 'edit_song_screen.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();

    if (!auth.isAdmin) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        appBar: AppBar(
          title: const Text('Admin'),
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.error, size: 64),
              const SizedBox(height: 16),
              Text(
                'Admin Access Required',
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : AppColors.textDark,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Poppins',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You need admin privileges to access this section.',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondary
                      : AppColors.textDarkSecondary,
                  fontSize: 14,
                  fontFamily: 'Poppins',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return _AdminDashboard(isDark: isDark);
  }
}

class _AdminDashboard extends StatelessWidget {
  final bool isDark;
  const _AdminDashboard({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final songProvider = context.watch<SongProvider>();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor:
            isDark ? AppColors.darkBackground : AppColors.lightBackground,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: isDark ? AppColors.textPrimary : AppColors.textDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UploadSongScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 4),
                    Text(
                      'Upload',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _StatCard(
                  label: 'Total Songs',
                  value: '${songProvider.allSongs.length}',
                  icon: Icons.music_note_rounded,
                  color: AppColors.primary,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Featured',
                  value: '${songProvider.featuredSongs.length}',
                  icon: Icons.star_rounded,
                  color: AppColors.accent,
                  isDark: isDark,
                ),
                const SizedBox(width: 12),
                _StatCard(
                  label: 'Languages',
                  value: '3',
                  icon: Icons.language_rounded,
                  color: AppColors.success,
                  isDark: isDark,
                ),
              ],
            ),
          ),

          // Songs list header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  'Manage Songs',
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColors.textDark,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),

          // Songs list
          Expanded(
            child: songProvider.allSongs.isEmpty
                ? Center(
                    child: Text(
                      'No songs yet. Upload your first song!',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textDarkSecondary,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: songProvider.allSongs.length,
                    itemBuilder: (_, i) {
                      final song = songProvider.allSongs[i];
                      return _AdminSongTile(
                        song: song,
                        isDark: isDark,
                        onEdit: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditSongScreen(song: song),
                          ),
                        ),
                        onDelete: () =>
                            _confirmDelete(context, song, songProvider),
                        onToggleFeatured: () => songProvider.toggleFeatured(
                          song.id,
                          !song.featured,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    SongModel song,
    SongProvider provider,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Song',
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : AppColors.textDark,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${song.title}"? This cannot be undone.',
          style: TextStyle(
            color:
                isDark ? AppColors.textSecondary : AppColors.textDarkSecondary,
            fontFamily: 'Poppins',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textDarkSecondary,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              provider.deleteSong(song.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Delete',
              style: TextStyle(fontFamily: 'Poppins', color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : AppColors.textDark,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textDarkSecondary,
                fontSize: 11,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminSongTile extends StatelessWidget {
  final SongModel song;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFeatured;

  const _AdminSongTile({
    required this.song,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFeatured,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: 52,
              height: 52,
              color: AppColors.primary.withOpacity(0.2),
              child: const Icon(
                Icons.music_note_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColors.textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Poppins',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artist,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondary
                        : AppColors.textDarkSecondary,
                    fontSize: 12,
                    fontFamily: 'Poppins',
                  ),
                ),
                Text(
                  song.language,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontFamily: 'Poppins',
                  ),
                ),
              ],
            ),
          ),
          // Actions
          Row(
            children: [
              // Featured toggle
              GestureDetector(
                onTap: onToggleFeatured,
                child: Icon(
                  song.featured
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: song.featured ? AppColors.accent : AppColors.textMuted,
                  size: 22,
                ),
              ),
              const SizedBox(width: 8),
              // Edit
              GestureDetector(
                onTap: onEdit,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Delete
              GestureDetector(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.delete_rounded,
                    color: AppColors.error,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
