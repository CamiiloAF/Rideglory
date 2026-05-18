import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class NextServiceRow extends StatelessWidget {
  const NextServiceRow({super.key, required this.label, required this.pill});

  final String label;
  final Widget pill;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.darkTextSecondary,
          ),
        ),
        pill,
      ],
    );
  }
}
