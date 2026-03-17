import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class RegistrationDetailLicensePlateTag extends StatelessWidget {
  const RegistrationDetailLicensePlateTag({
    super.key,
    required this.plate,
  });

  final String plate;

  @override
  Widget build(BuildContext context) {
    final textTheme = context.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.licensePlateTagBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        plate,
        style: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: AppColors.licensePlateTagText,
        ),
      ),
    );
  }
}
