import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/song_model.dart';
import '../../providers/song_provider.dart';
import '../../services/audio_player_service.dart';
import '../../widgets/song_card.dart';
import '../../widgets/shimmer_loading.dart';
import '../song_detail/song_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _selectedLanguage = 'All';
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() => _hasSearched = query.isNotEmpty);
    context.read<SongProvider>().search(query);
  }

  void _playSong(song, List<SongModel> songs) {
    final player = context.read<AudioPlayerService>();
    player.playSong(song, queue: songs);
    context.read<SongProvider>().incrementPlayCount(song.id);
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, animation, __) => SongDetailScreen(song: song),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                .animate(
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
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final songProvider = context.watch<SongProvider>();
    final player = context.watch<AudioPlayerService>();

    // Filter search results by language
    final results = _selectedLanguage == 'All'
        ? songProvider.searchResults
        : songProvider.searchResults
            .where((s) => s.language == _selectedLanguage)
            .toList();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Text(
                'Search',
                style: TextStyle(
                  color: isDark ? AppColors.textPrimary : AppColors.textDark,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isDark ? AppColors.darkDivider : AppColors.lightDivider,
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: _onSearch,
                  style: TextStyle(
                    color: isDark ? AppColors.textPrimary : AppColors.textDark,
                    fontFamily: 'Poppins',
                  ),
                  decoration: InputDecoration(
                    hintText: 'Search songs, artists...',
                    hintStyle: TextStyle(
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textDarkSecondary,
                      fontFamily: 'Poppins',
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: isDark
                          ? AppColors.textMuted
                          : AppColors.textDarkSecondary,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: isDark
                                  ? AppColors.textMuted
                                  : AppColors.textDarkSecondary,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _onSearch('');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Language filter
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ['All', ...AppConstants.languages].map((lang) {
                  final isSelected = _selectedLanguage == lang;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedLanguage = lang),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppColors.primaryGradient : null,
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
                        lang,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark
                                  ? AppColors.textSecondary
                                  : AppColors.textDarkSecondary),
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w400,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Results
            Expanded(
              child: !_hasSearched
                  ? _BrowseCategories(isDark: isDark)
                  : songProvider.isSearching
                      ? const ShimmerList(count: 4)
                      : results.isEmpty
                          ? _NoResults(isDark: isDark)
                          : ListView.builder(
                              itemCount: results.length,
                              itemBuilder: (_, i) {
                                final song = results[i];
                                return SongCard(
                                  song: song,
                                  isPlaying: player.currentSong?.id == song.id,
                                  onTap: () => _playSong(song, results),
                                );
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseCategories extends StatelessWidget {
  final bool isDark;
  const _BrowseCategories({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {
        'label': 'Afaan Oromo',
        'icon': Icons.language_rounded,
        'color': const Color(0xFF7C4DFF),
      },
      {
        'label': 'English',
        'icon': Icons.translate_rounded,
        'color': const Color(0xFF2196F3),
      },
      {
        'label': 'Amharic',
        'icon': Icons.record_voice_over_rounded,
        'color': const Color(0xFF4CAF50),
      },
      {
        'label': 'Featured',
        'icon': Icons.star_rounded,
        'color': const Color(0xFFFFD700),
      },
      {
        'label': 'Trending',
        'icon': Icons.trending_up_rounded,
        'color': const Color(0xFFFF5252),
      },
      {
        'label': 'New',
        'icon': Icons.new_releases_rounded,
        'color': const Color(0xFFFF9800),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Browse Categories',
            style: TextStyle(
              color: isDark ? AppColors.textPrimary : AppColors.textDark,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.8,
              ),
              itemCount: categories.length,
              itemBuilder: (_, i) {
                final cat = categories[i];
                final color = cat['color'] as Color;
                return Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Icon(
                          cat['icon'] as IconData,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          cat['label'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  final bool isDark;
  const _NoResults({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: isDark ? AppColors.textMuted : AppColors.textDarkSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            'No results found',
            style: TextStyle(
              color: isDark
                  ? AppColors.textSecondary
                  : AppColors.textDarkSecondary,
              fontSize: 16,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search term',
            style: TextStyle(
              color: isDark ? AppColors.textMuted : AppColors.textDarkSecondary,
              fontSize: 13,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
