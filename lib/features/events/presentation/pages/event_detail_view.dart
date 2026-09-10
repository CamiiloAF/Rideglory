import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/error_state_view.dart';
import '../../../../shared/widgets/states/skeleton_list.dart';
import '../cubit/event_detail_cubit.dart';
import '../cubit/event_detail_state.dart';
import '../event_error_translator.dart';
import '../widgets/event_detail_scaffold.dart';
import '../../../../core/domain/result_state.dart';

/// EV2: orquesta las tres vistas del frame (participante, inscrito,
/// organizador) sobre el mismo cubit.
class EventDetailView extends StatelessWidget {
  const EventDetailView({required this.eventId, super.key});

  final String eventId;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EventDetailCubit>();
    return BlocListener<EventDetailCubit, EventDetailState>(
      listenWhen: (previous, current) => previous.action != current.action,
      listener: (context, state) {
        state.action.whenOrNull(
          error: (error) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(eventErrorMessage(context, error))),
          ),
        );
      },
      child: BlocBuilder<EventDetailCubit, EventDetailState>(
        builder: (context, state) {
          return state.event.when(
            initial: () => const Scaffold(body: SkeletonList()),
            loading: () => const Scaffold(body: SkeletonList()),
            empty: () => const Scaffold(body: SkeletonList()),
            error: (error) => Scaffold(
              body: SafeArea(
                child: ErrorStateView(
                  title: context.l10n.events_detail_error_title,
                  onRetry: () => cubit.load(eventId),
                ),
              ),
            ),
            data: (event) => EventDetailScaffold(
              event: event,
              routeChanges:
                  state.routeChanges.whenOrNull(data: (data) => data) ??
                  const [],
              isBusy: state.isActionInFlight,
              cubit: cubit,
            ),
          );
        },
      ),
    );
  }
}
