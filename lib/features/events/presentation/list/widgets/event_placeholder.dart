import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class EventPlaceholder extends StatelessWidget {
  const EventPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBgSecondary,
      child: const Center(
        child: Icon(
          Icons.two_wheeler_rounded,
          color: AppColors.darkBorderPrimary,
          size: 48,
        ),
      ),
    );
  }
}
