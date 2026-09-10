import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../event_labels.dart';

/// Filas de fecha y punto de encuentro del detalle.
class EventDetailDataRows extends StatelessWidget {
  const EventDetailDataRows({
    required this.startAt,
    required this.meetingPointLabel,
    super.key,
  });

  final DateTime startAt;
  final String meetingPointLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final textStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: colors.text,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.calendar, size: 16, color: colors.textSecondary),
            const SizedBox(width: 8),
            Expanded(child: Text(eventDateLabel(startAt), style: textStyle)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.flag, size: 16, color: colors.textSecondary),
            const SizedBox(width: 8),
            Expanded(child: Text(meetingPointLabel, style: textStyle)),
          ],
        ),
      ],
    );
  }
}
