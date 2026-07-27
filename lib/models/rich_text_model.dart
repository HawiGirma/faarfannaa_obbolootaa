import 'package:flutter/material.dart';

/// Represents a span of text with formatting
class RichTextSpan {
  final String text;
  final TextStyle style;
  final int start;
  final int end;

  RichTextSpan({
    required this.text,
    required this.style,
    required this.start,
    required this.end,
  });

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'start': start,
      'end': end,
      'bold': style.fontWeight == FontWeight.bold,
      'italic': style.fontStyle == FontStyle.italic,
      'underline': style.decoration == TextDecoration.underline,
      'strikethrough': style.decoration == TextDecoration.lineThrough,
      'color': style.color?.value.toRadixString(16),
      'backgroundColor': style.backgroundColor?.value.toRadixString(16),
      'fontFamily': style.fontFamily,
      'fontSize': style.fontSize,
    };
  }

  factory RichTextSpan.fromJson(Map<String, dynamic> json) {
    return RichTextSpan(
      text: json['text'] as String,
      start: json['start'] as int,
      end: json['end'] as int,
      style: TextStyle(
        fontWeight: json['bold'] == true ? FontWeight.bold : FontWeight.normal,
        fontStyle: json['italic'] == true ? FontStyle.italic : FontStyle.normal,
        decoration: json['strikethrough'] == true
            ? TextDecoration.lineThrough
            : (json['underline'] == true
                ? TextDecoration.underline
                : TextDecoration.none),
        color: json['color'] != null
            ? Color(int.parse(json['color'], radix: 16))
            : null,
        backgroundColor: json['backgroundColor'] != null
            ? Color(int.parse(json['backgroundColor'], radix: 16))
            : null,
        fontFamily: json['fontFamily'] as String?,
        fontSize: json['fontSize'] as double?,
      ),
    );
  }
}

/// Represents rich content for title and body
class RichContent {
  final String plainText;
  final List<RichTextSpan> spans;
  final List<ContentBlock> blocks;

  RichContent({
    required this.plainText,
    this.spans = const [],
    this.blocks = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'plainText': plainText,
      'spans': spans.map((s) => s.toJson()).toList(),
      'blocks': blocks.map((b) => b.toJson()).toList(),
    };
  }

  factory RichContent.fromJson(Map<String, dynamic> json) {
    return RichContent(
      plainText: json['plainText'] as String? ?? '',
      spans: (json['spans'] as List?)
              ?.map((s) => RichTextSpan.fromJson(s))
              .toList() ??
          [],
      blocks: (json['blocks'] as List?)
              ?.map((b) => ContentBlock.fromJson(b))
              .toList() ??
          [],
    );
  }

  factory RichContent.plain(String text) {
    return RichContent(plainText: text);
  }
}

/// Represents different types of content blocks
enum BlockType {
  paragraph,
  bulletList,
  numberedList,
  heading1,
  heading2,
  heading3,
  quote,
  code,
  image,
  drawing,
}

class ContentBlock {
  final String id;
  final BlockType type;
  final String content;
  final int level; // For nested lists
  final Map<String, dynamic>? metadata; // For images, drawings, etc.

  ContentBlock({
    required this.id,
    required this.type,
    required this.content,
    this.level = 0,
    this.metadata,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'content': content,
      'level': level,
      'metadata': metadata,
    };
  }

  factory ContentBlock.fromJson(Map<String, dynamic> json) {
    return ContentBlock(
      id: json['id'] as String,
      type: BlockType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => BlockType.paragraph,
      ),
      content: json['content'] as String,
      level: json['level'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
    );
  }
}

/// Represents formatting state
class FormattingState {
  bool isBold;
  bool isItalic;
  bool isUnderline;
  bool isStrikethrough;
  Color? textColor;
  Color? backgroundColor;
  String? fontFamily;
  double? fontSize;

  FormattingState({
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.textColor,
    this.backgroundColor,
    this.fontFamily,
    this.fontSize,
  });

  TextStyle toTextStyle() {
    return TextStyle(
      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
      fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
      decoration: isStrikethrough
          ? TextDecoration.lineThrough
          : (isUnderline ? TextDecoration.underline : TextDecoration.none),
      color: textColor,
      backgroundColor: backgroundColor,
      fontFamily: fontFamily,
      fontSize: fontSize,
    );
  }

  FormattingState copyWith({
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isStrikethrough,
    Color? textColor,
    Color? backgroundColor,
    String? fontFamily,
    double? fontSize,
  }) {
    return FormattingState(
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isStrikethrough: isStrikethrough ?? this.isStrikethrough,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
    );
  }
}
