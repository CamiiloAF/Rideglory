import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
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
import 'package:rideglory/features/events/presentation/detail/widgets/event_detail_info_section.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/event_registration_status_card.dart';
import 'package:rideglory/features/events/presentation/shared/dialogs/cancel_registration_dialog.dart';
import 'package:rideglory/shared/router/app_routes.dart';
import 'package:rideglory/shared/widgets/rich_text_viewer.dart';
import 'package:rideglory/shared/widgets/modals/app_dialog.dart';
import 'package:rideglory/shared/widgets/modals/confirmation_dialog.dart';
import 'package:rideglory/shared/widgets/modals/dialog_type.dart';

// TODO STRINGS and widgets
class EventDetailPage extends StatelessWidget {
  final EventDetailPageParams params;

  const EventDetailPage({super.key, required this.params});

  void _listener(BuildContext context, EventDetailState state) {
    state.registrationResult.whenOrNull(
      data: (registration) {
        if (params.onRegistrationChanged != null) {
          params.onRegistrationChanged!(registration!);
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
        extendBodyBehindAppBar: true,
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
                // ── Hero header (no AppBar) ───────────────────────
                _EventDetailHeader(
                  event: _currentEvent,
                  isOwner: isOwner,
                  onBack: () {
                    if (!widget.isFromEventDetailByIdPage) {
                      context.pop(_currentEvent);
                    } else {
                      context.pop();
                    }
                  },
                  onEdit: isOwner
                      ? () async {
                          final result = await context.pushNamed<EventModel?>(
                            AppRoutes.editEvent,
                            extra: _currentEvent,
                          );
                          if (result != null && mounted) {
                            setState(() => _currentEvent = result);
                          }
                        }
                      : null,
                  onAttendees: isOwner
                      ? () => context.pushNamed(
                          AppRoutes.eventAttendees,
                          extra: _currentEvent,
                        )
                      : null,
                  onDelete: isOwner ? () => _confirmDelete(context) : null,
                ),

                // ── Info sections ─────────────────────────────────
                EventDetailInfoSection(event: _currentEvent),

                // ── Registration card (registered non-owners) ─────
                if (!isOwner)
                  BlocBuilder<EventDetailCubit, EventDetailState>(
                    builder: (context, state) {
                      return state.registrationResult.maybeWhen(
                        data: (registration) {
                          if (registration == null) {
                            return const SizedBox.shrink();
                          }
                          return EventRegistrationStatusCard(
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
                            onViewRecommendations:
                                _currentEvent.recommendations != null
                                ? () => _showRecommendations(context)
                                : null,
                          );
                        },
                        orElse: () => const SizedBox.shrink(),
                      );
                    },
                  ),

                // ── Owner recommendations shortcut ────────────────
                if (isOwner && _currentEvent.recommendations != null) ...[
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton.icon(
                      onPressed: () => _showRecommendations(context),
                      icon: const Icon(Icons.tips_and_updates_outlined),
                      label: const Text(EventStrings.viewRecommendations),
                    ),
                  ),
                ],

                const SizedBox(height: 120),
              ],
            ),
          ),
        ),

        // ── Sticky CTA for non-owners ─────────────────────────────
        bottomNavigationBar: !isOwner
            ? BlocBuilder<EventDetailCubit, EventDetailState>(
                builder: (context, state) {
                  return state.registrationResult.maybeWhen(
                    data: (registration) => _EventCTABar(
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

  void _showRecommendations(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        expand: false,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                EventStrings.viewRecommendations,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Divider(),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  child: RichTextViewer(
                    content: _currentEvent.recommendations ?? '',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Hero header
// ─────────────────────────────────────────────────────────────────────────────

class _EventDetailHeader extends StatelessWidget {
  final EventModel event;
  final bool isOwner;
  final VoidCallback onBack;
  final VoidCallback? onEdit;
  final VoidCallback? onAttendees;
  final VoidCallback? onDelete;

  const _EventDetailHeader({
    required this.event,
    required this.isOwner,
    required this.onBack,
    this.onEdit,
    this.onAttendees,
    this.onDelete,
  });

  // Gradient color per event type
  Color _typeColor(EventType type) => switch (type) {
    EventType.offRoad => const Color(0xFF8B4513),
    EventType.onRoad => AppColors.primary,
    EventType.exhibition => const Color(0xFF7C3AED),
    EventType.charitable => const Color(0xFF0891B2),
  };

  String _badgeLabel() {
    final now = DateTime.now();
    if (event.startDate.isAfter(now)) return 'Próximo Evento';
    final end = event.endDate ?? event.startDate;
    if (event.startDate.isBefore(now) && end.isAfter(now)) return 'En curso';
    return event.eventType.label;
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = _typeColor(event.eventType);

    return SizedBox(
      height: 400,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background gradient ──────────────────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [typeColor.withOpacity(0.85), const Color(0xFF0D1117)],
              ),
            ),
          ),

          // ── Decorative motorcycle icon ───────────────────────
          Positioned(
            right: -24,
            top: 30,
            child: Opacity(
              opacity: 0.07,
              child: Icon(Icons.motorcycle, size: 260, color: Colors.white),
            ),
          ),

          // ── Bottom gradient overlay ──────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 220,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF0D1117)],
                ),
              ),
            ),
          ),

          // ── Content column ───────────────────────────────────
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      _OverlayButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onPressed: onBack,
                      ),
                      if (isOwner)
                        Row(
                          children: [
                            if (onAttendees != null)
                              _OverlayButton(
                                icon: Icons.people_outline,
                                onPressed: onAttendees!,
                              ),
                            if (onEdit != null)
                              _OverlayButton(
                                icon: Icons.edit_outlined,
                                onPressed: onEdit!,
                              ),
                            if (onDelete != null)
                              _OverlayButton(
                                icon: Icons.delete_outline,
                                onPressed: onDelete!,
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              // Bottom text overlay
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _badgeLabel().toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      event.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Price
                    Text(
                      event.isFree
                          ? 'Gratis'
                          : '\$${_formatPrice(event.price!)} COP',
                      style: TextStyle(
                        color: event.isFree
                            ? Colors.greenAccent
                            : AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatPrice(int price) {
    return NumberFormat('#,###', 'es').format(price);
  }
}

class _OverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _OverlayButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Material(
        color: Colors.black38,
        borderRadius: BorderRadius.circular(50),
        child: InkWell(
          borderRadius: BorderRadius.circular(50),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky CTA bar
// ─────────────────────────────────────────────────────────────────────────────

class _EventCTABar extends StatelessWidget {
  final EventModel event;
  final EventRegistrationModel? registration;
  final VoidCallback onRegister;

  const _EventCTABar({
    required this.event,
    required this.registration,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final bool notRegistered = registration == null;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, max(16.0, bottomPadding)),
      child: notRegistered
          ? SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: onRegister,
                icon: const Icon(Icons.how_to_reg_outlined),
                label: const Text(
                  'Inscribirse Ahora',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
              ),
            )
          : Container(
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: _statusColor(registration!.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _statusColor(registration!.status).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: _statusColor(registration!.status),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _statusLabel(registration!.status),
                    style: TextStyle(
                      color: _statusColor(registration!.status),
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Color _statusColor(RegistrationStatus status) => switch (status) {
    RegistrationStatus.pending => Colors.orange,
    RegistrationStatus.approved => Colors.green,
    RegistrationStatus.rejected => Colors.red,
    RegistrationStatus.cancelled => Colors.grey,
    RegistrationStatus.readyForEdit => Colors.blue,
  };

  String _statusLabel(RegistrationStatus status) => switch (status) {
    RegistrationStatus.pending => 'Inscripción pendiente',
    RegistrationStatus.approved => 'Inscripción aprobada',
    RegistrationStatus.rejected => 'Inscripción rechazada',
    RegistrationStatus.cancelled => 'Inscripción cancelada',
    RegistrationStatus.readyForEdit => 'Lista para editar',
  };
}
