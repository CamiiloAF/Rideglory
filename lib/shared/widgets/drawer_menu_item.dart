import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? textColor;
  final Color? iconColor;

  const DrawerMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
    this.textColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = const Color(0xFF6366F1);
    final defaultTextColor = textColor ?? Colors.grey[800];
    final defaultIconColor = iconColor ?? Colors.grey[600];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected
            ? selectedColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? selectedColor : defaultIconColor,
          size: 24,
        ),
        title: Text(
          title,
          style: context.bodyMedium?.copyWith(
            color: isSelected ? selectedColor : defaultTextColor,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
