import 'package:flutter/material.dart';

class NoteCategory {
  final String id;
  final String name;
  final IconData icon;
  final int count;

  const NoteCategory({
    required this.id,
    required this.name,
    required this.icon,
    this.count = 0,
  });

  NoteCategory copyWith({
    String? id,
    String? name,
    IconData? icon,
    int? count,
  }) {
    return NoteCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      count: count ?? this.count,
    );
  }

  static List<NoteCategory> get defaultCategories => [
        const NoteCategory(
          id: 'all',
          name: 'All Notes',
          icon: Icons.grid_view_rounded,
        ),
        const NoteCategory(
          id: 'favorites',
          name: 'Favorites',
          icon: Icons.star_rounded,
        ),
        const NoteCategory(
          id: 'personal',
          name: 'Personal',
          icon: Icons.person_rounded,
        ),
        const NoteCategory(
          id: 'work',
          name: 'Work',
          icon: Icons.work_rounded,
        ),
        const NoteCategory(
          id: 'ideas',
          name: 'Ideas',
          icon: Icons.lightbulb_rounded,
        ),
        const NoteCategory(
          id: 'shopping',
          name: 'Shopping',
          icon: Icons.shopping_cart_rounded,
        ),
        const NoteCategory(
          id: 'travel',
          name: 'Travel',
          icon: Icons.flight_rounded,
        ),
        const NoteCategory(
          id: 'archived',
          name: 'Archived',
          icon: Icons.archive_rounded,
        ),
      ];
}
