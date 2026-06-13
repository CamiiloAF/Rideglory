import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_inscribed_badge.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_owner_indicator.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_placeholder.dart';
import 'package:rideglory/features/events/presentation/list/widgets/event_status_badge.dart';

/// Event card matching the Pencil design:
/// - Full-width card, radius 12, bg #1E1E24
/// - Top: image area h=220 with a status badge overlay (top-left)
/// - Bottom: content area padding=14, gap=8
///   - titleRow: name (18/700 white) + price (13/700 orange)
///   - optional "Inscrito" badge row
///   - locRow: map-pin icon + city text (13 secondary)
///   - dateRow: calendar icon + date text (13 secondary)
class EventCard extends StatelessWidget {
  const EventCard({
    super.key,
    required this.event,
    required this.onTap,
    this.isOwner = false,
    this.isRegistered = false,
    this.onStartEvent,
  });

  final EventModel event;
  final VoidCallback onTap;
  final bool isOwner;
  final bool isRegistered;
  final VoidCallback? onStartEvent;

  String _formattedDate(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final formatter = DateFormat('dd \'de\' MMMM, yyyy • hh:mm a', locale);
    return formatter.format(event.meetingTime);
  }

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
    final imageUrl = event.imageUrl?.trim();
    final hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image area ──────────────────────────────────────────────
            SizedBox(
              height: 220,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  hasImage
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const EventPlaceholder(),
                        )
                      : const EventPlaceholder(),
                  // Status badge + owner indicator — top-left overlay.
                  // Laid out in a Row so the owner pill never overlaps the
                  // status badge regardless of the badge label width.
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Row(
                      children: [
                        EventStatusBadge(
                          label: _badgeLabel(context),
                          color: _badgeColor(),
                        ),
                        if (isOwner) ...[
                          const SizedBox(width: 8),
                          const EventOwnerIndicator(),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Content area ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row: name + price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (isOwner) ...[
                        const Icon(
                          Icons.star_rounded,
                          color: AppColors.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          event.name,
                          style: const TextStyle(
                            color: AppColors.textOnDarkPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.isFree
                            ? context.l10n.event_free
                            : '\$${_formatPrice(event.price ?? 0)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Registered badge (if applicable)
                  if (isRegistered) ...[
                    const EventInscribedBadge(),
                    const SizedBox(height: 8),
                  ],

                  // Location row
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.textOnDarkSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.meetingPoint,
                          style: const TextStyle(
                            color: AppColors.textOnDarkSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Date row
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        color: AppColors.textOnDarkSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _formattedDate(context),
                          style: const TextStyle(
                            color: AppColors.textOnDarkSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatPrice(int price) {
    final formatter = NumberFormat('#,###', 'es_CO');
    return formatter.format(price);
  }
}
