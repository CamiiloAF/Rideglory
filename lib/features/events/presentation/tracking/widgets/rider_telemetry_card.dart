import 'package:flutter/material.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/telemetry_metric.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class RiderTelemetryCard extends StatelessWidget {
  const RiderTelemetryCard({
    super.key,
    required this.name,
    required this.roleLabel,
    required this.deviceLabel,
    required this.speedKmh,
    required this.distanceMeters,
    required this.batteryPercent,
    required this.isActive,
  });

  final String name;
  final String roleLabel;
  final String deviceLabel;
  final int speedKmh;
  final int distanceMeters;
  final int batteryPercent;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final bg = context.colorScheme.surfaceContainerHighest;
    final border = context.colorScheme.outlineVariant;
    final batteryColor = batteryPercent >= 30
        ? context.appColors.success
        : context.appColors.warning;

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),
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
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colorScheme.primary.withValues(alpha: 0.20),
                        border: Border.all(
                          color: context.colorScheme.primary.withValues(alpha: 0.45),
                        ),
                      ),
                      child: Icon(Icons.person, color: context.colorScheme.primary),
                    ),
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive ? context.appColors.success : border,
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
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: context.colorScheme.onSurface,
                              ),
                            ),
                          ),
                          AppSpacing.hGapSm,
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: context.colorScheme.primary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              roleLabel.toUpperCase(),
                              style: context.labelSmall?.copyWith(
                                color: context.colorScheme.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      AppSpacing.gapXxs,
                      Text(
                        deviceLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
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
                  label: context.l10n.map_distance,
                  value: '${distanceMeters}m',
                  icon: Icons.route,
                ),
                AppSpacing.hGapSm,
                TelemetryMetric(
                  label: context.l10n.map_battery,
                  value: '$batteryPercent%',
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
}
