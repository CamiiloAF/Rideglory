import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/events/presentation/tracking/cubit/live_tracking_cubit.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/rider_telemetry_riders_content.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';

class RiderTelemetryPanel extends StatefulWidget {
  const RiderTelemetryPanel({super.key});

  @override
  State<RiderTelemetryPanel> createState() => _RiderTelemetryPanelState();
}

class _RiderTelemetryPanelState extends State<RiderTelemetryPanel> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final mqHeight = MediaQuery.of(context).size.height;
    final height = _isExpanded ? mqHeight * 0.27 : mqHeight * 0.1;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: height,
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: context.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    context.l10n.map_riderTelemetry,
                    style: context.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => setState(() => _isExpanded = !_isExpanded),
                    icon: Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_down_rounded
                          : Icons.keyboard_arrow_up_rounded,
                    ),
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (_isExpanded) ...[
                AppSpacing.gapMd,
                Expanded(
                  child: BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
                    builder: (context, state) {
                      return RiderTelemetryRidersContent(
                        ridersResult: state.ridersResult,
                        currentUserLatitude: state.currentUserLatitude,
                        currentUserLongitude: state.currentUserLongitude,
                      );
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
