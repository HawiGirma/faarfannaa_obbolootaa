import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/bible_models.dart';

/// Service for managing Bible data and user interactions
class BibleService {
  static const String _highlightsKey = 'bible_highlights';
  static const String _bookmarksKey = 'bible_bookmarks';
  static const String _notesKey = 'bible_notes';
  static const String _preferencesKey = 'bible_preferences';
  static const String _progressKey = 'bible_progress';
  static const String _customFontsKey = 'bible_custom_fonts';

  final SharedPreferences _prefs;
  final Uuid _uuid = const Uuid();

  BibleService(this._prefs);

  // Cache for the loaded Bible data
  Map<String, dynamic>? _bibleData;

  // ──────────────────────────────────────────────────────────────────────
  // Bible Data Loading
  // ──────────────────────────────────────────────────────────────────────

  /// Load and cache the Bible data from JSON
  Future<Map<String, dynamic>> _loadBibleData() async {
    if (_bibleData != null) return _bibleData!;

    try {
      final String jsonString =
          await rootBundle.loadString('assets/JSON/afaan_oromo_bible.json');
      _bibleData = json.decode(jsonString);
      return _bibleData!;
    } catch (e) {
      print('Error loading Bible data: $e');
      rethrow;
    }
  }

  /// Load list of all Bible books with metadata
  Future<List<BibleBook>> loadBibleBooks() async {
    try {
      final bibleData = await _loadBibleData();
      final List<dynamic> books = bibleData['books'] ?? [];

      // Get unique books (JSON has duplicates) - prioritize entries with chapters
      final Map<int, Map<String, dynamic>> uniqueBooks = {};
      for (var bookJson in books) {
        final id = bookJson['id'] as int;
        final chapters = bookJson['chapters'] as List?;
        final hasChapters = chapters != null && chapters.isNotEmpty;

        // If this book ID isn't in the map yet, OR the current entry has chapters and the stored one doesn't
        if (!uniqueBooks.containsKey(id) ||
            (hasChapters &&
                (uniqueBooks[id]!['chapters'] as List?)?.isEmpty != false)) {
          uniqueBooks[id] = bookJson;
        }
      }

      return uniqueBooks.values
          .map((bookJson) {
            final chapters = (bookJson['chapters'] as List?)
                ?.where((ch) => (ch['verses'] as List?)?.isNotEmpty == true)
                .toList();
            final chapterCount = chapters?.length ?? 0;

            print('Book: ${bookJson['name']}, chapters: $chapterCount');

            return BibleBook(
              name: bookJson['name'] as String,
              abbreviation: bookJson['abbreviation'] as String,
              totalChapters: chapterCount,
            );
          })
          .where((book) => book.totalChapters > 0)
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
    } catch (e) {
      print('Error loading Bible books: $e');
      return [];
    }
  }

  /// Load a specific chapter from a book
  Future<BibleChapter> loadChapter(
    String bookName,
    int chapterNumber,
  ) async {
    try {
      final bibleData = await _loadBibleData();
      final List<dynamic> books = bibleData['books'] ?? [];

      // Find the book with matching name
      Map<String, dynamic>? targetBook;
      for (var bookJson in books) {
        if (bookJson['name'] == bookName) {
          final chapters = bookJson['chapters'] as List?;
          if (chapters != null && chapters.isNotEmpty) {
            targetBook = bookJson;
            break;
          }
        }
      }

      if (targetBook == null) {
        throw Exception('Book $bookName not found');
      }

      // Find the chapter
      final List<dynamic> chapters = targetBook['chapters'] ?? [];
      final chapterData = chapters.firstWhere(
        (ch) => ch['chapter'] == chapterNumber,
        orElse: () => null,
      );

      if (chapterData == null) {
        throw Exception('Chapter $chapterNumber not found in $bookName');
      }

      // Parse verses
      final List<dynamic> versesJson = chapterData['verses'] ?? [];
      final verses = versesJson.map((verseJson) {
        return BibleVerse(
          number: verseJson['verse'] as int,
          text: verseJson['text'] as String,
        );
      }).toList();

      return BibleChapter(
        number: chapterNumber,
        verses: verses,
      );
    } catch (e) {
      print('Error loading chapter: $e');
      rethrow;
    }
  }

  /// Search verses across the Bible
  Future<List<SearchResult>> searchVerses(String query) async {
    if (query.trim().isEmpty) return [];

    try {
      final results = <SearchResult>[];
      final bibleData = await _loadBibleData();
      final List<dynamic> books = bibleData['books'] ?? [];

      final lowerQuery = query.toLowerCase();

      // Search through all books
      for (var bookJson in books) {
        final String bookName = bookJson['name'] as String;
        final List<dynamic>? chapters = bookJson['chapters'] as List?;

        if (chapters == null || chapters.isEmpty) continue;

        for (var chapterJson in chapters) {
          final int chapterNum = chapterJson['chapter'] as int;
          final List<dynamic>? verses = chapterJson['verses'] as List?;

          if (verses == null) continue;

          for (var verseJson in verses) {
            final String text = verseJson['text'] as String;
            if (text.toLowerCase().contains(lowerQuery)) {
              results.add(SearchResult(
                bookName: bookName,
                chapter: chapterNum,
                verse: verseJson['verse'] as int,
                text: text,
                query: query,
              ));

              // Limit results to prevent performance issues
              if (results.length >= 100) {
                return results;
              }
            }
          }
        }
      }

      return results;
    } catch (e) {
      print('Error searching verses: $e');
      return [];
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // Highlights
  // ──────────────────────────────────────────────────────────────────────

  Future<List<VerseHighlight>> getHighlights() async {
    final String? data = _prefs.getString(_highlightsKey);
    if (data == null) return [];

    final List<dynamic> list = json.decode(data);
    return list.map((json) => VerseHighlight.fromJson(json)).toList();
  }

  Future<void> addHighlight(VerseHighlight highlight) async {
    final highlights = await getHighlights();

    // Remove existing highlight for this verse
    highlights.removeWhere((h) =>
        h.bookName == highlight.bookName &&
        h.chapter == highlight.chapter &&
        h.verse == highlight.verse);

    highlights.add(highlight);
    await _prefs.setString(
      _highlightsKey,
      json.encode(highlights.map((h) => h.toJson()).toList()),
    );
  }

  Future<void> removeHighlight(
    String bookName,
    int chapter,
    int verse,
  ) async {
    final highlights = await getHighlights();
    highlights.removeWhere((h) =>
        h.bookName == bookName && h.chapter == chapter && h.verse == verse);
    await _prefs.setString(
      _highlightsKey,
      json.encode(highlights.map((h) => h.toJson()).toList()),
    );
  }

  Future<String?> getHighlightColor(
    String bookName,
    int chapter,
    int verse,
  ) async {
    final highlights = await getHighlights();
    final highlight = highlights.firstWhere(
      (h) => h.bookName == bookName && h.chapter == chapter && h.verse == verse,
      orElse: () => VerseHighlight(
        bookName: '',
        chapter: 0,
        verse: 0,
        color: '',
        createdAt: DateTime.now(),
      ),
    );
    return highlight.bookName.isEmpty ? null : highlight.color;
  }

  // ──────────────────────────────────────────────────────────────────────
  // Bookmarks
  // ──────────────────────────────────────────────────────────────────────

  Future<List<VerseBookmark>> getBookmarks() async {
    final String? data = _prefs.getString(_bookmarksKey);
    if (data == null) return [];

    final List<dynamic> list = json.decode(data);
    return list.map((json) => VerseBookmark.fromJson(json)).toList();
  }

  Future<void> addBookmark(String bookName, int chapter, int verse) async {
    final bookmarks = await getBookmarks();

    // Check if bookmark already exists
    if (bookmarks.any((b) =>
        b.bookName == bookName && b.chapter == chapter && b.verse == verse)) {
      return;
    }

    bookmarks.add(VerseBookmark(
      id: _uuid.v4(),
      bookName: bookName,
      chapter: chapter,
      verse: verse,
      createdAt: DateTime.now(),
    ));

    await _prefs.setString(
      _bookmarksKey,
      json.encode(bookmarks.map((b) => b.toJson()).toList()),
    );
  }

  Future<void> removeBookmark(String bookmarkId) async {
    final bookmarks = await getBookmarks();
    bookmarks.removeWhere((b) => b.id == bookmarkId);
    await _prefs.setString(
      _bookmarksKey,
      json.encode(bookmarks.map((b) => b.toJson()).toList()),
    );
  }

  Future<bool> isBookmarked(
    String bookName,
    int chapter,
    int verse,
  ) async {
    final bookmarks = await getBookmarks();
    return bookmarks.any((b) =>
        b.bookName == bookName && b.chapter == chapter && b.verse == verse);
  }

  // ──────────────────────────────────────────────────────────────────────
  // Notes
  // ──────────────────────────────────────────────────────────────────────

  Future<List<VerseNote>> getNotes() async {
    final String? data = _prefs.getString(_notesKey);
    if (data == null) return [];

    final List<dynamic> list = json.decode(data);
    return list.map((json) => VerseNote.fromJson(json)).toList();
  }

  Future<void> addOrUpdateNote(
    String bookName,
    int chapter,
    int verse,
    String noteText,
  ) async {
    final notes = await getNotes();

    // Check if note already exists
    final existingIndex = notes.indexWhere((n) =>
        n.bookName == bookName && n.chapter == chapter && n.verse == verse);

    if (existingIndex != -1) {
      // Update existing note
      notes[existingIndex] = notes[existingIndex].copyWith(
        note: noteText,
        updatedAt: DateTime.now(),
      );
    } else {
      // Add new note
      notes.add(VerseNote(
        id: _uuid.v4(),
        bookName: bookName,
        chapter: chapter,
        verse: verse,
        note: noteText,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
    }

    await _prefs.setString(
      _notesKey,
      json.encode(notes.map((n) => n.toJson()).toList()),
    );
  }

  Future<void> deleteNote(String noteId) async {
    final notes = await getNotes();
    notes.removeWhere((n) => n.id == noteId);
    await _prefs.setString(
      _notesKey,
      json.encode(notes.map((n) => n.toJson()).toList()),
    );
  }

  Future<VerseNote?> getNote(
    String bookName,
    int chapter,
    int verse,
  ) async {
    final notes = await getNotes();
    try {
      return notes.firstWhere((n) =>
          n.bookName == bookName && n.chapter == chapter && n.verse == verse);
    } catch (e) {
      return null;
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // Reading Preferences
  // ──────────────────────────────────────────────────────────────────────

  Future<ReadingPreferences> getPreferences() async {
    final String? data = _prefs.getString(_preferencesKey);
    if (data == null) return ReadingPreferences();

    return ReadingPreferences.fromJson(json.decode(data));
  }

  Future<void> savePreferences(ReadingPreferences preferences) async {
    await _prefs.setString(
      _preferencesKey,
      json.encode(preferences.toJson()),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // Reading Progress
  // ──────────────────────────────────────────────────────────────────────

  Future<ReadingProgress?> getProgress() async {
    final String? data = _prefs.getString(_progressKey);
    if (data == null) return null;

    return ReadingProgress.fromJson(json.decode(data));
  }

  Future<void> saveProgress(ReadingProgress progress) async {
    await _prefs.setString(
      _progressKey,
      json.encode(progress.toJson()),
    );
  }

  // ──────────────────────────────────────────────────────────────────────
  // Custom Fonts
  // ──────────────────────────────────────────────────────────────────────

  Future<List<String>> getCustomFonts() async {
    final String? data = _prefs.getString(_customFontsKey);
    if (data == null) return [];

    return List<String>.from(json.decode(data));
  }

  Future<String> addCustomFont(File fontFile) async {
    final appDir = await getApplicationDocumentsDirectory();
    final fontsDir = Directory('${appDir.path}/custom_fonts');
    if (!await fontsDir.exists()) {
      await fontsDir.create(recursive: true);
    }

    final fileName = fontFile.path.split('/').last;
    final targetPath = '${fontsDir.path}/$fileName';
    await fontFile.copy(targetPath);

    final customFonts = await getCustomFonts();
    if (!customFonts.contains(fileName)) {
      customFonts.add(fileName);
      await _prefs.setString(_customFontsKey, json.encode(customFonts));
    }

    return targetPath;
  }

  Future<void> removeCustomFont(String fontName) async {
    final customFonts = await getCustomFonts();
    customFonts.remove(fontName);
    await _prefs.setString(_customFontsKey, json.encode(customFonts));

    // Delete the font file
    final appDir = await getApplicationDocumentsDirectory();
    final fontPath = '${appDir.path}/custom_fonts/$fontName';
    final file = File(fontPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // ──────────────────────────────────────────────────────────────────────
  // Helper Methods
  // ──────────────────────────────────────────────────────────────────────

  /// Get book information by ID
  Future<Map<String, dynamic>?> getBookById(int bookId) async {
    final bibleData = await _loadBibleData();
    final List<dynamic> books = bibleData['books'] ?? [];

    for (var bookJson in books) {
      if (bookJson['id'] == bookId) {
        return bookJson as Map<String, dynamic>;
      }
    }
    return null;
  }
}

/// Search result model
class SearchResult {
  final String bookName;
  final int chapter;
  final int verse;
  final String text;
  final String query;

  SearchResult({
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.text,
    required this.query,
  });

  String get reference => '$bookName $chapter:$verse';
}
