import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/shared/widgets/detail_pill.dart';

class EventDetailHeader extends StatelessWidget {
  const EventDetailHeader({super.key, required this.event});

  final EventModel event;

  String _badgeLabel() {
    switch (event.state) {
      case EventState.scheduled:
        return EventStrings.comingSoonPill;
      case EventState.inProgress:
        return EventStrings.eventLiveNow;
      case EventState.cancelled:
        return event.state.label.toUpperCase();
      case EventState.finished:
        return EventStrings.eventFinished.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildBackground(),
          _buildOverlayGradient(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _badgeLabel(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    event.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const EventDetailOrganizerRow(
                    organizerName: EventStrings.organizerPlaceholder,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      DetailPill(
                        leading: _DifficultyFlames(
                          level: event.difficulty.value,
                        ),
                        label: EventDifficulty.fromValue(
                          event.difficulty.value,
                        ).shortLabel,
                        variant: DetailPillVariant.overlay,
                      ),
                      const SizedBox(width: 12),
                      DetailPill(
                        leading: const Icon(
                          Icons.two_wheeler,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        label: event.eventType.label.toUpperCase(),
                        variant: DetailPillVariant.overlay,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DetailPill(
                    leading: const Icon(
                      Icons.access_time,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    subtitle: 'HORA',
                    label: '${DateFormat('HH:mm').format(event.meetingTime)}h',
                    variant: DetailPillVariant.overlay,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (event.imageUrl != null && event.imageUrl!.isNotEmpty) {
      return Image.network(
        event.imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
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

  Widget _buildOverlayGradient() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        height: 220,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0xE0000000)],
          ),
        ),
      ),
    );
  }
}

class EventDetailOrganizerRow extends StatelessWidget {
  const EventDetailOrganizerRow({
    super.key,
    required this.organizerName,
    this.onTapOrganizer,
  });

  final String organizerName;
  final VoidCallback? onTapOrganizer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: const Icon(Icons.check, color: Colors.white, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              children: [
                const TextSpan(text: '${EventStrings.organizedBy} '),
                TextSpan(
                  text: organizerName,
                  // style: const TextStyle(decoration: TextDecoration.underline),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DifficultyFlames extends StatelessWidget {
  const _DifficultyFlames({required this.level});

  final int level;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i < level;
        return Padding(
          padding: const EdgeInsets.only(right: 2),
          child: Icon(
            Icons.local_fire_department,
            size: 16,
            color: filled
                ? AppColors.primary
                : Colors.white.withValues(alpha: 0.35),
          ),
        );
      }),
    );
  }
}
