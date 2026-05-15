import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// Simple back-navigation app bar used when the event is not yet in progress
/// or the event id is missing.
class LiveMapSimpleAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const LiveMapSimpleAppBar({super.key, required this.title});

  final String title;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.darkCard,
      foregroundColor: AppColors.textOnDarkPrimary,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        onPressed: () => context.pop(),
      ),
      centerTitle: true,
      title: Text(
        title,
        style: const TextStyle(
          color: AppColors.textOnDarkPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevation: 0,
    );
  }
}

/// Transparent overlay app bar shown when the live map is active.
class LiveMapOverlayAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const LiveMapOverlayAppBar({super.key, required this.event});

  final EventModel event;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: _MapOverlayButton(
        onTap: () => context.pop(),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textOnDarkPrimary,
          size: 18,
        ),
      ),
      centerTitle: true,
      title: _LiveBadgeTitle(eventName: event.name),
      actions: [
        _MapOverlayButton(
          onTap: () => context.pushNamed(AppRoutes.participants, extra: event),
          child: const Icon(
            Icons.group_rounded,
            color: AppColors.textOnDarkPrimary,
            size: 22,
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}

class _MapOverlayButton extends StatelessWidget {
  const _MapOverlayButton({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.darkCard.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorderPrimary),
        ),
        child: Center(child: child),
      ),
    );
  }
}

class _LiveBadgeTitle extends StatelessWidget {
  const _LiveBadgeTitle({required this.eventName});

  final String eventName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkCard.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.error,
            ),
          ),
          AppSpacing.hGapXxs,
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              eventName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
