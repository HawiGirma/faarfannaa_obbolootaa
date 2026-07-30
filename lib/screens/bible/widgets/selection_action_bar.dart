import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class SelectionActionBar extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onHighlight;
  final VoidCallback onRemoveHighlight;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;

  const SelectionActionBar({
    super.key,
    required this.selectedCount,
    required this.onCopy,
    required this.onShare,
    required this.onHighlight,
    required this.onRemoveHighlight,
    required this.onSelectAll,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$selectedCount selected',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontFamily: 'Poppins',
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionButton(
                icon: Icons.copy,
                onTap: onCopy,
                tooltip: 'Copy',
              ),
              _ActionButton(
                icon: Icons.share,
                onTap: onShare,
                tooltip: 'Share',
              ),
              _ActionButton(
                icon: Icons.highlight,
                onTap: onHighlight,
                tooltip: 'Highlight',
              ),
              _ActionButton(
                icon: Icons.highlight_remove,
                onTap: onRemoveHighlight,
                tooltip: 'Remove Highlight',
              ),
              _ActionButton(
                icon: Icons.select_all,
                onTap: onSelectAll,
                tooltip: 'Select All',
              ),
              _ActionButton(
                icon: Icons.close,
                onTap: onClear,
                tooltip: 'Clear',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
