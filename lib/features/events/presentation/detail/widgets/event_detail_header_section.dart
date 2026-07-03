import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

/// Badge Row + event name + organizer row.
/// Matches Pencil "Event Header" block.
class EventDetailHeaderSection extends StatelessWidget {
  const EventDetailHeaderSection({super.key, required this.event});

  final EventModel event;

  String _badgeLabel(BuildContext context) {
    return switch (event.state) {
      EventState.draft => context.l10n.event_draftBadge,
      EventState.scheduled => context.l10n.event_comingSoonPill,
      EventState.inProgress => context.l10n.event_eventLiveNow,
      EventState.finished => context.l10n.event_eventFinished.toUpperCase(),
      EventState.cancelled => event.state.label.toUpperCase(),
    };
  }

  Color _badgeColor() {
    return switch (event.state) {
      EventState.draft => AppColors.primary,
      EventState.scheduled => AppColors.info,
      EventState.inProgress => AppColors.success,
      EventState.finished => AppColors.tabInactive,
      EventState.cancelled => AppColors.tabInactive,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge row: state badge + date pill
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _badgeColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _badgeLabel(context),
                  style: const TextStyle(
                    color: AppColors.textOnDarkPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatDate(event.startDate),
                  style: const TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Event name
          Text(
            event.name,
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Organizer row
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.darkTertiary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  color: AppColors.textOnDarkSecondary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${context.l10n.event_organizedBy} ${event.ownerName ?? context.l10n.event_organizerPlaceholder}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const monthNames = [
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
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }
}
