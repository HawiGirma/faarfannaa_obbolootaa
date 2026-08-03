import 'dart:io';
import 'package:flutter/material.dart';
import '../models/bible_models.dart';
import '../services/bible_service.dart';

/// Provider for managing Bible reading state
class BibleProvider extends ChangeNotifier {
  final BibleService _service;

  BibleProvider(this._service) {
    _init();
  }

  // ── State ───────────────────────────────────────────────────────────────
  List<BibleBook> _books = [];
  BibleBook? _currentBook;
  BibleChapter? _currentChapter;
  List<VerseHighlight> _highlights = [];
  List<VerseBookmark> _bookmarks = [];
  List<VerseNote> _notes = [];
  ReadingPreferences _preferences = ReadingPreferences();
  ReadingProgress? _progress;
  List<String> _customFonts = [];

  bool _isLoading = false;
  bool _isLoadingChapter = false;
  String? _error;

  // Auto-scroll state
  bool _isAutoScrolling = false;
  bool _isAutoScrollPaused = false;

  // ── Getters ─────────────────────────────────────────────────────────────
  List<BibleBook> get books => _books;
  BibleBook? get currentBook => _currentBook;
  BibleChapter? get currentChapter => _currentChapter;
  List<VerseHighlight> get highlights => _highlights;
  List<VerseBookmark> get bookmarks => _bookmarks;
  List<VerseNote> get notes => _notes;
  ReadingPreferences get preferences => _preferences;
  ReadingProgress? get progress => _progress;
  List<String> get customFonts => _customFonts;

  bool get isLoading => _isLoading;
  bool get isLoadingChapter => _isLoadingChapter;
  String? get error => _error;
  bool get isAutoScrolling => _isAutoScrolling;
  bool get isAutoScrollPaused => _isAutoScrollPaused;

  int get selectedVerseCount =>
      _currentChapter?.verses.where((v) => v.isSelected).length ?? 0;

  // ── Initialization ──────────────────────────────────────────────────────
  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load books
      _books = await _service.loadBibleBooks();

      // Load saved data
      _highlights = await _service.getHighlights();
      _bookmarks = await _service.getBookmarks();
      _notes = await _service.getNotes();
      _preferences = await _service.getPreferences();
      _progress = await _service.getProgress();
      _customFonts = await _service.getCustomFonts();

      // Restore last reading position
      if (_progress != null && _books.isNotEmpty) {
        final book = _books.firstWhere(
          (b) => b.name == _progress!.bookName,
          orElse: () => _books.first,
        );
        await loadChapter(book, _progress!.chapter);
      } else if (_books.isNotEmpty) {
        // Load first available book with chapters
        await loadChapter(_books.first, 1);
      }

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Chapter Navigation ──────────────────────────────────────────────────
  Future<void> loadChapter(BibleBook book, int chapterNumber) async {
    _isLoadingChapter = true;
    _error = null;
    notifyListeners();

    try {
      _currentBook = book;
      _currentChapter = await _service.loadChapter(book.name, chapterNumber);

      // Apply highlights to verses
      for (final verse in _currentChapter!.verses) {
        final highlightColor = await _service.getHighlightColor(
          book.name,
          chapterNumber,
          verse.number,
        );
        if (highlightColor != null) {
          verse.highlightColor = highlightColor;
        }
      }

      // Save progress
      _progress = ReadingProgress(
        bookName: book.name,
        chapter: chapterNumber,
        lastRead: DateTime.now(),
      );
      await _service.saveProgress(_progress!);

      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingChapter = false;
      notifyListeners();
    }
  }

  Future<void> goToNextChapter() async {
    if (_currentBook == null || _currentChapter == null) return;

    if (_currentChapter!.number < _currentBook!.totalChapters) {
      await loadChapter(_currentBook!, _currentChapter!.number + 1);
    } else {
      // Move to next book
      final currentIndex = _books.indexOf(_currentBook!);
      if (currentIndex < _books.length - 1) {
        await loadChapter(_books[currentIndex + 1], 1);
      }
    }
  }

  Future<void> goToPreviousChapter() async {
    if (_currentBook == null || _currentChapter == null) return;

    if (_currentChapter!.number > 1) {
      await loadChapter(_currentBook!, _currentChapter!.number - 1);
    } else {
      // Move to previous book's last chapter
      final currentIndex = _books.indexOf(_currentBook!);
      if (currentIndex > 0) {
        final prevBook = _books[currentIndex - 1];
        await loadChapter(prevBook, prevBook.totalChapters);
      }
    }
  }

  // ── Verse Selection ─────────────────────────────────────────────────────
  void toggleVerseSelection(int verseNumber) {
    if (_currentChapter == null) return;

    final verse =
        _currentChapter!.verses.firstWhere((v) => v.number == verseNumber);
    verse.isSelected = !verse.isSelected;
    notifyListeners();
  }

  void selectAllVerses() {
    if (_currentChapter == null) return;

    for (final verse in _currentChapter!.verses) {
      verse.isSelected = true;
    }
    notifyListeners();
  }

  void clearSelection() {
    if (_currentChapter == null) return;

    for (final verse in _currentChapter!.verses) {
      verse.isSelected = false;
    }
    notifyListeners();
  }

  List<BibleVerse> getSelectedVerses() {
    if (_currentChapter == null) return [];
    return _currentChapter!.verses.where((v) => v.isSelected).toList();
  }

  String getSelectedVersesText() {
    final selected = getSelectedVerses();
    if (selected.isEmpty) return '';

    final verses = selected.map((v) => v.text).join(' ');
    final reference = _formatVerseReference(selected);

    return '$reference\n"$verses"';
  }

  String _formatVerseReference(List<BibleVerse> verses) {
    if (verses.isEmpty) return '';
    if (_currentBook == null || _currentChapter == null) return '';

    if (verses.length == 1) {
      return '${_currentBook!.name} ${_currentChapter!.number}:${verses.first.number}';
    } else {
      return '${_currentBook!.name} ${_currentChapter!.number}:${verses.first.number}-${verses.last.number}';
    }
  }

  // ── Highlights ──────────────────────────────────────────────────────────
  Future<void> highlightSelectedVerses(String color) async {
    if (_currentBook == null || _currentChapter == null) return;

    final selected = getSelectedVerses();
    for (final verse in selected) {
      final highlight = VerseHighlight(
        bookName: _currentBook!.name,
        chapter: _currentChapter!.number,
        verse: verse.number,
        color: color,
        createdAt: DateTime.now(),
      );

      await _service.addHighlight(highlight);
      verse.highlightColor = color;
      verse.isSelected = false;
    }

    _highlights = await _service.getHighlights();
    notifyListeners();
  }

  Future<void> removeHighlightFromSelectedVerses() async {
    if (_currentBook == null || _currentChapter == null) return;

    final selected = getSelectedVerses();
    for (final verse in selected) {
      await _service.removeHighlight(
        _currentBook!.name,
        _currentChapter!.number,
        verse.number,
      );
      verse.highlightColor = null;
      verse.isSelected = false;
    }

    _highlights = await _service.getHighlights();
    notifyListeners();
  }

  // ── Bookmarks ───────────────────────────────────────────────────────────
  Future<void> toggleBookmark(int verseNumber) async {
    if (_currentBook == null || _currentChapter == null) return;

    final isBookmarked = await _service.isBookmarked(
      _currentBook!.name,
      _currentChapter!.number,
      verseNumber,
    );

    if (isBookmarked) {
      final bookmark = _bookmarks.firstWhere((b) =>
          b.bookName == _currentBook!.name &&
          b.chapter == _currentChapter!.number &&
          b.verse == verseNumber);
      await _service.removeBookmark(bookmark.id);
    } else {
      await _service.addBookmark(
        _currentBook!.name,
        _currentChapter!.number,
        verseNumber,
      );
    }

    _bookmarks = await _service.getBookmarks();
    notifyListeners();
  }

  Future<bool> isVerseBookmarked(int verseNumber) async {
    if (_currentBook == null || _currentChapter == null) return false;

    return await _service.isBookmarked(
      _currentBook!.name,
      _currentChapter!.number,
      verseNumber,
    );
  }

  // ── Notes ───────────────────────────────────────────────────────────────
  Future<void> addOrUpdateNote(int verseNumber, String noteText) async {
    if (_currentBook == null || _currentChapter == null) return;

    await _service.addOrUpdateNote(
      _currentBook!.name,
      _currentChapter!.number,
      verseNumber,
      noteText,
    );

    _notes = await _service.getNotes();
    notifyListeners();
  }

  Future<void> deleteNote(String noteId) async {
    await _service.deleteNote(noteId);
    _notes = await _service.getNotes();
    notifyListeners();
  }

  Future<VerseNote?> getVerseNote(int verseNumber) async {
    if (_currentBook == null || _currentChapter == null) return null;

    return await _service.getNote(
      _currentBook!.name,
      _currentChapter!.number,
      verseNumber,
    );
  }

  // ── Reading Preferences ─────────────────────────────────────────────────
  Future<void> updateFontSize(double size) async {
    _preferences = _preferences.copyWith(fontSize: size);
    await _service.savePreferences(_preferences);
    notifyListeners();
  }

  Future<void> updateFontFamily(String family, {String? customPath}) async {
    _preferences = _preferences.copyWith(
      fontFamily: family,
      customFontPath: customPath,
    );
    await _service.savePreferences(_preferences);
    notifyListeners();
  }

  Future<void> updateAutoScrollSpeed(double speed) async {
    _preferences = _preferences.copyWith(autoScrollSpeed: speed);
    await _service.savePreferences(_preferences);
    notifyListeners();
  }

  Future<String> addCustomFont(File fontFile) async {
    final path = await _service.addCustomFont(fontFile);
    _customFonts = await _service.getCustomFonts();
    notifyListeners();
    return path;
  }

  Future<void> removeCustomFont(String fontName) async {
    await _service.removeCustomFont(fontName);
    _customFonts = await _service.getCustomFonts();
    notifyListeners();
  }

  // ── Auto-scroll ─────────────────────────────────────────────────────────
  void startAutoScroll() {
    _isAutoScrolling = true;
    _isAutoScrollPaused = false;
    notifyListeners();
  }

  void pauseAutoScroll() {
    _isAutoScrollPaused = true;
    notifyListeners();
  }

  void resumeAutoScroll() {
    _isAutoScrollPaused = false;
    notifyListeners();
  }

  void stopAutoScroll() {
    _isAutoScrolling = false;
    _isAutoScrollPaused = false;
    notifyListeners();
  }

  // ── Progress ────────────────────────────────────────────────────────────
  Future<void> updateScrollOffset(double offset) async {
    if (_currentBook == null || _currentChapter == null) return;

    _progress = ReadingProgress(
      bookName: _currentBook!.name,
      chapter: _currentChapter!.number,
      scrollOffset: offset,
      lastRead: DateTime.now(),
    );
    await _service.saveProgress(_progress!);
  }
}
