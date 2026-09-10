import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../design_system/components/app_fab.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/cubits/connectivity/connectivity_cubit.dart';
import '../../../../shared/cubits/connectivity/connectivity_state.dart';
import '../../../../shared/widgets/states/empty_state_view.dart';
import '../../../../shared/widgets/states/error_state_view.dart';
import '../../../../shared/widgets/states/offline_state_view.dart';
import '../../../../shared/widgets/states/skeleton_list.dart';
import '../cubit/events_list_cubit.dart';
import '../cubit/events_list_state.dart';
import '../widgets/events_list_content.dart';
import '../widgets/events_list_header.dart';
import '../widgets/events_segmented_control.dart';

/// Cuerpo de EV1: encabezado + segmentos fijos, y el estado obligatorio
/// (carga/vacío/error/sin conexión/contenido) debajo.
class EventsListView extends StatelessWidget {
  const EventsListView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EventsListCubit>();
    final isOffline =
        context.watch<ConnectivityCubit>().state is ConnectivityOffline;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const EventsListHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: BlocBuilder<EventsListCubit, EventsListState>(
                builder: (context, state) => EventsSegmentedControl(
                  selected: state.segment,
                  onSelected: cubit.selectSegment,
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<EventsListCubit, EventsListState>(
                builder: (context, state) {
                  if (isOffline && (state.isLoading || state.hasError)) {
                    return OfflineStateView(
                      body: context.l10n.events_list_offline_body,
                      onRetry: cubit.refreshCurrent,
                    );
                  }
                  if (state.isLoading) {
                    return const SkeletonList();
                  }
                  if (state.hasError) {
                    return ErrorStateView(
                      title: context.l10n.events_list_error_title,
                      onRetry: cubit.refreshCurrent,
                    );
                  }
                  if (state.isEmpty) {
                    return EmptyStateView(
                      icon: LucideIcons.bike,
                      title: context.l10n.events_list_empty_title,
                      body: state.segment == EventsSegment.upcoming
                          ? context.l10n.events_list_empty_body
                          : context.l10n.events_list_mine_empty_body,
                      actionLabel: context.l10n.events_list_empty_cta,
                      actionIcon: LucideIcons.plus,
                      onAction: () => context.pushNamed(AppRoutes.eventCreate),
                    );
                  }
                  return EventsListContent(
                    events: state.items,
                    onEventTap: (event) => context.pushNamed(
                      AppRoutes.eventDetail,
                      pathParameters: {'id': event.id},
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 76),
        child: Semantics(
          button: true,
          label: context.l10n.events_list_empty_cta,
          child: AppFab(
            onPressed: () => context.pushNamed(AppRoutes.eventCreate),
          ),
        ),
      ),
    );
  }
}
