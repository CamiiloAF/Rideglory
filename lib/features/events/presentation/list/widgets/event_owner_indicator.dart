import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class EventOwnerIndicator extends StatelessWidget {
  const EventOwnerIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primarySubtle,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary, width: 1),
      ),
      child: const Icon(Icons.star_rounded, color: AppColors.primary, size: 12),
    );
  }
}
