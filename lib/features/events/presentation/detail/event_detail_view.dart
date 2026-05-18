import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/extensions/date_extensions.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/core/permissions/location_permission_handler.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/my_registrations_cubit.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/delete/cubit/event_delete_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/cubit/event_detail_cubit.dart';
import 'package:rideglory/features/events/presentation/detail/params.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_cta_bar.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_header_background_image.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_meeting_point_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_owner_lifecycle_bar.dart';
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

  Future<void> _shareEvent(BuildContext context) async {
    final encoded = Uri.encodeComponent(currentEvent.meetingPoint);
    final text = [
      currentEvent.name,
      currentEvent.city,
      '${context.l10n.event_meetingPointLabel}: ${currentEvent.meetingPoint}',
      '${context.l10n.event_viewMap}: https://www.google.com/maps/search/?api=1&query=$encoded',
    ].join('\n');
    await Clipboard.setData(ClipboardData(text: text));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.savedSuccessfully),
        backgroundColor: AppColors.success,
      ),
    );
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content:
                            Text(context.l10n.event_eventDeletedSuccess),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    context.pop(true);
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
                child: _HeroSection(
                  event: currentEvent,
                  isOwner: isOwner,
                  onBack: _pop,
                  onShare: () => unawaited(_shareEvent(context)),
                  onEdit: () => context
                      .pushNamed<EventModel?>(
                        AppRoutes.editEvent,
                        extra: currentEvent,
                      )
                      .then((result) {
                        if (result != null && mounted) {
                          setState(() => currentEvent = result);
                        }
                      }),
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
                      _EventHeaderSection(event: currentEvent),
                      const SizedBox(height: 24),

                      // Meta (difficulty + type + time)
                      _MetaSection(event: currentEvent),
                      const SizedBox(height: 24),

                      // About
                      _AboutSection(event: currentEvent),
                      const SizedBox(height: 24),

                      // Meeting point
                      EventDetailMeetingPointSection(
                        location: currentEvent.meetingPoint,
                        onViewMap: () => unawaited(
                          MapLauncherHelper.openSearchByAddress(
                            currentEvent.meetingPoint,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Allowed brands
                      if (currentEvent.allowedBrands.isNotEmpty) ...[
                        _AllowedBrandsSection(event: currentEvent),
                        const SizedBox(height: 24),
                      ],

                      // Participants
                      _ParticipantsSection(event: currentEvent),
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
                      currentEvent.state == EventState.inProgress
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
                          _showRegistrationOptions(context, reg);
                        } else if (reg.status ==
                            RegistrationStatus.readyForEdit) {
                          navigateToRegistration(context, reg);
                        }
                      },
                    ),
                    orElse: () => const SizedBox.shrink(),
                  );
                },
              ),
      ),
    );
  }

  Future<void> _showRegistrationOptions(
    BuildContext context,
    EventRegistrationModel registration,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                leading: const Icon(Icons.info_outline_rounded,
                    color: AppColors.textOnDarkPrimary),
                title: Text(
                  context.l10n.registration_viewDetail,
                  style: const TextStyle(color: AppColors.textOnDarkPrimary),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  context.pushNamed(
                    AppRoutes.registrationDetail,
                    extra: RegistrationDetailExtra(
                      registration: registration,
                      eventOwnerId: currentEvent.ownerId,
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined,
                    color: AppColors.error),
                title: Text(
                  context.l10n.event_cancelRegistration,
                  style: const TextStyle(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.of(sheetCtx).pop();
                  confirmCancelRegistration(context, registration);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Section widgets — private helpers
// ──────────────────────────────────────────────────────────────────────────────

/// Hero area: h=219 image + back button (top-left) + share button (top-right)
/// Optionally shows owner action menu.
class _HeroSection extends StatelessWidget {
  const _HeroSection({
    required this.event,
    required this.isOwner,
    required this.onBack,
    required this.onShare,
    required this.onEdit,
    required this.onAttendees,
    required this.onDelete,
  });

  final EventModel event;
  final bool isOwner;
  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onAttendees;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    return SizedBox(
      height: 219 + topPadding,
      child: Stack(
        fit: StackFit.expand,
        children: [
          EventDetailHeaderBackgroundImage(event: event),
          // Back button — top-left
          Positioned(
            top: topPadding + 16,
            left: 16,
            child: _CircleButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
            ),
          ),
          // Share / more actions — top-right
          Positioned(
            top: topPadding + 16,
            right: 16,
            child: Row(
              children: [
                _CircleButton(icon: Icons.share_outlined, onTap: onShare),
                if (isOwner) ...[
                  const SizedBox(width: 8),
                  _OwnerMenuButton(
                    onEdit: onEdit,
                    onAttendees: onAttendees,
                    onDelete: onDelete,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0x990D0D0F), // #0D0D0F with 60% opacity
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}

class _OwnerMenuButton extends StatelessWidget {
  const _OwnerMenuButton({
    required this.onEdit,
    required this.onAttendees,
    required this.onDelete,
  });

  final VoidCallback onEdit;
  final VoidCallback onAttendees;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: AppColors.darkCard,
      icon: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0x990D0D0F),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.more_vert, color: Colors.white, size: 20),
      ),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit();
          case 'attendees':
            onAttendees();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            const Icon(Icons.edit_outlined, color: AppColors.textOnDarkPrimary),
            const SizedBox(width: 12),
            Text(context.l10n.event_edit,
                style: const TextStyle(color: AppColors.textOnDarkPrimary)),
          ]),
        ),
        PopupMenuItem(
          value: 'attendees',
          child: Row(children: [
            const Icon(Icons.people_outline,
                color: AppColors.textOnDarkPrimary),
            const SizedBox(width: 12),
            Text(context.l10n.event_viewAttendees,
                style: const TextStyle(color: AppColors.textOnDarkPrimary)),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            const Icon(Icons.delete_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Text(context.l10n.event_delete,
                style: const TextStyle(color: AppColors.error)),
          ]),
        ),
      ],
    );
  }
}

/// Badge Row + event name + organizer row.
/// Matches Pencil "Event Header" block.
class _EventHeaderSection extends StatelessWidget {
  const _EventHeaderSection({required this.event});

  final EventModel event;

  String _badgeLabel(BuildContext context) {
    return switch (event.state) {
      EventState.scheduled => context.l10n.event_comingSoonPill,
      EventState.inProgress => context.l10n.event_eventLiveNow,
      EventState.finished => context.l10n.event_eventFinished.toUpperCase(),
      EventState.cancelled => event.state.label.toUpperCase(),
    };
  }

  Color _badgeColor() {
    return switch (event.state) {
      EventState.scheduled => AppColors.info,
      EventState.inProgress => AppColors.success,
      EventState.finished => AppColors.tabInactive,
      EventState.cancelled => AppColors.tabInactive,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 17),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge row: state badge + date pill
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _badgeColor(),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _badgeLabel(context),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _formatDate(event.startDate),
                  style: const TextStyle(
                    color: AppColors.textOnDarkSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Event name
          Text(
            event.name,
            style: const TextStyle(
              color: AppColors.textOnDarkPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),

          // Organizer row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.darkTertiary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_outline,
                        color: AppColors.textOnDarkSecondary, size: 16),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${context.l10n.event_organizedBy} ${context.l10n.event_organizerPlaceholder}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              // Small share/actions button
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.share_outlined,
                    color: AppColors.textOnDarkSecondary, size: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatDate(DateTime date) {
    const monthNames = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    return '${date.day} ${monthNames[date.month - 1]} ${date.year}';
  }
}

/// Difficulty pill + type pill + meeting time row.
/// Matches Pencil "Meta Section".
class _MetaSection extends StatelessWidget {
  const _MetaSection({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final difficulty = event.difficulty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Pills row
        Row(
          children: [
            // Difficulty pill
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded,
                      color: AppColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'X${difficulty.value}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text(
                    '·',
                    style: TextStyle(
                      color: AppColors.textOnDarkTertiary,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    difficulty.shortLabel,
                    style: const TextStyle(
                      color: AppColors.textOnDarkPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Type pill
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.explore_outlined,
                      color: AppColors.primary, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    event.eventType.label.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textOnDarkPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Meeting time row
        Row(
          children: [
            const Icon(Icons.timer_outlined, color: AppColors.primary, size: 16),
            const SizedBox(width: 8),
            Text(
              event.meetingTime.formattedTime,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// "Sobre la rodada" section with rich-text description.
class _AboutSection extends StatelessWidget {
  const _AboutSection({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.event_aboutTheRide,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        RichTextViewer(content: event.description),
      ],
    );
  }
}

/// "Marcas Permitidas" chips section.
class _AllowedBrandsSection extends StatelessWidget {
  const _AllowedBrandsSection({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    final labels = event.isMultiBrand || event.allowedBrands.isEmpty
        ? [context.l10n.event_allBrandsChip]
        : event.allowedBrands;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.event_allowedBrandsTitle,
          style: const TextStyle(
            color: AppColors.textOnDarkPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: labels
              .map(
                (label) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.textOnDarkPrimary,
                      fontSize: 13,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

/// "Inscritos" section showing count badge + view-all link.
class _ParticipantsSection extends StatelessWidget {
  const _ParticipantsSection({required this.event});

  final EventModel event;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.event_registrationsTab,
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.19),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                context.l10n.event_participants,
                style: const TextStyle(
                  color: AppColors.info,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // View all link
        GestureDetector(
          onTap: () {},
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                context.l10n.event_viewAttendees,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right,
                  color: AppColors.primary, size: 14),
            ],
          ),
        ),
      ],
    );
  }
}
