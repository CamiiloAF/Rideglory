import 'package:flutter/material.dart';

class FilterStatusChip extends StatelessWidget {
  final String label;
  final Color textColor;
  final Color fillColor;
  final Color borderColor;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterStatusChip({
    super.key,
    required this.label,
    required this.textColor,
    required this.fillColor,
    required this.borderColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: fillColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.fromBorderSide(
            BorderSide(
              color: isSelected ? textColor : borderColor,
              width: isSelected ? 1.5 : 1,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}
