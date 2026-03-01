import 'package:flutter/material.dart';

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
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        style: TextStyle(color: darkMode ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: darkMode ? Colors.grey[500] : Colors.grey[600],
          ),
          prefixIcon: Icon(
            Icons.search,
            color: darkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          filled: true,
          fillColor: darkMode ? const Color(0xFF1A1A1A) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: darkMode ? const Color(0xFF2A2A2A) : Colors.grey[300]!,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: darkMode ? const Color(0xFF2A2A2A) : Colors.grey[300]!,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: darkMode
                  ? Colors.grey[600]!
                  : Theme.of(context).primaryColor,
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
