import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection.dart';
import 'cubit/live_ride_cubit.dart';
import 'cubit/sos_cubit.dart';

/// `ShellRoute` de LV1/LV3-LV4/LV6: crea **una sola vez** [LiveRideCubit] y
/// [SosCubit] para toda la sesión de "rodada en vivo" de un evento, y los
/// comparte entre las tres pantallas (`/live`, `/live/sos`,
/// `/live/riders`). Sin esto, cada `pushNamed` a la pantalla de SOS
/// crearía un [SosCubit] nuevo y perdería el `mine` recién confirmado por
/// LV3 hasta que Realtime lo reconciliara — inaceptable para una pantalla
/// de seguridad.
class LiveRideSessionScope extends StatefulWidget {
  const LiveRideSessionScope({
    required this.eventId,
    required this.child,
    super.key,
  });

  final String eventId;
  final Widget child;

  @override
  State<LiveRideSessionScope> createState() => _LiveRideSessionScopeState();
}

class _LiveRideSessionScopeState extends State<LiveRideSessionScope> {
  late final LiveRideCubit _liveRideCubit;
  late final SosCubit _sosCubit;

  @override
  void initState() {
    super.initState();
    _liveRideCubit = getIt<LiveRideCubit>()..load(widget.eventId);
    _sosCubit = getIt<SosCubit>()..load(widget.eventId);
  }

  @override
  void dispose() {
    _liveRideCubit.close();
    _sosCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<LiveRideCubit>.value(value: _liveRideCubit),
        BlocProvider<SosCubit>.value(value: _sosCubit),
      ],
      child: widget.child,
    );
  }
}
