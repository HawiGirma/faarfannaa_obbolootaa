import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppUtils {
  /// Format duration to mm:ss
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// Format timestamp to readable date
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format timestamp to relative time
  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}y ago';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  /// Show snackbar
  static void showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontFamily: 'Poppins')),
        backgroundColor: isError ? Colors.red.shade700 : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Get language flag emoji
  static String getLanguageFlag(String language) {
    switch (language.toLowerCase()) {
      case 'afaan oromo':
        return '🇪🇹';
      case 'english':
        return '🇬🇧';
      case 'amharic':
        return '🇪🇹';
      default:
        return '🎵';
    }
  }

  /// Get language color
  static Color getLanguageColor(String language) {
    switch (language.toLowerCase()) {
      case 'afaan oromo':
        return const Color(0xFF7C4DFF);
      case 'english':
        return const Color(0xFF2196F3);
      case 'amharic':
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF9E9E9E);
    }
  }
}
