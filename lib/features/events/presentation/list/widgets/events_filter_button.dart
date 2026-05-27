import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class EventsFilterButton extends StatelessWidget {
  const EventsFilterButton({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(
          Icons.tune_rounded,
          color: AppColors.darkBgPrimary,
          size: 18,
        ),
      ),
    );
  }
}
