import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../models/song_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/audio_player_service.dart';
import '../player/player_screen.dart';

class SongDetailScreen extends StatefulWidget {
  final SongModel song;

  const SongDetailScreen({super.key, required this.song});

  @override
  State<SongDetailScreen> createState() => _SongDetailScreenState();
}

class _SongDetailScreenState extends State<SongDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final auth = context.watch<AuthProvider>();
    final isCurrentSong = player.currentSong?.id == widget.song.id;
    final isFav = auth.isFavorite(widget.song.id);

    return Scaffold(
      body: Stack(
        children: [
          // Background image with blur
          if (widget.song.imageUrl.isNotEmpty)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: widget.song.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.playerGradient,
                  ),
                ),
              ),
            ),
          // Dark overlay
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.9),
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
                // App bar
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
                          'Song Details',
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
                        onPressed: () {
                          Share.share(
                            '🎵 Listen to "${widget.song.title}" by ${widget.song.artist} on Faarfanna Obbolootaa',
                          );
                        },
                        icon: const Icon(
                          Icons.share_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Album art
                        Hero(
                          tag: 'song_image_${widget.song.id}',
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 40,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: widget.song.imageUrl.isNotEmpty
                                  ? CachedNetworkImage(
                                      imageUrl: widget.song.imageUrl,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) =>
                                          _placeholder(),
                                    )
                                  : _placeholder(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Song info
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.song.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Poppins',
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.song.artist,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.7),
                                      fontSize: 15,
                                      fontFamily: 'Poppins',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppUtils.getLanguageColor(
                                        widget.song.language,
                                      ).withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${AppUtils.getLanguageFlag(widget.song.language)} ${widget.song.language}',
                                      style: TextStyle(
                                        color: AppUtils.getLanguageColor(
                                          widget.song.language,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'Poppins',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Favorite button — only functional for admin
                            GestureDetector(
                              onTap: () {
                                if (!auth.isAdmin) return; // guests can't save
                                auth.toggleFavorite(widget.song.id);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 48,
                                height: 48,
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
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // Play button
                        GestureDetector(
                          onTap: () {
                            if (isCurrentSong) {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, animation, __) =>
                                      const PlayerScreen(),
                                  transitionsBuilder:
                                      (_, animation, __, child) {
                                    return SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 1),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        ),
                                      ),
                                      child: child,
                                    );
                                  },
                                ),
                              );
                            } else {
                              final playerService =
                                  context.read<AudioPlayerService>();
                              playerService.playSong(widget.song);
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 56,
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.4),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  isCurrentSong && player.isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isCurrentSong && player.isPlaying
                                      ? 'Now Playing'
                                      : 'Play Song',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Poppins',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),

                        // Tabs
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabController,
                            indicator: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            labelColor: Colors.white,
                            unselectedLabelColor: Colors.white54,
                            labelStyle: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            dividerColor: Colors.transparent,
                            tabs: const [
                              Tab(text: 'Lyrics'),
                              Tab(text: 'Info'),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Tab content
                        SizedBox(
                          height: 300,
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // Lyrics tab
                              _LyricsTab(song: widget.song),
                              // Info tab
                              _InfoTab(song: widget.song),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
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

class _LyricsTab extends StatelessWidget {
  final SongModel song;
  const _LyricsTab({required this.song});

  @override
  Widget build(BuildContext context) {
    if (song.lyrics.isEmpty) {
      return Center(
        child: Text(
          'No lyrics available',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontFamily: 'Poppins',
          ),
        ),
      );
    }
    return SingleChildScrollView(
      child: Text(
        song.lyrics,
        style: TextStyle(
          color: Colors.white.withOpacity(0.85),
          fontSize: 15,
          fontFamily: 'Poppins',
          height: 1.8,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _InfoTab extends StatelessWidget {
  final SongModel song;
  const _InfoTab({required this.song});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _InfoRow(label: 'Title', value: song.title),
          _InfoRow(label: 'Artist', value: song.artist),
          _InfoRow(label: 'Language', value: song.language),
          if (song.albumName != null)
            _InfoRow(label: 'Album', value: song.albumName!),
          _InfoRow(label: 'Added', value: AppUtils.timeAgo(song.createdAt)),
          _InfoRow(label: 'Plays', value: '${song.playCount} times'),
          if (song.duration != null)
            _InfoRow(
              label: 'Duration',
              value: AppUtils.formatDuration(song.duration!),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
                fontFamily: 'Poppins',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
