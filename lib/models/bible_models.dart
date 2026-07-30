// Bible Data Models

/// Represents a single Bible verse
class BibleVerse {
  final int number;
  final String text;
  bool isSelected;
  String? highlightColor;

  BibleVerse({
    required this.number,
    required this.text,
    this.isSelected = false,
    this.highlightColor,
  });

  Map<String, dynamic> toJson() => {
        'number': number,
        'text': text,
        'highlightColor': highlightColor,
      };

  factory BibleVerse.fromJson(Map<String, dynamic> json) => BibleVerse(
        number: json['number'] as int,
        text: json['text'] as String,
        highlightColor: json['highlightColor'] as String?,
      );

  BibleVerse copyWith({
    int? number,
    String? text,
    bool? isSelected,
    String? highlightColor,
  }) {
    return BibleVerse(
      number: number ?? this.number,
      text: text ?? this.text,
      isSelected: isSelected ?? this.isSelected,
      highlightColor: highlightColor ?? this.highlightColor,
    );
  }
}

/// Represents a Bible chapter
class BibleChapter {
  final int number;
  final List<BibleVerse> verses;

  BibleChapter({
    required this.number,
    required this.verses,
  });

  Map<String, dynamic> toJson() => {
        'number': number,
        'verses': verses.map((v) => v.toJson()).toList(),
      };

  factory BibleChapter.fromJson(Map<String, dynamic> json) => BibleChapter(
        number: json['number'] as int,
        verses: (json['verses'] as List)
            .map((v) => BibleVerse.fromJson(v as Map<String, dynamic>))
            .toList(),
      );
}

/// Represents a Bible book
class BibleBook {
  final String name;
  final String abbreviation;
  final int totalChapters;
  final List<BibleChapter>? chapters; // Lazy loaded

  BibleBook({
    required this.name,
    required this.abbreviation,
    required this.totalChapters,
    this.chapters,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'abbreviation': abbreviation,
        'totalChapters': totalChapters,
        if (chapters != null)
          'chapters': chapters!.map((c) => c.toJson()).toList(),
      };

  factory BibleBook.fromJson(Map<String, dynamic> json) => BibleBook(
        name: json['name'] as String,
        abbreviation: json['abbreviation'] as String,
        totalChapters: json['totalChapters'] as int,
        chapters: json['chapters'] != null
            ? (json['chapters'] as List)
                .map((c) => BibleChapter.fromJson(c as Map<String, dynamic>))
                .toList()
            : null,
      );
}

/// Represents a verse highlight
class VerseHighlight {
  final String bookName;
  final int chapter;
  final int verse;
  final String color;
  final DateTime createdAt;

  VerseHighlight({
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.color,
    required this.createdAt,
  });

  String get reference => '$bookName $chapter:$verse';

  Map<String, dynamic> toJson() => {
        'bookName': bookName,
        'chapter': chapter,
        'verse': verse,
        'color': color,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VerseHighlight.fromJson(Map<String, dynamic> json) => VerseHighlight(
        bookName: json['bookName'] as String,
        chapter: json['chapter'] as int,
        verse: json['verse'] as int,
        color: json['color'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Represents a verse bookmark
class VerseBookmark {
  final String id;
  final String bookName;
  final int chapter;
  final int verse;
  final DateTime createdAt;

  VerseBookmark({
    required this.id,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.createdAt,
  });

  String get reference => '$bookName $chapter:$verse';

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookName': bookName,
        'chapter': chapter,
        'verse': verse,
        'createdAt': createdAt.toIso8601String(),
      };

  factory VerseBookmark.fromJson(Map<String, dynamic> json) => VerseBookmark(
        id: json['id'] as String,
        bookName: json['bookName'] as String,
        chapter: json['chapter'] as int,
        verse: json['verse'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

/// Represents a verse note
class VerseNote {
  final String id;
  final String bookName;
  final int chapter;
  final int verse;
  final String note;
  final DateTime createdAt;
  final DateTime updatedAt;

  VerseNote({
    required this.id,
    required this.bookName,
    required this.chapter,
    required this.verse,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  String get reference => '$bookName $chapter:$verse';

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookName': bookName,
        'chapter': chapter,
        'verse': verse,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory VerseNote.fromJson(Map<String, dynamic> json) => VerseNote(
        id: json['id'] as String,
        bookName: json['bookName'] as String,
        chapter: json['chapter'] as int,
        verse: json['verse'] as int,
        note: json['note'] as String,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  VerseNote copyWith({
    String? id,
    String? bookName,
    int? chapter,
    int? verse,
    String? note,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VerseNote(
      id: id ?? this.id,
      bookName: bookName ?? this.bookName,
      chapter: chapter ?? this.chapter,
      verse: verse ?? this.verse,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Reading preferences
class ReadingPreferences {
  final double fontSize;
  final String fontFamily;
  final String? customFontPath;
  final bool autoScrollEnabled;
  final double autoScrollSpeed;

  ReadingPreferences({
    this.fontSize = 16.0,
    this.fontFamily = 'Default',
    this.customFontPath,
    this.autoScrollEnabled = false,
    this.autoScrollSpeed = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'fontSize': fontSize,
        'fontFamily': fontFamily,
        'customFontPath': customFontPath,
        'autoScrollEnabled': autoScrollEnabled,
        'autoScrollSpeed': autoScrollSpeed,
      };

  factory ReadingPreferences.fromJson(Map<String, dynamic> json) =>
      ReadingPreferences(
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 16.0,
        fontFamily: json['fontFamily'] as String? ?? 'Default',
        customFontPath: json['customFontPath'] as String?,
        autoScrollEnabled: json['autoScrollEnabled'] as bool? ?? false,
        autoScrollSpeed: (json['autoScrollSpeed'] as num?)?.toDouble() ?? 1.0,
      );

  ReadingPreferences copyWith({
    double? fontSize,
    String? fontFamily,
    String? customFontPath,
    bool? autoScrollEnabled,
    bool clearCustomFont = false,
    double? autoScrollSpeed,
  }) {
    return ReadingPreferences(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      customFontPath:
          clearCustomFont ? null : (customFontPath ?? this.customFontPath),
      autoScrollEnabled: autoScrollEnabled ?? this.autoScrollEnabled,
      autoScrollSpeed: autoScrollSpeed ?? this.autoScrollSpeed,
    );
  }
}

/// Reading progress
class ReadingProgress {
  final String bookName;
  final int chapter;
  final double scrollOffset;
  final DateTime lastRead;

  ReadingProgress({
    required this.bookName,
    required this.chapter,
    this.scrollOffset = 0.0,
    required this.lastRead,
  });

  Map<String, dynamic> toJson() => {
        'bookName': bookName,
        'chapter': chapter,
        'scrollOffset': scrollOffset,
        'lastRead': lastRead.toIso8601String(),
      };

  factory ReadingProgress.fromJson(Map<String, dynamic> json) =>
      ReadingProgress(
        bookName: json['bookName'] as String,
        chapter: json['chapter'] as int,
        scrollOffset: (json['scrollOffset'] as num?)?.toDouble() ?? 0.0,
        lastRead: DateTime.parse(json['lastRead'] as String),
      );
}
