import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/events/domain/model/rider_tracking_model.dart';
import 'package:rideglory/features/events/presentation/tracking/cubit/live_tracking_cubit.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/rider_telemetry_riders_content.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

/// Collapsible telemetry panel at the bottom of the live map (Pencil page 33).
class RiderTelemetryPanel extends StatefulWidget {
  const RiderTelemetryPanel({
    super.key,
    required this.selectedRiderId,
    required this.onRiderTap,
  });

  /// Shared selection with the map; highlights and scrolls to this rider.
  final ValueListenable<String?> selectedRiderId;

  /// Called when a rider card is tapped, to center the map on that rider.
  final ValueChanged<RiderTrackingModel> onRiderTap;

  static const double _headerHeight = 56.0;
  static const double _dividerHeight = 1.0;
  // 128 px content + 8 px slack so font-metric variance never overflows
  static const double _contentHeight = 136.0;
  static const double collapsedHeight = 64.0;

  /// Base expanded height without bottom safe-area inset.
  /// +4 px buffer absorbs SafeArea fractional insets and font-metric variance.
  static const double expandedBaseHeight =
      _headerHeight + _dividerHeight + _contentHeight + 4.0;

  @override
  State<RiderTelemetryPanel> createState() => _RiderTelemetryPanelState();
}

class _RiderTelemetryPanelState extends State<RiderTelemetryPanel> {

  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final expandedHeight = RiderTelemetryPanel.expandedBaseHeight + bottomInset;
    // Collapsed height must also absorb the safe-area bottom inset; without it
    // the 56 px header + iOS home-indicator inset (~34 px) exceeds 64 px → overflow.
    final collapsedHeight = RiderTelemetryPanel.collapsedHeight + bottomInset;
    final height = _isExpanded ? expandedHeight : collapsedHeight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: const Border(
          top: BorderSide(color: AppColors.darkBorderPrimary),
          left: BorderSide(color: AppColors.darkBorderPrimary),
          right: BorderSide(color: AppColors.darkBorderPrimary),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkBgPrimary.withValues(alpha: 0.35),
            blurRadius: 28,
            offset: const Offset(0, -12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // Drag handle + header row
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _isExpanded = !_isExpanded),
                child: SizedBox(
                  height: 56,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        // Live indicator dot
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.success,
                          ),
                        ),
                        AppSpacing.hGapSm,
                        Text(
                          context.l10n.map_riderTelemetry.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.textOnDarkPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const Spacer(),
                        // Rider count badge
                        BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
                          buildWhen: (prev, next) =>
                              prev.ridersResult != next.ridersResult,
                          builder: (context, state) {
                            final count = state.ridersResult.when(
                              initial: () => 0,
                              loading: () => 0,
                              data: (riders) =>
                                  riders.where((r) => r.isActive).length,
                              empty: () => 0,
                              error: (_) => 0,
                            );
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primarySubtle,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: AppColors.primary.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                '$count ${context.l10n.map_activeRiders}',
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            );
                          },
                        ),
                        AppSpacing.hGapSm,
                        // Chevron toggle
                        Icon(
                          _isExpanded
                              ? Icons.keyboard_arrow_down_rounded
                              : Icons.keyboard_arrow_up_rounded,
                          color: AppColors.textOnDarkTertiary,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (_isExpanded)
                const ColoredBox(
                  color: AppColors.darkBorderPrimary,
                  child: SizedBox(height: 1, width: double.infinity),
                ),
              if (_isExpanded)
                SizedBox(
                  height: RiderTelemetryPanel._contentHeight,
                  child: BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
                    builder: (context, state) {
                      return RiderTelemetryRidersContent(
                        ridersResult: state.ridersResult,
                        currentUserLatitude: state.currentUserLatitude,
                        currentUserLongitude: state.currentUserLongitude,
                        selectedRiderId: widget.selectedRiderId,
                        sosUserId: state.sosAlertResult.whenOrNull(
                          data: (alert) => alert?.userId,
                        ),
                        onRiderTap: widget.onRiderTap,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
