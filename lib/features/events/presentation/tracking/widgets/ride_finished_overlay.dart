import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/go_router.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/shared/router/app_routes.dart';

/// Semi-opaque overlay shown when the organizer ends the ride.
/// Displays a summary and a "Volver al inicio" CTA.
class RideFinishedOverlay extends StatelessWidget {
  const RideFinishedOverlay({super.key, required this.eventName});

  final String eventName;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.darkBgPrimary.withValues(alpha: 0.92),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🏁', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 16),
          Text(
            context.l10n.tracking_ride_finished,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.tracking_ride_finished_body(eventName),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textOnDarkSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 32),
          AppButton(
            label: context.l10n.tracking_back_to_home,
            onPressed: () => context.goAndClearStack(AppRoutes.home),
          ),
        ],
      ),
    );
  }
}
