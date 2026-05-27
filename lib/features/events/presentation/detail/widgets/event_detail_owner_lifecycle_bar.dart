import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

/// Owner CTA bar for the Event Detail screen.
///
/// Handles two states from Pencil page 6:
/// - OWNER — START EVENT: participant count (left) + green "Iniciar evento" btn (right)
/// - OWNER — EVENT LIVE: live badge + "Rodada en curso" + full-width red "Finalizar rodada" btn
class EventDetailOwnerLifecycleBar extends StatelessWidget {
  const EventDetailOwnerLifecycleBar({
    super.key,
    required this.event,
    required this.isLoading,
    required this.onStart,
    required this.onStop,
    required this.onOpenMap,
    this.onPublish,
  });

  final EventModel event;
  final bool isLoading;
  final VoidCallback onStart;
  final VoidCallback onStop;
  final VoidCallback onOpenMap;
  final VoidCallback? onPublish;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        border: Border(top: BorderSide(color: AppColors.darkBorderPrimary)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, max(16.0, bottomPadding)),
      child: switch (event.state) {
        EventState.draft => _OwnerDraftBar(
            isLoading: isLoading,
            onPublish: onPublish ?? () {},
          ),
        EventState.scheduled => _OwnerStartBar(
            isLoading: isLoading,
            onStart: onStart,
          ),
        EventState.inProgress => _OwnerLiveBar(
            isLoading: isLoading,
            onStop: onStop,
            onOpenMap: onOpenMap,
          ),
        EventState.finished => const SizedBox.shrink(),
        EventState.cancelled => const SizedBox.shrink(),
      },
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────

/// OWNER — START EVENT state: participant count left + green start button right.
class _OwnerStartBar extends StatelessWidget {
  const _OwnerStartBar({required this.isLoading, required this.onStart});

  final bool isLoading;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Info column
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.event_participantsReady,
              style: const TextStyle(
                color: AppColors.textOnDarkTertiary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              context.l10n.event_participants,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        // Start button
        GestureDetector(
          onTap: isLoading ? null : onStart,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.successSubtle,
              borderRadius: BorderRadius.circular(25),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation(AppColors.success),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.play_arrow_rounded,
                          color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.event_startEvent,
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}

/// OWNER — DRAFT state: full-width primary "Publicar" CTA.
class _OwnerDraftBar extends StatelessWidget {
  const _OwnerDraftBar({required this.isLoading, required this.onPublish});

  final bool isLoading;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onPublish,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
        decoration: BoxDecoration(
          color: isLoading
              ? AppColors.primary.withValues(alpha: 0.6)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(28),
        ),
        child: isLoading
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation(AppColors.darkBgPrimary),
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.publish_rounded,
                    color: AppColors.darkBgPrimary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.l10n.draft_publish,
                    style: const TextStyle(
                      color: AppColors.darkBgPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// OWNER — EVENT LIVE state: live badge + "Rodada en curso" + map button + end button.
class _OwnerLiveBar extends StatelessWidget {
  const _OwnerLiveBar({
    required this.isLoading,
    required this.onStop,
    required this.onOpenMap,
  });

  final bool isLoading;
  final VoidCallback onStop;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Live header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.errorSubtle,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.event_eventLiveNow,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              context.l10n.event_rideInProgress,
              style: const TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Map button
        GestureDetector(
          onTap: onOpenMap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 22),
            decoration: BoxDecoration(
              color: Colors.transparent, // Intentional: outlined button with no fill
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.primary, width: 1.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map_outlined, color: AppColors.primary, size: 16),
                const SizedBox(width: 8),
                Text(
                  context.l10n.event_viewMap,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),

        // End button
        GestureDetector(
          onTap: isLoading ? null : onStop,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 22),
            decoration: BoxDecoration(
              color: AppColors.errorSubtle,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: AppColors.error, width: 1.5),
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation(AppColors.error),
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.stop_rounded,
                          color: AppColors.error, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.event_stopEvent,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }
}
