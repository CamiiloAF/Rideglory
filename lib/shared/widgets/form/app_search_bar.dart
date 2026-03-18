import 'package:flutter/material.dart';
import 'package:rideglory/design_system/foundation/extensions/theme_extensions.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

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
    final cs = context.colorScheme;
    final appColors = context.appColors;

    final fillColor =
        darkMode ? cs.surfaceContainerHighest : cs.surface;
    final borderColor =
        darkMode ? cs.primary : cs.outlineVariant;
    final hintColor = cs.onSurfaceVariant;
    final textColor = cs.onSurface;
    final iconColor =
        darkMode ? appColors.inputIcon : cs.onSurfaceVariant;

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
              color: cs.primary,
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
