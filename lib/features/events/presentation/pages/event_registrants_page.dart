import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../cubit/registrants_cubit.dart';
import 'event_registrants_view.dart';

/// Entrada de ruta de EV5: `/events/detail/:id/inscritos`.
class EventRegistrantsPage extends StatelessWidget {
  const EventRegistrantsPage({
    required this.eventId,
    this.maxParticipants,
    super.key,
  });

  final String eventId;
  final int? maxParticipants;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RegistrantsCubit>()..load(eventId),
      child: EventRegistrantsView(maxParticipants: maxParticipants),
    );
  }
}
