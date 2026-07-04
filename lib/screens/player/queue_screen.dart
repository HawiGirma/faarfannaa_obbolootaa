import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_utils.dart';
import '../../services/audio_player_service.dart';
import '../../models/song_model.dart';

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<AudioPlayerService>();
    final queue = player.queue;
    final currentIndex = player.currentIndex;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0E21),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close_rounded, color: Colors.white),
        ),
        title: const Text(
          'Now Playing Queue',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
      ),
      body: queue.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.queue_music_rounded,
                    size: 80,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No songs in queue',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 16,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: queue.length,
              itemBuilder: (context, index) {
                final song = queue[index];
                final isCurrentSong = index == currentIndex;

                return _QueueItem(
                  song: song,
                  isCurrentSong: isCurrentSong,
                  index: index,
                  onTap: () {
                    player.playQueueItem(index);
                    Navigator.pop(context);
                  },
                );
              },
            ),
    );
  }
}

class _QueueItem extends StatelessWidget {
  final SongModel song;
  final bool isCurrentSong;
  final int index;
  final VoidCallback onTap;

  const _QueueItem({
    required this.song,
    required this.isCurrentSong,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentSong
              ? AppColors.primary.withValues(alpha: 0.15)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCurrentSong
                ? AppColors.primary.withValues(alpha: 0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Album art
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 50,
                height: 50,
                child: song.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: song.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _placeholder(),
                      )
                    : _placeholder(),
              ),
            ),
            const SizedBox(width: 12),

            // Song info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      color: isCurrentSong ? AppColors.primary : Colors.white,
                      fontSize: 15,
                      fontWeight:
                          isCurrentSong ? FontWeight.w600 : FontWeight.w500,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    song.artist,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Duration and play indicator
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isCurrentSong)
                  Icon(
                    Icons.equalizer_rounded,
                    color: AppColors.primary,
                    size: 20,
                  )
                else if (song.duration != null)
                  Text(
                    AppUtils.formatDuration(song.duration!),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                      fontFamily: 'Poppins',
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: Colors.white.withValues(alpha: 0.1),
      child: Icon(
        Icons.music_note_rounded,
        color: Colors.white.withValues(alpha: 0.3),
        size: 24,
      ),
    );
  }
}
