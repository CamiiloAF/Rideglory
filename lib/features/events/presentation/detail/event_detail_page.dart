import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/constants/event_strings.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/use_cases/cancel_event_registration_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_event_by_id_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_my_registration_for_event_use_case.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/cubit/event_detail_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/params.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_body.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_cta_bar.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_header.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_started_banner.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_registration_status_card.dart';
import 'package:rideglory/features/events/presentation/shared/dialogs/cancel_registration_dialog.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

class EventDetailPage extends StatelessWidget {
  final EventDetailPageParams params;

  const EventDetailPage({super.key, required this.params});

  void _listener(BuildContext context, EventDetailState state) {
    state.registrationResult.whenOrNull(
      data: (registration) {
        if (params.onRegistrationChanged != null && registration != null) {
          params.onRegistrationChanged!(registration);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        if (!params.isFromEventDetailByIdPage)
          BlocProvider(
            create: (_) => EventDetailCubit(
              getIt<GetMyRegistrationForEventUseCase>(),
              getIt<CancelEventRegistrationUseCase>(),
              getIt<GetEventByIdUseCase>(),
            )..loadMyRegistration(params.event.id!),
          ),
        BlocProvider(create: (_) => getIt<EventDeleteCubit>()),
      ],
      child: BlocListener<EventDetailCubit, EventDetailState>(
        listener: _listener,
        child: _EventDetailView(
          event: params.event,
          isFromEventDetailByIdPage: params.isFromEventDetailByIdPage,
        ),
      ),
    );
  }
}

class _EventDetailView extends StatefulWidget {
  final EventModel event;
  final bool isFromEventDetailByIdPage;

  const _EventDetailView({
    required this.event,
    required this.isFromEventDetailByIdPage,
  });

  @override
  State<_EventDetailView> createState() => _EventDetailViewState();
}

class _EventDetailViewState extends State<_EventDetailView> {
  late EventModel _currentEvent;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = getIt<AuthService>().currentUser?.uid;
    final isOwner = _currentEvent.ownerId == currentUserId;

    return PopScope(
      canPop: widget.isFromEventDetailByIdPage,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !widget.isFromEventDetailByIdPage) {
          context.pop(_currentEvent);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        appBar: AppBar(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkTextPrimary,
          centerTitle: true,
          title: const Text(EventStrings.eventDetail),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              if (!widget.isFromEventDetailByIdPage) {
                context.pop(_currentEvent);
              } else {
                context.pop();
              }
            },
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () {
                // TODO: share event
              },
            ),
            if (isOwner)
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      context.pushNamed<EventModel?>(
                        AppRoutes.editEvent,
                        extra: _currentEvent,
                      ).then((result) {
                        if (result != null && mounted) {
                          setState(() => _currentEvent = result);
                        }
                      });
                      break;
                    case 'attendees':
                      context.pushNamed(
                        AppRoutes.eventAttendees,
                        extra: _currentEvent,
                      );
                      break;
                    case 'delete':
                      _confirmDelete(context);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined),
                        SizedBox(width: 12),
                        Text(EventStrings.edit),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'attendees',
                    child: Row(
                      children: [
                        Icon(Icons.people_outline),
                        SizedBox(width: 12),
                        Text(EventStrings.viewAttendees),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red),
                        SizedBox(width: 12),
                        Text(EventStrings.delete, style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
          ],
        ),
        body: MultiBlocListener(
          listeners: [
            BlocListener<EventDeleteCubit, ResultState<String>>(
              listener: (context, state) {
                state.whenOrNull(
                  data: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(EventStrings.eventDeletedSuccess),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.pop(true);
                  },
                );
              },
            ),
          ],
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                EventDetailHeader(event: _currentEvent),
                if (_currentEvent.state == EventState.inProgress ||
                    _currentEvent.state == EventState.finished)
                  EventDetailStartedBanner(
                    onFollowLive: _currentEvent.state == EventState.inProgress
                        ? () {}
                        : null,
                  ),
                EventDetailBody(
                  event: _currentEvent,
                  onViewMap: () {
                    // TODO: open maps with event.meetingPoint
                  },
                ),
                if (!isOwner)
                  BlocBuilder<EventDetailCubit, EventDetailState>(
                    builder: (context, state) {
                      return state.registrationResult.maybeWhen(
                        data: (registration) {
                          if (registration == null) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                            child: EventRegistrationStatusCard(
                              event: _currentEvent,
                              registration: registration,
                              onRegister: () => _navigateToRegistration(
                                context,
                                registration.status ==
                                        RegistrationStatus.cancelled
                                    ? registration
                                    : null,
                              ),
                              onEditRegistration: () =>
                                  _navigateToRegistration(context, registration),
                              onCancelRegistration: () =>
                                  _confirmCancelRegistration(
                                    context,
                                    registration,
                                  ),
                            ),
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      );
                    },
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
        bottomNavigationBar: !isOwner
            ? BlocBuilder<EventDetailCubit, EventDetailState>(
                builder: (context, state) {
                  return state.registrationResult.maybeWhen(
                    data: (registration) => EventDetailCTABar(
                      event: _currentEvent,
                      registration: registration,
                      onRegister: () => _navigateToRegistration(context, null),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              )
            : null,
      ),
    );
  }

  Future<void> _navigateToRegistration(
    BuildContext context,
    EventRegistrationModel? registration,
  ) async {
    final result = await context.pushNamed<EventRegistrationModel?>(
      AppRoutes.eventRegistration,
      extra: {'event': _currentEvent, 'registration': registration},
    );
    if (result != null && context.mounted) {
      context.read<EventDetailCubit>().updateRegistration(result);
    }
  }

  Future<void> _confirmCancelRegistration(
    BuildContext context,
    EventRegistrationModel registration,
  ) async {
    await CancelRegistrationDialog.show(
      context: context,
      onCancel: () =>
          context.read<EventDetailCubit>().cancelRegistration(registration.id!),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    await ConfirmationDialog.show(
      context: context,
      title: EventStrings.deleteEvent,
      content: EventStrings.deleteEventMessage,
      dialogType: DialogType.warning,
      confirmLabel: 'Eliminar',
      confirmType: DialogActionType.danger,
      onConfirm: () {
        if (_currentEvent.id != null) {
          context.read<EventDeleteCubit>().deleteEvent(_currentEvent.id!);
        }
      },
    );
  }
}
