import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';

class RiderListItem extends StatelessWidget {
  const RiderListItem({super.key, required this.rider});

  final RiderTrackingModel rider;

  Color _batteryColor(int percent) {
    if (percent < 0) return AppColors.tabInactive;
    if (percent >= 30) return AppColors.success;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    final isLead = rider.role == RiderTrackingRole.lead;
    final name = rider.fullName.trim();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorderPrimary),
      ),
      child: Row(
        children: [
          // Avatar
          Stack(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isLead
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : AppColors.darkTertiary,
                  border: Border.all(
                    color: isLead
                        ? AppColors.primary.withValues(alpha: 0.55)
                        : AppColors.darkBorderLight,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.person,
                  color: isLead
                      ? AppColors.primary
                      : AppColors.textOnDarkSecondary,
                  size: 22,
                ),
              ),
              Positioned(
                right: 1,
                bottom: 1,
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rider.isActive
                        ? AppColors.success
                        : AppColors.tabInactive,
                    border: Border.all(
                      color: AppColors.darkCard,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.hGapMd,
          // Info
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
                          color: AppColors.textOnDarkPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (isLead) ...[
                      AppSpacing.hGapSm,
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          context.l10n.map_riderLead.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.darkBgPrimary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                AppSpacing.gapXxs,
                Row(
                  children: [
                    const Icon(
                      Icons.speed_rounded,
                      size: 12,
                      color: AppColors.textOnDarkTertiary,
                    ),
                    AppSpacing.hGapXxs,
                    Text(
                      '${rider.speedKmh.round()} km/h',
                      style: const TextStyle(
                        color: AppColors.textOnDarkTertiary,
                        fontSize: 12,
                      ),
                    ),
                    AppSpacing.hGapMd,
                    Icon(
                      Icons.battery_full_rounded,
                      size: 12,
                      color: _batteryColor(rider.batteryPercent),
                    ),
                    AppSpacing.hGapXxs,
                    Text(
                      rider.batteryPercent < 0
                          ? '—'
                          : '${rider.batteryPercent}%',
                      style: TextStyle(
                        color: _batteryColor(rider.batteryPercent),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Status pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: rider.isActive
                  ? AppColors.successSubtle
                  : AppColors.darkTertiary,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: rider.isActive
                    ? AppColors.success.withValues(alpha: 0.4)
                    : AppColors.darkBorderPrimary,
              ),
            ),
            child: Text(
              rider.isActive
                  ? context.l10n.map_activeRiders
                  : context.l10n.notAvailable,
              style: TextStyle(
                color: rider.isActive
                    ? AppColors.success
                    : AppColors.textOnDarkTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
