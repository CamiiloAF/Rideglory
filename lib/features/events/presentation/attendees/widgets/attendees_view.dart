import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/theme_extensions.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/presentation/attendees/attendees_cubit.dart';
import 'package:rideglory/features/events/presentation/attendees/widgets/attendees_data_view.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class AttendeesView extends StatelessWidget {
  final EventModel event;

  const AttendeesView({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Scaffold(
      appBar: AppAppBar(
        title: context.l10n.event_participants,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
          color: colorScheme.primary,
        ),
      ),
      body: BlocBuilder<AttendeesCubit, ResultState<List<EventRegistrationModel>>>(
        builder: (context, state) {
          return state.when(
            initial: () => const SizedBox.shrink(),
            loading: () => AppLoadingIndicator(variant: AppLoadingIndicatorVariant.page),
            data: (registrations) =>
                AttendeesDataView(registrations: registrations, event: event),
            empty: () => Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  AppSpacing.gapLg,
                  Text(
                    context.l10n.event_noAttendees,
                    style: context.textTheme.titleMedium
                        ?.copyWith(color: colorScheme.onSurface),
                  ),
                ],
              ),
            ),
            error: (error) => Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      error.message,
                      style: context.textTheme.bodyMedium
                          ?.copyWith(color: colorScheme.onSurface),
                      textAlign: TextAlign.center,
                    ),
                    AppSpacing.gapLg,
                    AppButton(
                      label: context.l10n.retry,
                      onPressed: () => context
                          .read<AttendeesCubit>()
                          .fetchAttendees(event.id!),
                      isFullWidth: false,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
