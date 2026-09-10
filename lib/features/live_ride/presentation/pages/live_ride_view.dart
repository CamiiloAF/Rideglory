import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/result_state.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/cubits/connectivity/connectivity_cubit.dart';
import '../../../../shared/cubits/connectivity/connectivity_state.dart';
import '../../../../shared/widgets/states/error_state_view.dart';
import '../../../../shared/widgets/states/offline_state_view.dart';
import '../../../../shared/widgets/states/skeleton_list.dart';
import '../../domain/location_permission_state.dart';
import '../cubit/live_ride_cubit.dart';
import '../cubit/live_ride_state.dart';
import '../live_ride_error_translator.dart';
import '../live_ride_route_args.dart';
import '../widgets/live_ride_content.dart';
import '../widgets/live_ride_finished_gate.dart';
import '../widgets/live_ride_no_gps_state_view.dart';
import '../widgets/live_ride_permission_state_view.dart';

/// LV1/LV1b/LV7: pantalla de la rodada en vivo. Decide entre los estados
/// obligatorios (sin permiso, sin GPS, carga, error, sin conexión) y el
/// contenido/terminada, sobre el `LiveRideCubit`/`SosCubit` que provee
/// `LiveRideSessionScope`.
///
/// Pencil: RJ9Aq (compartiendo) / gcRLk (sin compartir) / lMJpQ (carga) /
/// J22QFC (sin permiso) / eYAbY (sin GPS) / o19cv (sin conexión) /
/// OQJZS (terminada) / NdP2O (terminada con SOS abierto)
class LiveRideView extends StatefulWidget {
  const LiveRideView({
    required this.eventId,
    super.key,
    this.args,
    this.showMapTiles = true,
  });

  final String eventId;

  /// `null` cuando la pantalla se abre desde un push de SOS (deep link,
  /// sin pasar por el detalle del evento) — `LiveRideCubit.resolveArgs`
  /// la completa por su cuenta.
  final LiveRideRouteArgs? args;

  /// `false` en tests/goldens (ver `LiveRideContent.showMapTiles`).
  final bool showMapTiles;

  @override
  State<LiveRideView> createState() => _LiveRideViewState();
}

class _LiveRideViewState extends State<LiveRideView> {
  @override
  void initState() {
    super.initState();
    context.read<LiveRideCubit>().resolveArgs(widget.eventId, widget.args);
  }

  @override
  Widget build(BuildContext context) {
    final eventId = widget.eventId;
    return BlocBuilder<LiveRideCubit, LiveRideState>(
      builder: (context, state) {
        if (state.permission == LocationPermissionState.serviceDisabled) {
          return Scaffold(
            body: SafeArea(
              child: LiveRideNoGpsStateView(
                onRetry: () => context.read<LiveRideCubit>().load(eventId),
              ),
            ),
          );
        }
        if (state.permission == LocationPermissionState.denied ||
            state.permission == LocationPermissionState.deniedForever) {
          return Scaffold(
            body: SafeArea(
              child: LiveRidePermissionStateView(
                onRetry: () => context.read<LiveRideCubit>().load(eventId),
              ),
            ),
          );
        }

        return BlocBuilder<ConnectivityCubit, ConnectivityState>(
          builder: (context, connectivity) {
            final isOffline = connectivity is ConnectivityOffline;
            return state.riders.when(
              initial: () => const Scaffold(body: SkeletonList()),
              loading: () => const Scaffold(body: SkeletonList()),
              error: (error) => isOffline
                  ? Scaffold(
                      body: SafeArea(
                        child: OfflineStateView(
                          body: context.l10n.live_ride_offline_body,
                          onRetry: () =>
                              context.read<LiveRideCubit>().load(eventId),
                        ),
                      ),
                    )
                  : Scaffold(
                      body: SafeArea(
                        child: ErrorStateView(
                          title: context.l10n.live_ride_error_title,
                          message: liveRideErrorMessage(context, error),
                          onRetry: () =>
                              context.read<LiveRideCubit>().load(eventId),
                        ),
                      ),
                    ),
              empty: () => state.isEventFinished
                  ? LiveRideFinishedGate(eventId: eventId)
                  : LiveRideContent(
                      eventId: eventId,
                      args: state.args,
                      riders: const [],
                      sharing: state.sharing,
                      myPosition: state.myPosition,
                      showMapTiles: widget.showMapTiles,
                    ),
              data: (riders) => state.isEventFinished
                  ? LiveRideFinishedGate(eventId: eventId)
                  : LiveRideContent(
                      eventId: eventId,
                      args: state.args,
                      riders: riders,
                      sharing: state.sharing,
                      myPosition: state.myPosition,
                      showMapTiles: widget.showMapTiles,
                    ),
            );
          },
        );
      },
    );
  }
}
