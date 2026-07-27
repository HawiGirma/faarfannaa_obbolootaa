import 'dart:convert';

/// Model for rich text content
class RichTextContent {
  final String deltaJson; // Quill Delta JSON
  final String plainText; // Plain text representation

  RichTextContent({
    required this.deltaJson,
    required this.plainText,
  });

  factory RichTextContent.fromJson(Map<String, dynamic> json) {
    return RichTextContent(
      deltaJson: json['delta_json'] as String? ?? '',
      plainText: json['plain_text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'delta_json': deltaJson,
      'plain_text': plainText,
    };
  }

  /// Create from Quill Delta
  factory RichTextContent.fromDelta(dynamic delta, String plainText) {
    return RichTextContent(
      deltaJson: jsonEncode(delta),
      plainText: plainText,
    );
  }

  /// Get Quill Delta
  dynamic get delta => deltaJson.isNotEmpty ? jsonDecode(deltaJson) : null;

  bool get isEmpty => deltaJson.isEmpty && plainText.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

/// Text formatting state
class FormattingState {
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrikethrough;
  final bool isCode;
  final String? fontFamily;
  final double? fontSize;
  final String? textColor;
  final String? backgroundColor;
  final String? alignment;

  FormattingState({
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.isCode = false,
    this.fontFamily,
    this.fontSize,
    this.textColor,
    this.backgroundColor,
    this.alignment,
  });

  FormattingState copyWith({
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isStrikethrough,
    bool? isCode,
    String? fontFamily,
    double? fontSize,
    String? textColor,
    String? backgroundColor,
    String? alignment,
  }) {
    return FormattingState(
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isStrikethrough: isStrikethrough ?? this.isStrikethrough,
      isCode: isCode ?? this.isCode,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      textColor: textColor ?? this.textColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      alignment: alignment ?? this.alignment,
    );
  }
}

/// Available font families
class FontFamilies {
  static const List<String> available = [
    'Inter',
    'Roboto',
    'Open Sans',
    'Lato',
    'Montserrat',
    'Poppins',
    'Raleway',
    'Ubuntu',
    'Merriweather',
    'Georgia',
    'Times New Roman',
    'Courier New',
    'Monaco',
  ];
}

/// Available font sizes
class FontSizes {
  static const List<double> available = [
    8,
    10,
    12,
    14,
    16,
    18,
    20,
    24,
    28,
    32,
    36,
    48,
    64,
  ];

  static const double defaultSize = 16;
}

/// Text alignment options
enum TextAlignmentOption {
  left,
  center,
  right,
  justify,
}

/// List type options
enum ListType {
  bullet,
  numbered,
  checklist,
}

/// Block type options
enum BlockType {
  paragraph,
  heading1,
  heading2,
  heading3,
  quote,
  code,
}
