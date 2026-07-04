import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/song_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/song_provider.dart';
import '../../services/audio_player_service.dart';
import '../../widgets/featured_card.dart';
import '../../widgets/song_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../admin/upload_song_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedLanguage = 'All';

  final List<String> _filters = ['All', ...AppConstants.languages];

  void _playSong(BuildContext context, SongModel song, List<SongModel> songs) {
    final player = context.read<AudioPlayerService>();
    player.playSong(song, queue: songs);
    context.read<SongProvider>().incrementPlayCount(song.id);
    // Song plays directly without navigating to detail page
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final songProvider = context.watch<SongProvider>();
    final player = context.watch<AudioPlayerService>();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: RefreshIndicator(
        onRefresh: () => songProvider.refresh(),
        color: AppColors.primary,
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120,
              floating: true,
              snap: true,
              backgroundColor:
                  isDark ? AppColors.darkBackground : AppColors.lightBackground,
              flexibleSpace: FlexibleSpaceBar(
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.textSecondary
                                    : AppColors.textDarkSecondary,
                                fontSize: 13,
                                fontFamily: 'Poppins',
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'Worship Together',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Language filter chips
                  SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _filters.length,
                      itemBuilder: (_, i) {
                        final filter = _filters[i];
                        final isSelected = _selectedLanguage == filter;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedLanguage = filter);
                            songProvider.filterByLanguage(filter);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient:
                                  isSelected ? AppColors.primaryGradient : null,
                              color: isSelected
                                  ? null
                                  : (isDark
                                      ? AppColors.darkCard
                                      : AppColors.lightCard),
                              borderRadius: BorderRadius.circular(20),
                              border: isSelected
                                  ? null
                                  : Border.all(
                                      color: isDark
                                          ? AppColors.darkDivider
                                          : AppColors.lightDivider,
                                    ),
                            ),
                            child: Text(
                              filter,
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.textSecondary
                                        : AppColors.textDarkSecondary),
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                                fontFamily: 'Poppins',
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Featured Songs
                  if (songProvider.featuredSongs.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Featured',
                      onSeeAll: () {},
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 170,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 16),
                        itemCount: songProvider.featuredSongs.length,
                        itemBuilder: (_, i) {
                          final song = songProvider.featuredSongs[i];
                          return FeaturedCard(
                            song: song,
                            onTap: () => _playSong(
                              context,
                              song,
                              songProvider.featuredSongs,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // Trending
                  if (songProvider.trendingSongs.isNotEmpty) ...[
                    _SectionHeader(
                      title: 'Trending',
                      onSeeAll: () {},
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 170,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.only(left: 16),
                        itemCount: songProvider.trendingSongs.take(6).length,
                        itemBuilder: (_, i) {
                          final song = songProvider.trendingSongs[i];
                          return FeaturedCard(
                            song: song,
                            onTap: () => _playSong(
                              context,
                              song,
                              songProvider.trendingSongs,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // All Songs
                  _SectionHeader(
                    title: _selectedLanguage == 'All'
                        ? 'All Songs'
                        : '$_selectedLanguage Songs',
                    onSeeAll: null,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            // Songs list
            if (songProvider.isLoading)
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, __) => const ShimmerSongCard(),
                  childCount: 6,
                ),
              )
            else if (songProvider.filteredSongs.isEmpty)
              SliverToBoxAdapter(child: _EmptyState(isDark: isDark))
            else
              SliverList(
                delegate: SliverChildBuilderDelegate((_, i) {
                  final song = songProvider.filteredSongs[i];
                  return SongCard(
                    song: song,
                    isPlaying: player.currentSong?.id == song.id,
                    onTap: () =>
                        _playSong(context, song, songProvider.filteredSongs),
                  );
                }, childCount: songProvider.filteredSongs.length),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
      floatingActionButton: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          // Only show upload button for admin users
          if (!auth.isAdmin) return const SizedBox.shrink();

          return FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const UploadSongScreen(),
                ),
              );
            },
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text(
              'Upload Song',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning 🌅';
    if (hour < 17) return 'Good Afternoon ☀️';
    return 'Good Evening 🌙';
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.onSeeAll,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'See All',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool isDark;
  const _EmptyState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.music_off_rounded,
            size: 64,
            color: isDark ? AppColors.textMuted : AppColors.textDarkSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No songs found',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textDarkSecondary,
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
