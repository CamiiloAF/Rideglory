import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/home/constants/home_strings.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';

class HomeEmptyEventsCard extends StatelessWidget {
  const HomeEmptyEventsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorScheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(
            Icons.calendar_today_outlined,
            size: 48,
            color: context.colorScheme.outlineVariant,
          ),
          SizedBox(height: 8),
          Text(
            HomeStrings.emptyEvents,
            style: TextStyle(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            HomeStrings.emptyEventsDescription,
            style: TextStyle(color: context.colorScheme.onSurfaceVariant, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
