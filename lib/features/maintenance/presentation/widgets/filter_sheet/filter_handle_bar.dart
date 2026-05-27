import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class FilterHandleBar extends StatelessWidget {
  const FilterHandleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      width: 36,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.darkBorderLight,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
