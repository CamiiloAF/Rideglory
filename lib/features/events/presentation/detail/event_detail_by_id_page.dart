import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/cancel_event_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/get_my_registration_for_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_event_by_id_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';
import 'package:rideglory/features/events/presentation/detail/cubit/event_detail_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/event_detail_page.dart';
import 'package:rideglory/features/events/presentation/detail/params.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class EventDetailByIdPage extends StatefulWidget {
  final String eventId;

  const EventDetailByIdPage({super.key, required this.eventId});

  @override
  State<EventDetailByIdPage> createState() => _EventDetailByIdPageState();
}

class _EventDetailByIdPageState extends State<EventDetailByIdPage> {
  EventRegistrationModel? registrationModel;

  Widget _shell(BuildContext context, Widget body) {
    return Scaffold(
      appBar: AppAppBar(title: context.l10n.event_eventDetail),
      body: body,
    );
  }

  void _listener(BuildContext context, EventDetailState state) {
    state.eventResult.whenOrNull(
      data: (data) =>
          context.read<EventDetailCubit>().loadMyRegistration(data.id!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.pop(registrationModel);
        }
      },
      child: BlocProvider(
        create: (_) => EventDetailCubit(
          getIt<GetMyRegistrationForEventUseCase>(),
          getIt<CancelEventRegistrationUseCase>(),
          getIt<GetEventByIdUseCase>(),
          getIt<UpdateEventUseCase>(),
        )..loadEvent(widget.eventId),
        child: BlocConsumer<EventDetailCubit, EventDetailState>(
          listener: _listener,
          listenWhen: (previous, current) =>
              previous.eventResult != current.eventResult,
          builder: (context, state) {
            return state.eventResult.when(
              initial: () => _shell(context, const SizedBox.shrink()),
              loading: () => _shell(
                context,
                const Center(
                  child: AppLoadingIndicator(
                    variant: AppLoadingIndicatorVariant.inline,
                  ),
                ),
              ),
              data: (event) => EventDetailPage(
                params: EventDetailPageParams(
                  isFromEventDetailByIdPage: true,
                  event: event,
                  onRegistrationChanged: (registration) {
                    registrationModel = registration;
                  },
                ),
              ),
              empty: () => _shell(
                context,
                Center(
                  child: Text(
                    context.l10n.registration_errorLoadingEvent,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
              error: (error) => _shell(
                context,
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                      AppSpacing.gapMd,
                      Text(
                        context.l10n.registration_errorLoadingEvent,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      AppSpacing.gapLg,
                      AppButton(
                        label: context.l10n.retry,
                        onPressed: () => context
                            .read<EventDetailCubit>()
                            .loadEvent(widget.eventId),
                        variant: AppButtonVariant.primary,
                        style: AppButtonStyle.filled,
                        isFullWidth: false,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
