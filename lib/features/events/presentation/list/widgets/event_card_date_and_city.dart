import 'package:flutter/material.dart';

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
    final iconColor = colorScheme.onSurface.withOpacity(0.6);
    final textColor = colorScheme.onSurface.withOpacity(0.7);

    return Row(
      children: [
        Icon(Icons.calendar_today_outlined, size: _iconSize, color: iconColor),
        const SizedBox(width: 4),
        Text(
          formattedDate,
          style: theme.textTheme.bodySmall?.copyWith(color: textColor),
        ),
        const SizedBox(width: 12),
        Icon(Icons.location_on_outlined, size: _iconSize, color: iconColor),
        const SizedBox(width: 4),
        Text(
          city,
          style: theme.textTheme.bodySmall?.copyWith(color: textColor),
        ),
      ],
    );
  }
}
