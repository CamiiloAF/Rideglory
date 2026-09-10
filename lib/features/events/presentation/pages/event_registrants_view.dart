import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_page_header.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../../../shared/widgets/states/empty_state_view.dart';
import '../../../../shared/widgets/states/result_state_builder.dart';
import '../../domain/registration_status.dart';
import '../cubit/registrants_cubit.dart';
import '../cubit/registrants_state.dart';
import '../widgets/event_registrants_list.dart';
import '../../../../core/domain/result_state.dart';

/// EV5: cuerpo de la pantalla de inscritos para el organizador.
class EventRegistrantsView extends StatelessWidget {
  const EventRegistrantsView({this.maxParticipants, super.key});

  final int? maxParticipants;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<RegistrantsCubit>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            BlocBuilder<RegistrantsCubit, RegistrantsState>(
              builder: (context, state) {
                final approved =
                    state.registrants.whenOrNull(
                      data: (data) => data
                          .where(
                            (registrant) =>
                                registrant.status ==
                                RegistrationStatus.approved,
                          )
                          .length,
                    ) ??
                    0;
                final title = maxParticipants == null
                    ? context.l10n.events_registrants_title_unlimited(approved)
                    : context.l10n.events_registrants_title(
                        approved,
                        maxParticipants!,
                      );
                return AppPageHeader(title: title);
              },
            ),
            Expanded(
              child: BlocBuilder<RegistrantsCubit, RegistrantsState>(
                builder: (context, state) {
                  return ResultStateBuilder(
                    state: state.registrants,
                    onRetry: cubit.retry,
                    emptyBuilder: (context) => EmptyStateView(
                      icon: LucideIcons.users,
                      title: context.l10n.events_registrants_empty_title,
                      body: context.l10n.events_registrants_empty_body,
                    ),
                    onData: (context, registrants) {
                      if (registrants.isEmpty) {
                        return EmptyStateView(
                          icon: LucideIcons.users,
                          title: context.l10n.events_registrants_empty_title,
                          body: context.l10n.events_registrants_empty_body,
                        );
                      }
                      return EventRegistrantsList(registrants: registrants);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
