import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class FilterSectionLabel extends StatelessWidget {
  final String text;

  const FilterSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: AppColors.textOnDarkSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}
