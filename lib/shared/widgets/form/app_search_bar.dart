import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class AppSearchBar extends StatelessWidget {
  final String hintText;
  final Function(String) onSearchChanged;
  final EdgeInsetsGeometry? padding;
  final bool darkMode;

  const AppSearchBar({
    super.key,
    required this.hintText,
    required this.onSearchChanged,
    this.padding,
    this.darkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final fillColor = darkMode ? AppColors.darkSurfaceHighest : Colors.white;
    final borderColor = darkMode
        ? theme.colorScheme.primary
        : Colors.grey[300]!;
    final hintColor = darkMode
        ? AppColors.darkTextSecondary
        : Colors.grey[600]!;
    final textColor = darkMode ? AppColors.darkTextPrimary : Colors.black;
    final iconColor = darkMode ? AppColors.darkInputIcon : Colors.grey[600]!;

    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: hintColor),
          prefixIcon: Icon(Icons.search, color: iconColor),
          filled: true,
          fillColor: fillColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: borderColor, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: darkMode ? theme.colorScheme.primary : theme.primaryColor,
              width: 2,
            ),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        onChanged: onSearchChanged,
      ),
    );
  }
}
