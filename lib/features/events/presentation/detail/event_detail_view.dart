import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/permissions/location_permission_handler.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/form/event_edit_params.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/cubit/event_detail_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/params.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_about_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_allowed_brands_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_cta_bar.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_header_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_hero_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_meeting_point_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_meta_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_owner_lifecycle_bar.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_participants_section.dart';
import 'package:rideglory/features/events/presentation/detail/event_route_map_screen.dart';
import 'package:rideglory/features/events/presentation/shared/dialogs/cancel_registration_dialog.dart';
import 'package:rideglory/shared/helpers/map_launcher_helper.dart';
import 'package:rideglory/shared/router/app_routes.dart';

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

  // ── Navigation helpers ────────────────────────────────────────────────────

  void _pop() {
    if (!widget.isFromEventDetailByIdPage) {
      context.pop(currentEvent);
    } else {
      context.pop();
    }
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
      await context.pushNamed(AppRoutes.liveMap, extra: currentEvent);
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

  Future<void> confirmCancelRegistration(
    BuildContext context,
    EventRegistrationModel registration,
  ) async {
    final cancelled = await CancelRegistrationDialog.show(
      context: context,
      onCancel: () =>
          context.read<EventDetailCubit>().cancelRegistration(registration.id!),
    );
    if (!cancelled || !context.mounted) return;
    context.read<MyRegistrationsCubit>().onChangeRegistration(
      registration.copyWith(status: RegistrationStatus.cancelled),
    );
  }

  Future<void> _confirmStopEvent(BuildContext context) async {
    await ConfirmationDialog.show(
      context: context,
      title: context.l10n.event_stopEventConfirmTitle,
      content: context.l10n.event_stopEventConfirmMessage,
      dialogType: DialogType.warning,
      confirmLabel: context.l10n.event_stopEvent,
      confirmType: DialogActionType.danger,
      isDismissible: true,
      onConfirm: () {
        context.read<EventDetailCubit>().stopEvent(currentEvent);
      },
    );
  }

  Future<void> confirmDelete(BuildContext context) async {
    await ConfirmationDialog.show(
      context: context,
      title: context.l10n.event_deleteEvent,
      content: context.l10n.event_deleteEventMessage,
      dialogType: DialogType.warning,
      confirmLabel: context.l10n.event_delete,
      confirmType: DialogActionType.danger,
      onConfirm: () {
        if (currentEvent.id != null) {
          context.read<EventDeleteCubit>().deleteEvent(currentEvent.id!);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.watch<AuthCubit>().state.currentUser?.id;
    final isOwner = currentEvent.ownerId == currentUserId;

    return PopScope(
      canPop: widget.isFromEventDetailByIdPage,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !widget.isFromEventDetailByIdPage) {
          context.pop(currentEvent);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        body: MultiBlocListener(
          listeners: [
            BlocListener<EventDeleteCubit, ResultState<String>>(
              listener: (context, state) {
                state.whenOrNull(
                  data: (_) {
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      SnackBar(
                        content:
                            Text(context.l10n.event_eventDeletedSuccess),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    // Usar Navigator directamente para garantizar que el pop
                    // sucede independientemente de PopScope.canPop.
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                );
              },
            ),
            BlocListener<EventDetailCubit, EventDetailState>(
              listenWhen: (prev, curr) =>
                  prev.lastUpdatedEventResult !=
                  curr.lastUpdatedEventResult,
              listener: (context, state) {
                state.lastUpdatedEventResult?.maybeWhen(
                  data: (updated) {
                    setState(() => currentEvent = updated);
                    context
                        .read<EventDetailCubit>()
                        .clearLastUpdatedEvent();
                  },
                  error: (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.message)));
                    context
                        .read<EventDetailCubit>()
                        .clearLastUpdatedEvent();
                  },
                  orElse: () {},
                );
              },
            ),
          ],
          child: CustomScrollView(
            slivers: [
              // ── Hero image + back/share buttons ──────────────────────
              SliverToBoxAdapter(
                child: EventDetailHeroSection(
                  event: currentEvent,
                  isOwner: isOwner,
                  onBack: _pop,
                  onEdit: () => context.pushNamed(
                    AppRoutes.editEvent,
                    extra: EventEditParams(
                      event: currentEvent,
                      onSaved: (updated) {
                        if (mounted) setState(() => currentEvent = updated);
                      },
                    ),
                  ),
                  onAttendees: () => context.pushNamed(
                    AppRoutes.eventAttendees,
                    extra: currentEvent,
                  ),
                  onDelete: () => confirmDelete(context),
                ),
              ),

              // ── Content sections ─────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Event Header block
                      EventDetailHeaderSection(event: currentEvent),
                      const SizedBox(height: 24),

                      // Meta (difficulty + type + time)
                      EventDetailMetaSection(event: currentEvent),
                      const SizedBox(height: 24),

                      // About
                      EventDetailAboutSection(event: currentEvent),
                      const SizedBox(height: 24),

                      // Meeting point + route map
                      EventDetailMeetingPointSection(
                        meetingPoint: currentEvent.meetingPoint,
                        destination: currentEvent.destination.isNotEmpty
                            ? currentEvent.destination
                            : null,
                        routePoints: currentEvent.routePoints,
                        onViewMap: currentEvent.routePoints.isNotEmpty
                            ? () => Navigator.of(context).push( // Custom: EventRouteMapScreen has no go_router named route — anonymous push preserved. Reason: ephemeral sub-screen, no deep-link requirement.
                                  MaterialPageRoute<void>(
                                    builder: (_) => EventRouteMapScreen(
                                      points: currentEvent.routePoints,
                                      title: currentEvent.name,
                                    ),
                                  ),
                                )
                            : () => unawaited(
                                  MapLauncherHelper.openSearchByAddress(
                                    currentEvent.meetingPoint,
                                  ),
                                ),
                      ),
                      const SizedBox(height: 24),

                      // Allowed brands
                      if (currentEvent.allowedBrands.isNotEmpty) ...[
                        EventDetailAllowedBrandsSection(event: currentEvent),
                        const SizedBox(height: 24),
                      ],

                      // Participants — owner only
                      if (isOwner)
                        EventDetailParticipantsSection(event: currentEvent),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Bottom CTA bar ────────────────────────────────────────────────
        bottomNavigationBar: isOwner
            ? (currentEvent.state == EventState.scheduled ||
                      currentEvent.state == EventState.inProgress ||
                      currentEvent.state == EventState.draft
                  ? BlocBuilder<EventDetailCubit, EventDetailState>(
                      buildWhen: (prev, curr) =>
                          prev.lastUpdatedEventResult !=
                          curr.lastUpdatedEventResult,
                      builder: (context, state) {
                        final loading =
                            state.lastUpdatedEventResult?.maybeWhen(
                              loading: () => true,
                              orElse: () => false,
                            ) ??
                            false;
                        return EventDetailOwnerLifecycleBar(
                          event: currentEvent,
                          isLoading: loading,
                          onStart: () => context
                              .read<EventDetailCubit>()
                              .startEvent(currentEvent),
                          onStop: () => _confirmStopEvent(context),
                          onOpenMap: () =>
                              unawaited(_onFollowLivePressed()),
                          onPublish: () => context
                              .read<EventDetailCubit>()
                              .publishEvent(currentEvent),
                        );
                      },
                    )
                  : null)
            : BlocBuilder<EventDetailCubit, EventDetailState>(
                builder: (context, state) {
                  return state.registrationResult.maybeWhen(
                    data: (registration) => EventDetailCTABar(
                      event: currentEvent,
                      registration: registration,
                      onRegister: () =>
                          navigateToRegistration(context, null),
                      onFollowLive: () =>
                          unawaited(_onFollowLivePressed()),
                      onRegistrationStatusTap: (reg) {
                        if (reg.status == RegistrationStatus.pending ||
                            reg.status == RegistrationStatus.approved) {
                          confirmCancelRegistration(context, reg);
                        } else if (reg.status ==
                            RegistrationStatus.readyForEdit) {
                          navigateToRegistration(context, reg);
                        }
                      },
                      onOpenRegistrationDetail: (reg) => context.pushNamed(
                        AppRoutes.registrationDetail,
                        extra: RegistrationDetailExtra(
                          registration: reg,
                          eventOwnerId: currentEvent.ownerId,
                        ),
                      ),
                    ),
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              ),
      ),
    );
  }

}
