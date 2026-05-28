import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../models/song_model.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/app_utils.dart';

class SongCard extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;
  final bool isPlaying;
  final bool showLanguageBadge;

  const SongCard({
    super.key,
    required this.song,
    required this.onTap,
    this.isPlaying = false,
    this.showLanguageBadge = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textColor = isDark ? AppColors.textPrimary : AppColors.textDark;
    final subColor = isDark
        ? AppColors.textSecondary
        : AppColors.textDarkSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isPlaying ? AppColors.primary.withOpacity(0.15) : cardColor,
          borderRadius: BorderRadius.circular(16),
          border: isPlaying
              ? Border.all(color: AppColors.primary.withOpacity(0.5), width: 1)
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: song.imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: song.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => _shimmerBox(),
                          errorWidget: (_, __, ___) => _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isPlaying ? AppColors.primary : textColor,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      style: TextStyle(
                        fontSize: 13,
                        color: subColor,
                        fontFamily: 'Poppins',
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (showLanguageBadge) ...[
                      const SizedBox(height: 6),
                      _LanguageBadge(language: song.language),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Play indicator or duration
              if (isPlaying)
                _PlayingIndicator()
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (song.duration != null)
                      Text(
                        AppUtils.formatDuration(song.duration!),
                        style: TextStyle(
                          fontSize: 12,
                          color: subColor,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.play_circle_outline_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _shimmerBox() {
    return Shimmer.fromColors(
      baseColor: AppColors.darkCard,
      highlightColor: AppColors.darkCardElevated,
      child: Container(color: AppColors.darkCard),
    );
  }

  Widget _placeholderImage() {
    return Container(
      color: AppColors.primary.withOpacity(0.2),
      child: const Icon(
        Icons.music_note_rounded,
        color: AppColors.primary,
        size: 28,
      ),
    );
  }
}

class _LanguageBadge extends StatelessWidget {
  final String language;
  const _LanguageBadge({required this.language});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppUtils.getLanguageColor(language).withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${AppUtils.getLanguageFlag(language)} $language',
        style: TextStyle(
          fontSize: 10,
          color: AppUtils.getLanguageColor(language),
          fontWeight: FontWeight.w600,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}

class _PlayingIndicator extends StatefulWidget {
  @override
  State<_PlayingIndicator> createState() => _PlayingIndicatorState();
}

class _PlayingIndicatorState extends State<_PlayingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + i * 100),
      )..repeat(reverse: true),
    );
    _animations = _controllers
        .map(
          (c) => Tween<double>(
            begin: 4,
            end: 20,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _animations[i],
            builder: (_, __) => Container(
              width: 4,
              height: _animations[i].value,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
