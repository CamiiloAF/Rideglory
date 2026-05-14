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
    const bg = AppColors.riderCardBg;
    const border = AppColors.darkBorderPrimary;
    final batteryPercent = rider.batteryPercent;
    final batteryColor = batteryPercent < 0
        ? AppColors.tabInactive
        : batteryPercent >= 30
        ? AppColors.success
        : AppColors.warning;

    final roleLabel = rider.role == RiderTrackingRole.lead
        ? context.l10n.map_riderLead
        : context.l10n.map_riderRole;

    final name = rider.fullName.trim();
    final speedKmh = rider.speedKmh.round();
    final separationMeters = distanceFromCurrentUserMeters;
    final batteryValue = batteryPercent < 0
        ? EventStrings.trackingBatteryUnknown
        : '$batteryPercent%';

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withValues(alpha: 0.20),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.45),
                        ),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: rider.isActive ? AppColors.success : border,
                          border: Border.all(color: bg, width: 2),
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
                                color: Colors.white,
                              ),
                            ),
                          ),
                          AppSpacing.hGapSm,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              roleLabel.toUpperCase(),
                              style: const TextStyle(
                                color: AppColors.darkBgPrimary,
                                fontSize: 10,
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
                          color: AppColors.textOnDarkSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            AppSpacing.gapSm,
            Row(
              children: [
                TelemetryMetric(
                  label: context.l10n.map_speed,
                  value: '${speedKmh}km/h',
                  icon: Icons.speed,
                ),
                AppSpacing.hGapSm,
                TelemetryMetric(
                  label: context.l10n.map_distanceFromYou,
                  value: separationMeters != null
                      ? _formatDistance(separationMeters.round())
                      : EventStrings.trackingDistanceUnavailable,
                  icon: Icons.route,
                ),
                AppSpacing.hGapSm,
                TelemetryMetric(
                  label: context.l10n.map_battery,
                  value: batteryValue,
                  icon: Icons.battery_full,
                  valueColor: batteryColor,
                ),
              ],
            ),
          ],
        ),
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
