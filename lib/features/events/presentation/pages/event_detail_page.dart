import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../cubit/event_detail_cubit.dart';
import 'event_detail_view.dart';

/// Entrada de ruta de EV2: `/events/detail/:id`.
class EventDetailPage extends StatelessWidget {
  const EventDetailPage({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EventDetailCubit>()..load(eventId),
      child: EventDetailView(eventId: eventId),
    );
  }
}
