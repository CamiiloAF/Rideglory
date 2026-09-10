import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/event.dart';
import '../../domain/event_route_change.dart';
import '../../domain/event_state.dart';
import '../cubit/event_detail_cubit.dart';
import 'event_confirm_sheet.dart';
import 'event_detail_body.dart';
import 'event_detail_organizer_footer.dart';
import 'event_detail_participant_footer.dart';
import 'event_route_change_sheet.dart';

/// Estructura completa del detalle una vez cargado: cuerpo scrolleable +
/// footer de acciones según el rol de quien mira.
class EventDetailScaffold extends StatelessWidget {
  const EventDetailScaffold({
    required this.event,
    required this.routeChanges,
    required this.isBusy,
    required this.cubit,
    super.key,
  });

  final Event event;
  final List<EventRouteChange> routeChanges;
  final bool isBusy;
  final EventDetailCubit cubit;

  @override
  Widget build(BuildContext context) {
    final spotsLabel = event.maxParticipants == null
        ? context.l10n.events_detail_spots_unlimited(event.approvedCount)
        : context.l10n.events_detail_spots(
            event.approvedCount,
            event.maxParticipants!,
          );
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: EventDetailBody(
              event: event,
              routeChanges: routeChanges,
              showSpotsUnderOrganizer: event.isOwnedByMe,
              spotsLabel: spotsLabel,
              meetingPointLabel: context.l10n.events_detail_meeting_point(
                event.meetingPoint ?? '',
              ),
              bottomPadding: event.isOwnedByMe ? 210 : 140,
            ),
          ),
          if (event.isOwnedByMe)
            EventDetailOrganizerFooter(
              canStart: event.state == EventState.published,
              isBusy: isBusy,
              onStart: cubit.startEvent,
              onChangeRoute: () => _openChangeRoute(context, cubit, event),
              onViewRegistrants: () => context.pushNamed(
                AppRoutes.eventRegistrants,
                pathParameters: {'id': event.id},
                extra: event.maxParticipants,
              ),
              onCancelEvent: () => _confirmCancelEvent(context, cubit),
            )
          else
            EventDetailParticipantFooter(
              registrationStatus: event.myRegistrationStatus,
              spotsLabel: spotsLabel,
              canRegister: event.state == EventState.published,
              isBusy: isBusy,
              onRegister: () => context.pushNamed(
                AppRoutes.eventRegistration,
                pathParameters: {'id': event.id},
              ),
              onCancelRegistration: () =>
                  _confirmCancelRegistration(context, cubit),
            ),
        ],
      ),
    );
  }

  Future<void> _openChangeRoute(
    BuildContext context,
    EventDetailCubit cubit,
    Event event,
  ) async {
    final message = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (_) => EventRouteChangeSheet(approvedCount: event.approvedCount),
    );
    if (message != null && message.isNotEmpty) {
      await cubit.changeRoute(message);
    }
  }

  Future<void> _confirmCancelEvent(
    BuildContext context,
    EventDetailCubit cubit,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => EventConfirmSheet(
        title: context.l10n.events_detail_cancel_event_confirm_title,
        body: context.l10n.events_detail_cancel_event_confirm_body,
        confirmLabel: context.l10n.events_detail_cancel_event_confirm_cta,
        onConfirm: () {
          Navigator.of(sheetContext).pop();
          cubit.cancelEvent();
        },
      ),
    );
  }

  Future<void> _confirmCancelRegistration(
    BuildContext context,
    EventDetailCubit cubit,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => EventConfirmSheet(
        title: context.l10n.events_detail_cancel_registration_confirm_title,
        body: context.l10n.events_detail_cancel_registration_confirm_body,
        confirmLabel: context.l10n.events_detail_cancel_registration_cta,
        onConfirm: () {
          Navigator.of(sheetContext).pop();
          cubit.cancelMyRegistration();
        },
      ),
    );
  }
}
