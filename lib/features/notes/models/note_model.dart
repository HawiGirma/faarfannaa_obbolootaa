import 'package:uuid/uuid.dart';

enum NoteType {
  text,
  checklist,
  image,
  reminder,
  voice,
}

enum NotePriority {
  low,
  medium,
  high,
}

class NoteModel {
  final String id;
  final String title;
  final String content;
  final NoteType type;
  final String category;
  final List<String> tags;
  final int colorIndex;
  final bool isFavorite;
  final bool isPinned;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reminderDate;
  final NotePriority? priority;
  final List<ChecklistItem>? checklistItems;
  final String? imagePath;
  final String? voicePath;
  final int? voiceDuration; // in seconds

  NoteModel({
    String? id,
    required this.title,
    required this.content,
    required this.type,
    this.category = 'Personal',
    this.tags = const [],
    this.colorIndex = 0,
    this.isFavorite = false,
    this.isPinned = false,
    this.isArchived = false,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.reminderDate,
    this.priority,
    this.checklistItems,
    this.imagePath,
    this.voicePath,
    this.voiceDuration,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Calculate checklist progress
  double get checklistProgress {
    if (checklistItems == null || checklistItems!.isEmpty) return 0;
    final completed = checklistItems!.where((item) => item.isCompleted).length;
    return completed / checklistItems!.length;
  }

  // Get short preview text
  String get preview {
    if (content.length <= 100) return content;
    return '${content.substring(0, 100)}...';
  }

  // Copy with method
  NoteModel copyWith({
    String? title,
    String? content,
    NoteType? type,
    String? category,
    List<String>? tags,
    int? colorIndex,
    bool? isFavorite,
    bool? isPinned,
    bool? isArchived,
    DateTime? updatedAt,
    DateTime? reminderDate,
    NotePriority? priority,
    List<ChecklistItem>? checklistItems,
    String? imagePath,
    String? voicePath,
    int? voiceDuration,
  }) {
    return NoteModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      type: type ?? this.type,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      colorIndex: colorIndex ?? this.colorIndex,
      isFavorite: isFavorite ?? this.isFavorite,
      isPinned: isPinned ?? this.isPinned,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      reminderDate: reminderDate ?? this.reminderDate,
      priority: priority ?? this.priority,
      checklistItems: checklistItems ?? this.checklistItems,
      imagePath: imagePath ?? this.imagePath,
      voicePath: voicePath ?? this.voicePath,
      voiceDuration: voiceDuration ?? this.voiceDuration,
    );
  }

  // To JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'type': type.toString(),
      'category': category,
      'tags': tags,
      'colorIndex': colorIndex,
      'isFavorite': isFavorite,
      'isPinned': isPinned,
      'isArchived': isArchived,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reminderDate': reminderDate?.toIso8601String(),
      'priority': priority?.toString(),
      'checklistItems': checklistItems?.map((item) => item.toJson()).toList(),
      'imagePath': imagePath,
      'voicePath': voicePath,
      'voiceDuration': voiceDuration,
    };
  }

  // From JSON
  factory NoteModel.fromJson(Map<String, dynamic> json) {
    return NoteModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      type: NoteType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => NoteType.text,
      ),
      category: json['category'] ?? 'Personal',
      tags: List<String>.from(json['tags'] ?? []),
      colorIndex: json['colorIndex'] ?? 0,
      isFavorite: json['isFavorite'] ?? false,
      isPinned: json['isPinned'] ?? false,
      isArchived: json['isArchived'] ?? false,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      reminderDate: json['reminderDate'] != null
          ? DateTime.parse(json['reminderDate'])
          : null,
      priority: json['priority'] != null
          ? NotePriority.values.firstWhere(
              (e) => e.toString() == json['priority'],
              orElse: () => NotePriority.medium,
            )
          : null,
      checklistItems: json['checklistItems'] != null
          ? (json['checklistItems'] as List)
              .map((item) => ChecklistItem.fromJson(item))
              .toList()
          : null,
      imagePath: json['imagePath'],
      voicePath: json['voicePath'],
      voiceDuration: json['voiceDuration'],
    );
  }
}

class ChecklistItem {
  final String id;
  final String text;
  final bool isCompleted;

  ChecklistItem({
    String? id,
    required this.text,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  ChecklistItem copyWith({
    String? text,
    bool? isCompleted,
  }) {
    return ChecklistItem(
      id: id,
      text: text ?? this.text,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isCompleted': isCompleted,
    };
  }

  factory ChecklistItem.fromJson(Map<String, dynamic> json) {
    return ChecklistItem(
      id: json['id'],
      text: json['text'],
      isCompleted: json['isCompleted'] ?? false,
    );
  }
}
