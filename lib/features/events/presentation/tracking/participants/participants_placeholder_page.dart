import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Participants / Riders panel (Pencil page 34).
///
/// Shows an active-riders list sourced from [event]. When the full tracking
/// cubit is in scope this widget can be upgraded to a BlocBuilder; for now it
/// renders from whatever riders are passed in or shows a styled empty-state.
class ParticipantsPlaceholderPage extends StatelessWidget {
  const ParticipantsPlaceholderPage({
    super.key,
    required this.event,
    this.riders = const [],
  });

  final EventModel event;

  /// Active riders to display; defaults to empty list when not provided.
  final List<RiderTrackingModel> riders;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.darkCard,
        foregroundColor: AppColors.textOnDarkPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.map_participantsTitle,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              event.name,
              style: const TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.darkBorderPrimary),
        ),
      ),
      body: riders.isEmpty
          ? _buildEmptyState(context)
          : _buildRiderList(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.darkTertiary,
                border: Border.all(color: AppColors.darkBorderPrimary),
              ),
              child: const Icon(
                Icons.group_rounded,
                color: AppColors.textOnDarkTertiary,
                size: 32,
              ),
            ),
            AppSpacing.gapXl,
            Text(
              context.l10n.map_noActiveRidersMessage,
              style: const TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderList(BuildContext context) {
    final active = riders.where((r) => r.isActive).toList();
    final inactive = riders.where((r) => !r.isActive).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        if (active.isNotEmpty) ...[
          _SectionHeader(
            label: context.l10n.map_activeRiders.toUpperCase(),
            count: active.length,
          ),
          ...active.map((r) => _RiderListItem(rider: r)),
        ],
        if (inactive.isNotEmpty) ...[
          AppSpacing.gapMd,
          _SectionHeader(
            label: context.l10n.map_riderRole.toUpperCase(),
            count: inactive.length,
            isInactive: true,
          ),
          ...inactive.map((r) => _RiderListItem(rider: r)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.label,
    required this.count,
    this.isInactive = false,
  });

  final String label;
  final int count;
  final bool isInactive;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isInactive ? AppColors.tabInactive : AppColors.success,
            ),
          ),
          AppSpacing.hGapSm,
          Text(
            '$label ($count)',
            style: const TextStyle(
              color: AppColors.textOnDarkTertiary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _RiderListItem extends StatelessWidget {
  const _RiderListItem({required this.rider});

  final RiderTrackingModel rider;

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
                        name.isEmpty
                            ? context.l10n.map_riderRole
                            : name,
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

  Color _batteryColor(int percent) {
    if (percent < 0) return AppColors.tabInactive;
    if (percent >= 30) return AppColors.success;
    return AppColors.warning;
  }
}
