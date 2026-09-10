import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/result_state.dart';
import '../../../../design_system/components/app_page_header.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/error_state_view.dart';
import '../../../../shared/widgets/states/skeleton_list.dart';
import '../../../events/domain/registration_status.dart';
import '../../../events/presentation/cubit/registrants_cubit.dart';
import '../../../events/presentation/cubit/registrants_state.dart';
import '../live_ride_route_args.dart';
import '../widgets/internal/live_riders_merged_list.dart';

/// LV6: lista completa de riders — estado y botón de llamar por cada uno.
/// Fusiona `event_registrations_for_organizer` (teléfono, solo visible
/// para el organizador) con `live_riders` (posición en vivo), por eso
/// necesita su propio [RegistrantsCubit] (provisto por `LiveRidersPage`)
/// además del [LiveRideCubit] de la sesión. Cuando el viewer es un
/// participante (no el organizador), `RegistrantsState` llega vacío —
/// [LiveRidersMergedList] completa igual la fila del líder desde
/// `contacts`.
///
/// Pencil: UGgbU
class LiveRidersView extends StatelessWidget {
  const LiveRidersView({required this.eventId, required this.args, super.key});

  final String eventId;
  final LiveRideRouteArgs args;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppPageHeader(title: context.l10n.live_riders_page_header),
      body: SafeArea(
        top: false,
        child: BlocBuilder<RegistrantsCubit, RegistrantsState>(
          builder: (context, registrantsState) {
            return registrantsState.registrants.when(
              initial: () => const SkeletonList(),
              loading: () => const SkeletonList(),
              empty: () => LiveRidersMergedList(
                approvedRegistrants: const [],
                args: args,
              ),
              error: (_) => ErrorStateView(
                title: context.l10n.events_registrants_error_title,
                onRetry: () => context.read<RegistrantsCubit>().retry(),
              ),
              data: (registrants) {
                final approved = registrants
                    .where(
                      (registrant) =>
                          registrant.status == RegistrationStatus.approved,
                    )
                    .toList();
                return LiveRidersMergedList(
                  approvedRegistrants: approved,
                  args: args,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
