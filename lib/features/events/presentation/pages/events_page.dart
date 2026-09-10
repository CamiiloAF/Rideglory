import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../cubit/events_list_cubit.dart';
import 'events_list_view.dart';

/// Pestaña Eventos: lista de rodadas (EV1).
class EventsPage extends StatelessWidget {
  const EventsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<EventsListCubit>()..load(),
      child: const EventsListView(),
    );
  }
}
