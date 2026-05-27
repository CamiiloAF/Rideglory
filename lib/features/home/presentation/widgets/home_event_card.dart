import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class HomeEventCard extends StatelessWidget {
  const HomeEventCard({
    super.key,
    required this.event,
    required this.onTap,
  });

  final EventModel event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 240,
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CardImage(event: event),
            Expanded(child: _CardContent(event: event)),
          ],
        ),
      ),
    );
  }
}

class _CardImage extends StatelessWidget {
  const _CardImage({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          event.imageUrl != null
              ? CachedNetworkImage(
                  imageUrl: event.imageUrl!,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => const _ImagePlaceholder(),
                  errorWidget: (_, _, _) => const _ImagePlaceholder(),
                )
              : const _ImagePlaceholder(),
          Positioned(
            top: 12,
            left: 12,
            child: AppEventBadge(
              label: event.state.label,
              variant: switch (event.state) {
                EventState.draft => EventBadgeVariant.comingSoon,
                EventState.scheduled => EventBadgeVariant.scheduled,
                EventState.inProgress => EventBadgeVariant.inProgress,
                EventState.finished => EventBadgeVariant.finished,
                EventState.cancelled => EventBadgeVariant.cancelled,
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBgSecondary,
      child: const Center(
        child: Icon(Icons.route, size: 40, color: AppColors.darkBorderLight),
      ),
    );
  }
}

class _CardContent extends StatelessWidget {
  const _CardContent({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            event.name,
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today, size: 14, color: AppColors.textOnDarkSecondary),
              const SizedBox(width: 6),
              Text(
                event.startDate.formattedDate,
                style: const TextStyle(
                  color: AppColors.textOnDarkSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.terrain, size: 14, color: AppColors.textOnDarkTertiary),
              const SizedBox(width: 6),
              Text(
                event.difficulty.shortLabel,
                style: const TextStyle(
                  color: AppColors.textOnDarkTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _ViewDetailsButton(label: context.l10n.home_eventViewDetails),
        ],
      ),
    );
  }
}

class _ViewDetailsButton extends StatelessWidget {
  const _ViewDetailsButton({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.textOnDarkPrimary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.darkBgPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward, size: 14, color: AppColors.darkBgPrimary),
        ],
      ),
    );
  }
}
