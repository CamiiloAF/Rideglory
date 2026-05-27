import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/live_badge_title.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/map_overlay_button.dart';
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
      leading: MapOverlayButton(
        onTap: () => context.pop(),
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textOnDarkPrimary,
          size: 18,
        ),
      ),
      centerTitle: true,
      title: LiveBadgeTitle(eventName: event.name),
      actions: [
        MapOverlayButton(
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
