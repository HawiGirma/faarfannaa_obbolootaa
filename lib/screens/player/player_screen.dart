import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../providers/auth_provider.dart';
import '../../services/audio_player_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;
  bool _showLyrics = false;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final auth = context.watch<AuthProvider>();
    final song = player.currentSong;

    if (song == null) {
      return const Scaffold(body: Center(child: Text('No song playing')));
    }

    final isFav = auth.isFavorite(song.id);

    return Scaffold(
      body: Stack(
        children: [
          // Background
          if (song.imageUrl.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: song.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.playerGradient,
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 40, sigmaY: 40),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.6),
                      Colors.black.withOpacity(0.95),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Now Playing',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _showLyrics = !_showLyrics),
                        icon: Icon(
                          Icons.lyrics_rounded,
                          color: _showLyrics ? AppColors.primary : Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),

                        // Album art or lyrics
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          child: _showLyrics
                              ? _LyricsView(lyrics: song.lyrics)
                              : _AlbumArt(
                                  imageUrl: song.imageUrl,
                                  isPlaying: player.isPlaying,
                                  rotationController: _rotationController,
                                ),
                        ),

                        const SizedBox(height: 32),

                        // Song info
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    song.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    song.artist,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.65),
                                      fontSize: 15,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (auth.user != null) {
                                  auth.toggleFavorite(song.id);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isFav
                                      ? AppColors.error.withOpacity(0.2)
                                      : Colors.white.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFav
                                      ? Icons.favorite_rounded
                                      : Icons.favorite_border_rounded,
                                  color: isFav ? AppColors.error : Colors.white,
                                  size: 22,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Progress bar
                        Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14,
                                ),
                                activeTrackColor: AppColors.primary,
                                inactiveTrackColor: Colors.white.withOpacity(
                                  0.2,
                                ),
                                thumbColor: Colors.white,
                                overlayColor: AppColors.primary.withOpacity(
                                  0.2,
                                ),
                              ),
                              child: Slider(
                                value: player.progress.clamp(0.0, 1.0),
                                onChanged: (v) => player.seekToProgress(v),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    AppUtils.formatDuration(player.position),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  Text(
                                    AppUtils.formatDuration(player.duration),
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 12,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Previous
                            IconButton(
                              onPressed: player.playPrevious,
                              icon: const Icon(Icons.skip_previous_rounded),
                              color: Colors.white,
                              iconSize: 36,
                            ),
                            // Play/Pause
                            GestureDetector(
                              onTap: player.togglePlayPause,
                              child: Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.5),
                                      blurRadius: 30,
                                      spreadRadius: 5,
                                    ),
                                  ],
                                ),
                                child: player.isLoading
                                    ? const Padding(
                                        padding: EdgeInsets.all(20),
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Icon(
                                        player.isPlaying
                                            ? Icons.pause_rounded
                                            : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 38,
                                      ),
                              ),
                            ),
                            // Next
                            IconButton(
                              onPressed: player.playNext,
                              icon: const Icon(Icons.skip_next_rounded),
                              color: Colors.white,
                              iconSize: 36,
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AlbumArt extends StatelessWidget {
  final String imageUrl;
  final bool isPlaying;
  final AnimationController rotationController;

  const _AlbumArt({
    required this.imageUrl,
    required this.isPlaying,
    required this.rotationController,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isPlaying ? 260 : 220,
      height: isPlaying ? 260 : 220,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(isPlaying ? 0.5 : 0.2),
            blurRadius: isPlaying ? 50 : 20,
            spreadRadius: isPlaying ? 10 : 0,
          ),
        ],
      ),
      child: RotationTransition(
        turns: isPlaying ? rotationController : const AlwaysStoppedAnimation(0),
        child: ClipOval(
          child: imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _placeholder(),
                )
              : _placeholder(),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.playerGradient),
      child: const Icon(
        Icons.music_note_rounded,
        color: Colors.white54,
        size: 80,
      ),
    );
  }
}

class _LyricsView extends StatelessWidget {
  final String lyrics;
  const _LyricsView({required this.lyrics});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 260,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: lyrics.isEmpty
          ? Center(
              child: Text(
                'No lyrics available',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontFamily: 'Poppins',
                ),
              ),
            )
          : SingleChildScrollView(
              child: Text(
                lyrics,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  height: 1.8,
                ),
                textAlign: TextAlign.center,
              ),
            ),
    );
  }
}
