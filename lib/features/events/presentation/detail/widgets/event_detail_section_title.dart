import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class EventDetailSectionTitle extends StatelessWidget {
  const EventDetailSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.2,
      ),
    );
  }
}
