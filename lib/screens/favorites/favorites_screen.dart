import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/song_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/song_provider.dart';
import '../../services/audio_player_service.dart';
import '../../widgets/song_card.dart';
import '../../widgets/shimmer_loading.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  List<SongModel> _favSongs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAdmin) return;
    setState(() => _loading = true);
    final songs = await context
        .read<SongProvider>()
        .getFavoriteSongs(auth.user!.favoriteIds);
    setState(() {
      _favSongs = songs;
      _loading = false;
    });
  }

  void _playSong(SongModel song) {
    final player = context.read<AudioPlayerService>();
    player.playSong(song, queue: _favSongs);
    context.read<SongProvider>().incrementPlayCount(song.id);
    // Song plays directly without navigating to detail page
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthProvider>();
    final player = context.watch<AudioPlayerService>();

    // Reload when admin's favorites list changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (auth.isAdmin && auth.user!.favoriteIds.length != _favSongs.length) {
        _loadFavorites();
      }
    });

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Favorites',
                      style: TextStyle(
                        color:
                            isDark ? AppColors.textPrimary : AppColors.textDark,
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  if (_favSongs.isNotEmpty)
                    Text(
                      '${_favSongs.length} songs',
                      style: TextStyle(
                        color: isDark
                            ? AppColors.textSecondary
                            : AppColors.textDarkSecondary,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: !auth.isAdmin
                  ? _GuestState(isDark: isDark)
                  : _loading
                      ? const ShimmerList(count: 5)
                      : _favSongs.isEmpty
                          ? _EmptyFavorites(isDark: isDark)
                          : RefreshIndicator(
                              onRefresh: _loadFavorites,
                              color: AppColors.primary,
                              child: ListView.builder(
                                itemCount: _favSongs.length,
                                itemBuilder: (_, i) {
                                  final song = _favSongs[i];
                                  return SongCard(
                                    song: song,
                                    isPlaying:
                                        player.currentSong?.id == song.id,
                                    onTap: () => _playSong(song),
                                  );
                                },
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Guest state ────────────────────────────────────────────────────────
class _GuestState extends StatelessWidget {
  final bool isDark;
  const _GuestState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: AppColors.primary,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Favorites',
              style: TextStyle(
                color: isDark ? AppColors.textPrimary : AppColors.textDark,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                fontFamily: 'Poppins',
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Saved songs are visible to the admin.\nBrowse and enjoy the music freely!',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondary
                    : AppColors.textDarkSecondary,
                fontSize: 14,
                fontFamily: 'Poppins',
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty favorites ────────────────────────────────────────────────────
class _EmptyFavorites extends StatelessWidget {
  final bool isDark;
  const _EmptyFavorites({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              color: AppColors.error,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No favorites yet',
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the heart icon on any song to save it here',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textDarkSecondary,
              fontSize: 14,
              fontFamily: 'Poppins',
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
