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

  // ──────────────────────────────────────────────────────────────────────
  // Bible Data Loading
  // ──────────────────────────────────────────────────────────────────────

  /// Load list of all Bible books with metadata
  Future<List<BibleBook>> loadBibleBooks() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/bible/books.json');
      final List<dynamic> data = json.decode(jsonString);
      return data.map((json) => BibleBook.fromJson(json)).toList();
    } catch (e) {
      // If file doesn't exist, return hardcoded book list
      return _getDefaultBibleBooks();
    }
  }

  /// Load a specific chapter from a book
  Future<BibleChapter> loadChapter(
    String bookName,
    int chapterNumber,
  ) async {
    try {
      // Try to load from assets first
      final bookAbbr = _getBookAbbreviation(bookName);
      final String jsonString = await rootBundle
          .loadString('assets/bible/${bookAbbr}_$chapterNumber.json');
      final Map<String, dynamic> data = json.decode(jsonString);
      return BibleChapter.fromJson(data);
    } catch (e) {
      // Return sample chapter if file doesn't exist
      return _getSampleChapter(bookName, chapterNumber);
    }
  }

  /// Search verses across the Bible
  Future<List<SearchResult>> searchVerses(String query) async {
    // This is a simplified implementation
    // In production, you'd use a full-text search database
    final results = <SearchResult>[];
    final books = await loadBibleBooks();

    // Search through first few chapters of each book for demo
    for (final book in books.take(5)) {
      for (int chapterNum = 1;
          chapterNum <= (book.totalChapters > 3 ? 3 : book.totalChapters);
          chapterNum++) {
        try {
          final chapter = await loadChapter(book.name, chapterNum);
          for (final verse in chapter.verses) {
            if (verse.text.toLowerCase().contains(query.toLowerCase())) {
              results.add(SearchResult(
                bookName: book.name,
                chapter: chapterNum,
                verse: verse.number,
                text: verse.text,
                query: query,
              ));
            }
          }
        } catch (e) {
          // Skip chapters that fail to load
        }
      }
    }

    return results;
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

  String _getBookAbbreviation(String bookName) {
    final bookMap = {
      'Genesis': 'gen',
      'Exodus': 'exo',
      'John': 'jhn',
      'Romans': 'rom',
      'Revelation': 'rev',
      // Add more mappings as needed
    };
    return bookMap[bookName] ?? bookName.toLowerCase().substring(0, 3);
  }

  List<BibleBook> _getDefaultBibleBooks() {
    return [
      BibleBook(name: 'Genesis', abbreviation: 'Gen', totalChapters: 50),
      BibleBook(name: 'Exodus', abbreviation: 'Exo', totalChapters: 40),
      BibleBook(name: 'Leviticus', abbreviation: 'Lev', totalChapters: 27),
      BibleBook(name: 'Numbers', abbreviation: 'Num', totalChapters: 36),
      BibleBook(name: 'Deuteronomy', abbreviation: 'Deu', totalChapters: 34),
      BibleBook(name: 'Joshua', abbreviation: 'Jos', totalChapters: 24),
      BibleBook(name: 'Judges', abbreviation: 'Jdg', totalChapters: 21),
      BibleBook(name: 'Ruth', abbreviation: 'Rut', totalChapters: 4),
      BibleBook(name: '1 Samuel', abbreviation: '1Sa', totalChapters: 31),
      BibleBook(name: '2 Samuel', abbreviation: '2Sa', totalChapters: 24),
      BibleBook(name: '1 Kings', abbreviation: '1Ki', totalChapters: 22),
      BibleBook(name: '2 Kings', abbreviation: '2Ki', totalChapters: 25),
      BibleBook(name: '1 Chronicles', abbreviation: '1Ch', totalChapters: 29),
      BibleBook(name: '2 Chronicles', abbreviation: '2Ch', totalChapters: 36),
      BibleBook(name: 'Ezra', abbreviation: 'Ezr', totalChapters: 10),
      BibleBook(name: 'Nehemiah', abbreviation: 'Neh', totalChapters: 13),
      BibleBook(name: 'Esther', abbreviation: 'Est', totalChapters: 10),
      BibleBook(name: 'Job', abbreviation: 'Job', totalChapters: 42),
      BibleBook(name: 'Psalms', abbreviation: 'Psa', totalChapters: 150),
      BibleBook(name: 'Proverbs', abbreviation: 'Pro', totalChapters: 31),
      BibleBook(name: 'Ecclesiastes', abbreviation: 'Ecc', totalChapters: 12),
      BibleBook(name: 'Song of Solomon', abbreviation: 'SoS', totalChapters: 8),
      BibleBook(name: 'Isaiah', abbreviation: 'Isa', totalChapters: 66),
      BibleBook(name: 'Jeremiah', abbreviation: 'Jer', totalChapters: 52),
      BibleBook(name: 'Lamentations', abbreviation: 'Lam', totalChapters: 5),
      BibleBook(name: 'Ezekiel', abbreviation: 'Eze', totalChapters: 48),
      BibleBook(name: 'Daniel', abbreviation: 'Dan', totalChapters: 12),
      BibleBook(name: 'Hosea', abbreviation: 'Hos', totalChapters: 14),
      BibleBook(name: 'Joel', abbreviation: 'Joe', totalChapters: 3),
      BibleBook(name: 'Amos', abbreviation: 'Amo', totalChapters: 9),
      BibleBook(name: 'Obadiah', abbreviation: 'Oba', totalChapters: 1),
      BibleBook(name: 'Jonah', abbreviation: 'Jon', totalChapters: 4),
      BibleBook(name: 'Micah', abbreviation: 'Mic', totalChapters: 7),
      BibleBook(name: 'Nahum', abbreviation: 'Nah', totalChapters: 3),
      BibleBook(name: 'Habakkuk', abbreviation: 'Hab', totalChapters: 3),
      BibleBook(name: 'Zephaniah', abbreviation: 'Zep', totalChapters: 3),
      BibleBook(name: 'Haggai', abbreviation: 'Hag', totalChapters: 2),
      BibleBook(name: 'Zechariah', abbreviation: 'Zec', totalChapters: 14),
      BibleBook(name: 'Malachi', abbreviation: 'Mal', totalChapters: 4),
      // New Testament
      BibleBook(name: 'Matthew', abbreviation: 'Mat', totalChapters: 28),
      BibleBook(name: 'Mark', abbreviation: 'Mar', totalChapters: 16),
      BibleBook(name: 'Luke', abbreviation: 'Luk', totalChapters: 24),
      BibleBook(name: 'John', abbreviation: 'Jhn', totalChapters: 21),
      BibleBook(name: 'Acts', abbreviation: 'Act', totalChapters: 28),
      BibleBook(name: 'Romans', abbreviation: 'Rom', totalChapters: 16),
      BibleBook(name: '1 Corinthians', abbreviation: '1Co', totalChapters: 16),
      BibleBook(name: '2 Corinthians', abbreviation: '2Co', totalChapters: 13),
      BibleBook(name: 'Galatians', abbreviation: 'Gal', totalChapters: 6),
      BibleBook(name: 'Ephesians', abbreviation: 'Eph', totalChapters: 6),
      BibleBook(name: 'Philippians', abbreviation: 'Phi', totalChapters: 4),
      BibleBook(name: 'Colossians', abbreviation: 'Col', totalChapters: 4),
      BibleBook(name: '1 Thessalonians', abbreviation: '1Th', totalChapters: 5),
      BibleBook(name: '2 Thessalonians', abbreviation: '2Th', totalChapters: 3),
      BibleBook(name: '1 Timothy', abbreviation: '1Ti', totalChapters: 6),
      BibleBook(name: '2 Timothy', abbreviation: '2Ti', totalChapters: 4),
      BibleBook(name: 'Titus', abbreviation: 'Tit', totalChapters: 3),
      BibleBook(name: 'Philemon', abbreviation: 'Phm', totalChapters: 1),
      BibleBook(name: 'Hebrews', abbreviation: 'Heb', totalChapters: 13),
      BibleBook(name: 'James', abbreviation: 'Jam', totalChapters: 5),
      BibleBook(name: '1 Peter', abbreviation: '1Pe', totalChapters: 5),
      BibleBook(name: '2 Peter', abbreviation: '2Pe', totalChapters: 3),
      BibleBook(name: '1 John', abbreviation: '1Jn', totalChapters: 5),
      BibleBook(name: '2 John', abbreviation: '2Jn', totalChapters: 1),
      BibleBook(name: '3 John', abbreviation: '3Jn', totalChapters: 1),
      BibleBook(name: 'Jude', abbreviation: 'Jud', totalChapters: 1),
      BibleBook(name: 'Revelation', abbreviation: 'Rev', totalChapters: 22),
    ];
  }

  BibleChapter _getSampleChapter(String bookName, int chapterNumber) {
    // Return John 3:16 as sample data for demonstration
    if (bookName == 'John' && chapterNumber == 3) {
      return BibleChapter(
        number: 3,
        verses: [
          BibleVerse(
            number: 16,
            text:
                'For God so loved the world that he gave his one and only Son, that whoever believes in him shall not perish but have eternal life.',
          ),
          BibleVerse(
            number: 17,
            text:
                'For God did not send his Son into the world to condemn the world, but to save the world through him.',
          ),
        ],
      );
    }

    // Return generic sample verses for other books/chapters
    return BibleChapter(
      number: chapterNumber,
      verses: List.generate(
        10,
        (i) => BibleVerse(
          number: i + 1,
          text:
              'This is verse ${i + 1} of $bookName chapter $chapterNumber. Bible content would be loaded from a data source.',
        ),
      ),
    );
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
