import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../live_ride/presentation/cubit/sos_cubit.dart';
import '../cubit/event_detail_cubit.dart';
import 'event_detail_view.dart';

/// Entrada de ruta de EV2: `/events/detail/:id`. Provee también [SosCubit]
/// para que, si la rodada está en curso, `EventLiveRideBanner` pueda
/// mostrar un banner propio cuando el rider ya tiene un SOS pendiente o
/// confirmado — no se carga aquí, solo se crea, `EventLiveRideBanner`
/// dispara `load` cuando se monta.
class EventDetailPage extends StatelessWidget {
  const EventDetailPage({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<EventDetailCubit>()..load(eventId)),
        BlocProvider(create: (_) => getIt<SosCubit>()),
      ],
      child: EventDetailView(eventId: eventId),
    );
  }
}
