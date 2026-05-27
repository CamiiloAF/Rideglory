import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Fallback placeholder shown when event has no image.
class EventDetailImagePlaceholder extends StatelessWidget {
  const EventDetailImagePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkCard,
      child: const Center(
        child: Icon(
          Icons.two_wheeler_rounded,
          color: AppColors.primary,
          size: 64,
        ),
      ),
    );
  }
}
