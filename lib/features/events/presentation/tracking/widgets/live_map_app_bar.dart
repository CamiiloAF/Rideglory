import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/tracking/cubit/live_tracking_cubit.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/live_badge_title.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/map_overlay_button.dart';
import 'package:rideglory/shared/router/app_routes.dart';

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
        BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
          buildWhen: (prev, next) => prev.isFinished != next.isFinished,
          builder: (context, state) {
            if (state.isFinished) return const SizedBox.shrink();
            return MapOverlayButton(
              onTap: () =>
                  context.pushNamed(AppRoutes.participants, extra: event),
              child: const Icon(
                Icons.group_rounded,
                color: AppColors.textOnDarkPrimary,
                size: 22,
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
