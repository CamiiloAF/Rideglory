import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../events/presentation/cubit/registrants_cubit.dart';
import '../live_ride_route_args.dart';
import 'live_riders_view.dart';

/// Entrada de ruta de LV6: `/events/detail/:id/live/riders`. Provee el
/// [RegistrantsCubit] propio de esta pantalla (el `LiveRideCubit`/
/// `SosCubit` ya vienen de `LiveRideSessionScope`).
class LiveRidersPage extends StatelessWidget {
  const LiveRidersPage({required this.eventId, required this.args, super.key});

  final String eventId;
  final LiveRideRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RegistrantsCubit>()..load(eventId),
      child: LiveRidersView(eventId: eventId, args: args),
    );
  }
}
