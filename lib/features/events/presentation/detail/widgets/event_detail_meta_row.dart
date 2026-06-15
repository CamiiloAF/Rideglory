import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

/// Fila horizontal de metadatos: fecha · tipo · hora de encuentro.
/// Usa Wrap para evitar overflow en pantallas pequeñas.
class EventDetailMetaRow extends StatelessWidget {
  const EventDetailMetaRow({super.key, required this.event});

  final EventModel event;

  static const _monthNames = [
    'Ene',
    'Feb',
    'Mar',
    'Abr',
    'May',
    'Jun',
    'Jul',
    'Ago',
    'Sep',
    'Oct',
    'Nov',
    'Dic',
  ];

  String _formatDate(DateTime date) =>
      '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(LucideIcons.calendar, color: AppColors.primary, size: 14),
        const SizedBox(width: 8),
        Text(
          _formatDate(event.startDate),
          style: const TextStyle(
            color: AppColors.textOnDarkSecondary,
            fontSize: 13,
            fontFamily: 'Space Grotesk',
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '·',
          style: TextStyle(color: AppColors.textOnDarkTertiary, fontSize: 13),
        ),
        const SizedBox(width: 8),
        const Icon(LucideIcons.navigation, color: AppColors.primary, size: 14),
        const SizedBox(width: 8),
        Text(
          event.eventType.label,
          style: const TextStyle(
            color: AppColors.textOnDarkSecondary,
            fontSize: 13,
            fontFamily: 'Space Grotesk',
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '·',
          style: TextStyle(color: AppColors.textOnDarkTertiary, fontSize: 13),
        ),
        const SizedBox(width: 8),
        const Icon(LucideIcons.timer, color: AppColors.primary, size: 14),
        const SizedBox(width: 8),
        Text(
          event.meetingTime.formattedTime,
          style: const TextStyle(
            color: AppColors.textOnDarkSecondary,
            fontSize: 13,
            fontFamily: 'Space Grotesk',
          ),
        ),
      ],
    );
  }
}
