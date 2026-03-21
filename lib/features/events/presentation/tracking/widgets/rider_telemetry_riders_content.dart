import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/rider_telemetry_card.dart';
import 'package:rideglory/design_system/design_system.dart';

class RiderTelemetryRidersContent extends StatelessWidget {
  const RiderTelemetryRidersContent({
    super.key,
    required this.ridersResult,
    this.currentUserLatitude,
    this.currentUserLongitude,
  });

  final ResultState<List<RiderTrackingModel>> ridersResult;
  final double? currentUserLatitude;
  final double? currentUserLongitude;

  @override
  Widget build(BuildContext context) {
    return ridersResult.when(
      initial: () => const Center(
        child: AppLoadingIndicator(variant: AppLoadingIndicatorVariant.inline),
      ),
      loading: () => const Center(
        child: AppLoadingIndicator(variant: AppLoadingIndicatorVariant.inline),
      ),
      data: (riders) {
        if (riders.isEmpty) {
          return Center(
            child: Text(
              EventStrings.trackingNoActiveRiders,
              textAlign: TextAlign.center,
              style: context.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: riders.length,
          separatorBuilder: (_, _) => AppSpacing.hGapMd,
          itemBuilder: (context, index) {
            final rider = riders[index];
            return RiderTelemetryCard(
              rider: rider,
              distanceFromCurrentUserMeters: _distanceFromCurrentUserMeters(
                rider: rider,
                currentUserLatitude: currentUserLatitude,
                currentUserLongitude: currentUserLongitude,
              ),
            );
          },
        );
      },
      empty: () => Center(
        child: Text(
          EventStrings.trackingNoActiveRiders,
          textAlign: TextAlign.center,
          style: context.bodyMedium?.copyWith(
            color: context.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      error: (e) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            e.message,
            textAlign: TextAlign.center,
            style: context.bodyMedium?.copyWith(
              color: context.colorScheme.error,
            ),
          ),
        ),
      ),
    );
  }
}

double? _distanceFromCurrentUserMeters({
  required RiderTrackingModel rider,
  required double? currentUserLatitude,
  required double? currentUserLongitude,
}) {
  final myLat = currentUserLatitude;
  final myLon = currentUserLongitude;
  if (myLat == null || myLon == null) {
    return null;
  }
  return Geolocator.distanceBetween(
    myLat,
    myLon,
    rider.latitude,
    rider.longitude,
  );
}
