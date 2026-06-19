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
import 'package:rideglory/features/events/presentation/detail/widgets/cta/event_detail_cta_bar_content.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_allowed_brands_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_status_badge.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_description_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_diff_pill.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_hero_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_meeting_point_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_meta_row.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_owner_lifecycle_bar.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_participants_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_participants_summary.dart';
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

  // Suprimir el MapWidget de preview mientras hay otra pantalla encima.
  // Evita dos instancias Mapbox/Metal simultáneas que provocan redraw.
  bool _mapSuppressed = false;

  @override
  void initState() {
    super.initState();
    currentEvent = widget.event;
  }

  Future<void> _openFullscreenMap() async {
    setState(() => _mapSuppressed = true);
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => EventRouteMapScreen(
          points: currentEvent.routePoints,
          title: currentEvent.name,
        ),
      ),
    );
    if (mounted) setState(() => _mapSuppressed = false);
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
    setState(() => _mapSuppressed = true);
    final result = await context.pushNamed<EventRegistrationModel?>(
      AppRoutes.eventRegistration,
      extra: EventRegistrationParams(
        event: currentEvent,
        registration: registration,
      ),
    );
    if (!context.mounted) return;
    setState(() => _mapSuppressed = false);
    if (result != null) {
      final cubit = context.read<EventDetailCubit>();
      cubit.updateRegistration(result);
      cubit.loadAttendees(currentEvent.id!);
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
    context.read<EventDetailCubit>().loadAttendees(currentEvent.id!);
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

    final heroHeight = EventDetailHeroSection.computeHeroHeight(context);
    const overlapAmount = 90.0;
    final heroSliverHeight = heroHeight - overlapAmount;

    return Scaffold(
        backgroundColor: AppColors.darkBgPrimary,
        body: MultiBlocListener(
          listeners: [
            BlocListener<EventDeleteCubit, ResultState<String>>(
              listener: (context, state) {
                state.whenOrNull(
                  data: (_) {
                    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.event_eventDeletedSuccess),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop(true);
                    }
                  },
                );
              },
            ),
            BlocListener<EventDetailCubit, EventDetailState>(
              listenWhen: (prev, curr) =>
                  prev.lastUpdatedEventResult != curr.lastUpdatedEventResult,
              listener: (context, state) {
                state.lastUpdatedEventResult?.maybeWhen(
                  data: (updated) {
                    setState(() => currentEvent = updated);
                    context.read<EventDetailCubit>().clearLastUpdatedEvent();
                  },
                  error: (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.message)));
                    context.read<EventDetailCubit>().clearLastUpdatedEvent();
                  },
                  orElse: () {},
                );
              },
            ),
          ],
          child: CustomScrollView(
            slivers: [
              // ── Único sliver: hero + card en el mismo Stack ───────────────
              // El card está después del hero en el árbol → pinta encima.
              // La altura del Stack la determina el Padding (no el Positioned).
              SliverToBoxAdapter(
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SizedBox(
                        height: heroHeight,
                        child: EventDetailHeroSection(
                          event: currentEvent,
                          isOwner: isOwner,
                          onBack: _pop,
                          onEdit: () => context.pushNamed(
                            AppRoutes.editEvent,
                            extra: EventEditParams(
                              event: currentEvent,
                              onSaved: (updated) {
                                if (mounted) {
                                  setState(() => currentEvent = updated);
                                }
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
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: heroSliverHeight),
                      child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.darkBgPrimary,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle pill
                      Center(
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.darkBorderPrimary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),

                      // Badge de estado (dentro del card, bajo el handle)
                      Padding(
                        padding: const EdgeInsets.only(
                          left: 20,
                          bottom: 12,
                        ),
                        child: EventDetailStatusBadge(event: currentEvent),
                      ),

                      // Contenido con padding horizontal
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title row: nombre + diff pill
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    currentEvent.name,
                                    style: const TextStyle(
                                      color: AppColors.textOnDarkPrimary,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      height: 1.15,
                                      fontFamily: 'Space Grotesk',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                EventDetailDiffPill(event: currentEvent),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Meta row: fecha · tipo · hora
                            EventDetailMetaRow(event: currentEvent),
                            const SizedBox(height: 16),

                            // Descripción expandible (sin título "Sobre la rodada")
                            EventDetailDescriptionSection(event: currentEvent),
                            const SizedBox(height: 16),

                            const Divider(
                              color: AppColors.darkBorderPrimary,
                              height: 1,
                            ),
                            const SizedBox(height: 16),

                            // Punto de encuentro + mapa de ruta
                            EventDetailMeetingPointSection(
                              meetingPoint: currentEvent.meetingPoint,
                              destination: currentEvent.destination.isNotEmpty
                                  ? currentEvent.destination
                                  : null,
                              routePoints: currentEvent.routePoints,
                              suppressMapPreview: _mapSuppressed,
                              onViewMap: currentEvent.routePoints.isNotEmpty
                                  ? _openFullscreenMap
                                  : () => unawaited(
                                        MapLauncherHelper.openSearchByAddress(
                                          currentEvent.meetingPoint,
                                        ),
                                      ),
                            ),

                            // Marcas permitidas
                            if (currentEvent.allowedBrands.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              EventDetailAllowedBrandsSection(
                                event: currentEvent,
                              ),
                            ],

                            const SizedBox(height: 16),

                            // Participantes: owner ve filas con estados; usuario ve resumen
                            if (isOwner)
                              EventDetailParticipantsSection(
                                event: currentEvent,
                              )
                            else
                              EventDetailParticipantsSummary(
                                event: currentEvent,
                              ),

                            // CTA de usuario (embebida en el card, no bottomNavigationBar)
                            if (!isOwner) ...[
                              const SizedBox(height: 24),
                              BlocBuilder<EventDetailCubit, EventDetailState>(
                                builder: (context, state) {
                                  return state.registrationResult.maybeWhen(
                                    data: (registration) =>
                                        EventDetailCtaBarContent(
                                      event: currentEvent,
                                      registration: registration,
                                      onRegister: () =>
                                          navigateToRegistration(context, null),
                                      onFollowLive: () =>
                                          unawaited(_onFollowLivePressed()),
                                      onRegistrationStatusTap: (reg) {
                                        if (reg.status ==
                                                RegistrationStatus.pending ||
                                            reg.status ==
                                                RegistrationStatus.approved) {
                                          confirmCancelRegistration(
                                            context,
                                            reg,
                                          );
                                        } else if (reg.status ==
                                            RegistrationStatus.readyForEdit) {
                                          navigateToRegistration(context, reg);
                                        }
                                      },
                                      onOpenRegistrationDetail: (reg) =>
                                          context.pushNamed(
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
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),          // Container
              ),            // Padding(top: heroSliverHeight)
            ],              // Stack children
          ),                // Stack
        ),                  // SliverToBoxAdapter
      ],                    // slivers
    ),                      // CustomScrollView
  ),                        // MultiBlocListener

        // ── Owner lifecycle bar (sigue como bottomNavigationBar) ───────────
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
            : null,
    );
  }
}
