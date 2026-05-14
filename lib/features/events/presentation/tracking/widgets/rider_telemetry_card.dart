import 'package:flutter/material.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/telemetry_metric.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class RiderTelemetryCard extends StatelessWidget {
  const RiderTelemetryCard({
    super.key,
    required this.rider,
    this.distanceFromCurrentUserMeters,
  });

  final RiderTrackingModel rider;

  /// Haversine distance from the device GPS to this rider; null if unavailable.
  final double? distanceFromCurrentUserMeters;

  @override
  Widget build(BuildContext context) {
    final batteryPercent = rider.batteryPercent;
    final batteryColor = batteryPercent < 0
        ? AppColors.tabInactive
        : batteryPercent >= 30
        ? AppColors.success
        : AppColors.warning;

    final isLead = rider.role == RiderTrackingRole.lead;
    final roleLabel =
        isLead ? context.l10n.map_riderLead : context.l10n.map_riderRole;

    final name = rider.fullName.trim();
    final speedKmh = rider.speedKmh.round();
    final separationMeters = distanceFromCurrentUserMeters;
    final batteryValue = batteryPercent < 0
        ? EventStrings.trackingBatteryUnknown
        : '$batteryPercent%';

    return Container(
      width: MediaQuery.of(context).size.width * 0.82,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rider header row
          Row(
            children: [
              // Avatar with status dot
              Stack(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isLead
                          ? AppColors.primary.withValues(alpha: 0.20)
                          : AppColors.darkBorderPrimary,
                      border: Border.all(
                        color: isLead
                            ? AppColors.primary.withValues(alpha: 0.55)
                            : AppColors.darkBorderLight,
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.person,
                      color: isLead ? AppColors.primary : AppColors.textOnDarkSecondary,
                      size: 20,
                    ),
                  ),
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: rider.isActive
                            ? AppColors.success
                            : AppColors.tabInactive,
                        border: Border.all(
                          color: AppColors.darkTertiary,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              AppSpacing.hGapMd,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name.isEmpty ? context.l10n.map_riderRole : name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textOnDarkPrimary,
                            ),
                          ),
                        ),
                        AppSpacing.hGapSm,
                        // Role badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: isLead
                                ? AppColors.primary
                                : AppColors.darkBorderPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            roleLabel.toUpperCase(),
                            style: TextStyle(
                              color: isLead
                                  ? AppColors.darkBgPrimary
                                  : AppColors.textOnDarkSecondary,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapXxs,
                    Text(
                      rider.deviceLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textOnDarkTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppSpacing.gapSm,
          // Metrics row
          Row(
            children: [
              TelemetryMetric(
                label: context.l10n.map_speed,
                value: '${speedKmh}km/h',
                icon: Icons.speed_rounded,
              ),
              AppSpacing.hGapSm,
              TelemetryMetric(
                label: context.l10n.map_distanceFromYou,
                value: separationMeters != null
                    ? _formatDistance(separationMeters.round())
                    : EventStrings.trackingDistanceUnavailable,
                icon: Icons.route_rounded,
              ),
              AppSpacing.hGapSm,
              TelemetryMetric(
                label: context.l10n.map_battery,
                value: batteryValue,
                icon: Icons.battery_full_rounded,
                valueColor: batteryColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDistance(int meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return '${km.toStringAsFixed(1)}km';
    }
    return '${meters}m';
  }
}
