import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class FilterDivider extends StatelessWidget {
  const FilterDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, color: AppColors.darkBorderPrimary);
  }
}
