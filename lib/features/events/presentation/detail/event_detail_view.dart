import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/di/injection.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/permissions/location_permission_handler.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/cubit/event_detail_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/params.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_body.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_cta_bar.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_header.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_started_banner.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/events/presentation/shared/dialogs/cancel_registration_dialog.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

class EventDetailView extends StatefulWidget {
  const EventDetailView({
    super.key,
    required this.event,
    required this.isFromEventDetailByIdPage,
  });

  final EventModel event;
  final bool isFromEventDetailByIdPage;

  @override
  State<EventDetailView> createState() => EventDetailViewState();
}

class EventDetailViewState extends State<EventDetailView> {
  late EventModel currentEvent;

  @override
  void initState() {
    super.initState();
    currentEvent = widget.event;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = getIt<AuthService>().currentUser?.uid;
    final isOwner = currentEvent.ownerId == currentUserId;

    return PopScope(
      canPop: widget.isFromEventDetailByIdPage,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !widget.isFromEventDetailByIdPage) {
          context.pop(currentEvent);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBackground,
        body: MultiBlocListener(
          listeners: [
            BlocListener<EventDeleteCubit, ResultState<String>>(
              listener: (context, state) {
                state.whenOrNull(
                  data: (_) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.event_eventDeletedSuccess),
                        backgroundColor: Colors.green,
                      ),
                    );
                    context.pop(true);
                  },
                );
              },
            ),
          ],
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: MediaQuery.of(context).size.height * 0.8,
                pinned: true,
                stretch: true,
                backgroundColor: context.colorScheme.surface,
                foregroundColor: context.colorScheme.onSurface,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: () {
                    if (!widget.isFromEventDetailByIdPage) {
                      context.pop(currentEvent);
                    } else {
                      context.pop();
                    }
                  },
                ),
                centerTitle: true,
                title: null,
                actions: [
                  IconButton(
                    icon: Icon(Icons.share_outlined),
                    onPressed: () {
                      // TODO: share event
                    },
                  ),
                  if (isOwner)
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            context
                                .pushNamed<EventModel?>(
                                  AppRoutes.editEvent,
                                  extra: currentEvent,
                                )
                                .then((result) {
                                  if (result != null && mounted) {
                                    setState(() => currentEvent = result);
                                  }
                                });
                            break;
                          case 'attendees':
                            context.pushNamed(
                              AppRoutes.eventAttendees,
                              extra: currentEvent,
                            );
                            break;
                          case 'delete':
                            confirmDelete(context);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit_outlined),
                              SizedBox(width: 12),
                              Text(context.l10n.event_edit),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'attendees',
                          child: Row(
                            children: [
                              Icon(Icons.people_outline),
                              SizedBox(width: 12),
                              Text(context.l10n.event_viewAttendees),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete_outline, color: Colors.red),
                              SizedBox(width: 12),
                              Text(
                                context.l10n.event_delete,
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  titlePadding: const EdgeInsets.only(bottom: 12),
                  title: Text(
                    context.l10n.event_eventDetail,
                    style: TextStyle(
                      color: context.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  background: EventDetailHeaderBackground(event: currentEvent),
                  stretchModes: const [
                    StretchMode.zoomBackground,
                    StretchMode.blurBackground,
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (currentEvent.state == EventState.inProgress ||
                        currentEvent.state == EventState.finished)
                      BlocBuilder<EventDetailCubit, EventDetailState>(
                        builder: (context, state) {
                          return state.registrationResult.maybeWhen(
                            data: (registration) {
                              final isApproved = registration?.status ==
                                  RegistrationStatus.approved;
                              if (!isApproved) return const SizedBox.shrink();

                              return EventDetailStartedBanner(
                                onFollowLive:
                                    currentEvent.state == EventState.inProgress
                                        ? () {
                                            unawaited(_onFollowLivePressed());
                                          }
                                        : null,
                              );
                            },
                            orElse: () => const SizedBox.shrink(),
                          );
                        },
                      ),
                    EventDetailBody(
                      event: currentEvent,
                      onViewMap: () {
                        // TODO: open maps with event.meetingPoint
                      },
                    ),
                    SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: !isOwner
            ? BlocBuilder<EventDetailCubit, EventDetailState>(
                builder: (context, state) {
                  return state.registrationResult.maybeWhen(
                    data: (registration) => EventDetailCTABar(
                      event: currentEvent,
                      registration: registration,
                      onRegister: () => navigateToRegistration(context, null),
                      onRegistrationStatusTap: (reg) {
                        if (reg.status == RegistrationStatus.pending ||
                            reg.status == RegistrationStatus.approved) {
                          _showPendingRegistrationBottomSheet(context, reg);
                        } else if (reg.status ==
                            RegistrationStatus.readyForEdit) {
                          navigateToRegistration(context, reg);
                        }
                      },
                    ),
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              )
            : null,
      ),
    );
  }

  Future<void> navigateToRegistration(
    BuildContext context,
    EventRegistrationModel? registration,
  ) async {
    final result = await context.pushNamed<EventRegistrationModel?>(
      AppRoutes.eventRegistration,
      extra: EventRegistrationParams(
        event: currentEvent,
        registration: registration,
      ),
    );
    if (result != null && context.mounted) {
      context.read<EventDetailCubit>().updateRegistration(result);
    }
  }

  Future<void> _onFollowLivePressed() async {
    final result = await LocationPermissionHandler.request();

    if (result == LocationPermissionResult.granted) {
      if (!mounted) return;
      await context.pushNamed(
        AppRoutes.liveMap,
        extra: currentEvent,
      );
      return;
    }

    if (!mounted) return;

    final openSettings = await ConfirmationDialog.show(
      context: context,
      title: context.l10n.locationPermissionTitle,
      content: context.l10n.locationPermissionMapRequiredMessage,
      cancelLabel: context.l10n.continue_,
      confirmLabel: context.l10n.openSettings,
      dialogType: DialogType.warning,
      isDismissible: true,
    );

    if (openSettings == true) {
      await LocationPermissionHandler.openSettings();
    }
  }

  Future<void> _showPendingRegistrationBottomSheet(
    BuildContext context,
    EventRegistrationModel registration,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: Theme.of(sheetContext).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(context).padding.bottom + 24,
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text(context.l10n.registration_viewDetail),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.pushNamed(
                    AppRoutes.registrationDetail,
                    extra: RegistrationDetailExtra(registration: registration),
                  );
                },
              ),
              ListTile(
                leading: Icon(Icons.cancel_outlined),
                title: Text(context.l10n.event_cancelRegistration),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  confirmCancelRegistration(context, registration);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> confirmCancelRegistration(
    BuildContext context,
    EventRegistrationModel registration,
  ) async {
    await CancelRegistrationDialog.show(
      context: context,
      onCancel: () =>
          context.read<EventDetailCubit>().cancelRegistration(registration.id!),
    );
  }

  Future<void> confirmDelete(BuildContext context) async {
    await ConfirmationDialog.show(
      context: context,
      title: context.l10n.event_deleteEvent,
      content: context.l10n.event_deleteEventMessage,
      dialogType: DialogType.warning,
      confirmLabel: 'Eliminar',
      confirmType: DialogActionType.danger,
      onConfirm: () {
        if (currentEvent.id != null) {
          context.read<EventDeleteCubit>().deleteEvent(currentEvent.id!);
        }
      },
    );
  }
}
