import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/features/events/presentation/tracking/cubit/live_tracking_cubit.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/rider_telemetry_panel.dart';
import 'package:rideglory/features/events/presentation/tracking/widgets/sos_button.dart';

/// SOS button overlay for the live map. Hidden once the ride has finished.
///
/// `buildWhen` must react to `isFinished` (not only `hasSentSos`), otherwise the
/// button stays on screen after the ride ends without a matching `hasSentSos`
/// change.
class LiveMapSosButton extends StatelessWidget {
  const LiveMapSosButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveTrackingCubit, LiveTrackingState>(
      buildWhen: (prev, next) =>
          prev.hasSentSos != next.hasSentSos ||
          prev.isFinished != next.isFinished,
      builder: (context, state) {
        if (state.isFinished) return const SizedBox.shrink();
        return Positioned(
          right: 16,
          bottom:
              RiderTelemetryPanel.expandedBaseHeight +
              MediaQuery.of(context).padding.bottom +
              12,
          child: SosButton(
            label: context.l10n.map_sos,
            isActive: state.hasSentSos,
            onPressed: onPressed,
          ),
        );
      },
    );
  }
}
