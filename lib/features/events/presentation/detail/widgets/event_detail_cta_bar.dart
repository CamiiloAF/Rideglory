import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/presentation/detail/widgets/cta/event_detail_cta_bar_content.dart';

/// Bottom CTA bar for the Event Detail screen.
///
/// Handles all states from Pencil page 6 — CTA State Variants:
/// - DEFAULT: price left + "Inscribirme" button right
/// - PENDING: pending badge + message + "Cancelar" button
/// - APPROVED: green check + "Inscrito" label + "Cancelar inscripción" danger button
/// - REJECTED: rejected badge + explanation text
/// - CANCELLED event: cancelled badge + explanation text
/// - READY_FOR_EDIT: "Editar inscripción" outlined button
/// - EVENT LIVE (approved user): full-width "Seguir rodada en vivo" button
class EventDetailCTABar extends StatelessWidget {
  const EventDetailCTABar({
    super.key,
    required this.event,
    required this.registration,
    required this.onRegister,
    this.onRegistrationStatusTap,
    this.onFollowLive,
  });

  final EventModel event;
  final EventRegistrationModel? registration;
  final VoidCallback onRegister;
  final void Function(EventRegistrationModel)? onRegistrationStatusTap;
  final VoidCallback? onFollowLive;

  @override
  Widget build(BuildContext context) {
    // Owner check — owner should never see user CTA bar
    final currentUserId = context.watch<AuthCubit>().state.currentUser?.id;
    if (event.ownerId == currentUserId) return const SizedBox.shrink();

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.darkBgPrimary,
        border: Border(top: BorderSide(color: AppColors.darkBorderPrimary)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, max(16.0, bottomPadding)),
      child: EventDetailCtaBarContent(
        event: event,
        registration: registration,
        onRegister: onRegister,
        onRegistrationStatusTap: onRegistrationStatusTap,
        onFollowLive: onFollowLive,
      ),
    );
  }
}
