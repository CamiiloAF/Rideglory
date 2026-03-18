import 'package:flutter/material.dart';
import 'package:rideglory/design_system/design_system.dart';

class EventCardDateAndCity extends StatelessWidget {
  final String formattedDate;
  final String city;

  const EventCardDateAndCity({
    super.key,
    required this.formattedDate,
    required this.city,
  });

  static const double _iconSize = 14.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = colorScheme.onSurface.withValues(alpha: 0.6);
    final textColor = colorScheme.onSurface.withValues(alpha: 0.7);

    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: _iconSize, color: iconColor),
        AppSpacing.hGapXxs,
        Text(
          formattedDate,
          style: theme.textTheme.bodySmall?.copyWith(color: textColor),
        ),
        AppSpacing.hGapMd,
        Icon(Icons.location_on_outlined, size: _iconSize, color: iconColor),
        AppSpacing.hGapXxs,
        Text(
          city,
          style: theme.textTheme.bodySmall?.copyWith(color: textColor),
        ),
      ],
    );
  }
}
