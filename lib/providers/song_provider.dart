import 'package:flutter/foundation.dart';
import '../models/song_model.dart';
import '../services/song_service.dart';

class SongProvider extends ChangeNotifier {
  final SongService _songService = SongService();

  List<SongModel> _allSongs = [];
  List<SongModel> _featuredSongs = [];
  List<SongModel> _recentSongs = [];
  List<SongModel> _trendingSongs = [];
  List<SongModel> _searchResults = [];
  List<SongModel> _filteredSongs = [];
  String _selectedLanguage = 'All';
  bool _isLoading = false;
  bool _isSearching = false;
  String? _errorMessage;

  List<SongModel> get allSongs => _allSongs;
  List<SongModel> get featuredSongs => _featuredSongs;
  List<SongModel> get recentSongs => _recentSongs;
  List<SongModel> get trendingSongs => _trendingSongs;
  List<SongModel> get searchResults => _searchResults;
  List<SongModel> get filteredSongs => _filteredSongs;
  String get selectedLanguage => _selectedLanguage;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;
  String? get errorMessage => _errorMessage;

  SongProvider() {
    _initStreams();
    _loadInitialData();
  }

  void _initStreams() {
    _songService.getSongsStream().listen((songs) {
      _allSongs = songs;
      _applyLanguageFilter();
      notifyListeners();
    });

    _songService.getFeaturedSongs().listen((songs) {
      _featuredSongs = songs;
      notifyListeners();
    });
  }

  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();
    try {
      _recentSongs = await _songService.getRecentSongs();
      _trendingSongs = await _songService.getTrendingSongs();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await _loadInitialData();
  }

  void filterByLanguage(String language) {
    _selectedLanguage = language;
    _applyLanguageFilter();
    notifyListeners();
  }

  void _applyLanguageFilter() {
    if (_selectedLanguage == 'All') {
      _filteredSongs = List.from(_allSongs);
    } else {
      _filteredSongs =
          _allSongs.where((s) => s.language == _selectedLanguage).toList();
    }
  }

  Future<void> search(String query) async {
    if (query.isEmpty) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    try {
      _searchResults = await _songService.searchSongs(query);
    } catch (e) {
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  Future<List<SongModel>> getFavoriteSongs(List<String> ids) async {
    return await _songService.getSongsByIds(ids);
  }

  Future<void> incrementPlayCount(String id) async {
    await _songService.incrementPlayCount(id);
  }

  // Admin operations — these rethrow on failure so the UI can show the error
  Future<void> addSong(SongModel song) async {
    await _songService.addSong(song);
  }

  Future<void> updateSong(SongModel song) async {
    await _songService.updateSong(song);
  }

  Future<bool> deleteSong(String id) async {
    try {
      await _songService.deleteSong(id);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> toggleFeatured(String id, bool featured) async {
    try {
      await _songService.toggleFeatured(id, featured);
      return true;
    } catch (_) {
      return false;
    }
  }
}
