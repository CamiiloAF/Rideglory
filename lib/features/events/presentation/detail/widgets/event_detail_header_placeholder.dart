import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';

class EventDetailHeaderPlaceholder extends StatelessWidget {
  const EventDetailHeaderPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.4),
            AppColors.darkSurface,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.motorcycle,
          size: 80,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }
}
