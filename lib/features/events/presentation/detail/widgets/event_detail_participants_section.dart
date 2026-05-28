import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// "Inscritos" section showing count badge + view-all link.
class EventDetailParticipantsSection extends StatelessWidget {
  const EventDetailParticipantsSection({super.key, required this.event});

  final EventModel event;

  void _openAttendees(BuildContext context) {
    context.pushNamed(AppRoutes.eventAttendees, extra: event);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.event_registrationsTab,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.19),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                context.l10n.event_participants,
                style: const TextStyle(
                  color: AppColors.info,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // View all link
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _openAttendees(context),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.event_viewAttendees,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  color: AppColors.primary, size: 14),
            ],
          ),
        ),
      ],
    );
  }
}
