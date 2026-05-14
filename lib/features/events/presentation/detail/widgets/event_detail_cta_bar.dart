import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';

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
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    // LIVE event + approved registration → full-width "Seguir rodada en vivo"
    final isLive = event.state == EventState.inProgress;
    if (isLive &&
        registration?.status == RegistrationStatus.approved &&
        onFollowLive != null) {
      return _LiveUserBar(onFollowLive: onFollowLive!);
    }

    // No registration → DEFAULT state
    if (registration == null) {
      return _DefaultBar(event: event, onRegister: onRegister);
    }

    // Registration exists → render state-specific bar
    return switch (registration!.status) {
      RegistrationStatus.pending => _PendingBar(
          registration: registration!,
          onCancel: onRegistrationStatusTap != null
              ? () => onRegistrationStatusTap!(registration!)
              : null,
        ),
      RegistrationStatus.approved => _ApprovedBar(
          registration: registration!,
          onCancel: onRegistrationStatusTap != null
              ? () => onRegistrationStatusTap!(registration!)
              : null,
        ),
      RegistrationStatus.rejected => const _RejectedBar(),
      RegistrationStatus.cancelled => const _CancelledEventBar(),
      RegistrationStatus.readyForEdit => _ReadyForEditBar(
          onEdit: onRegistrationStatusTap != null
              ? () => onRegistrationStatusTap!(registration!)
              : null,
        ),
    };
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// State-specific bar widgets
// ──────────────────────────────────────────────────────────────────────────────

/// DEFAULT: price label (left) + orange "Inscribirme" button (right).
class _DefaultBar extends StatelessWidget {
  const _DefaultBar({required this.event, required this.onRegister});

  final EventModel event;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Price column
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.event_totalParticipation,
              style: const TextStyle(
                color: AppColors.textOnDarkTertiary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              event.isFree
                  ? context.l10n.event_free
                  : '${(event.price ?? 0).toStringAsFixed(2)}€',
              style: const TextStyle(
                color: AppColors.textOnDarkPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),

        const SizedBox(width: 12),

        // Register button
        Expanded(
          child: GestureDetector(
            onTap: onRegister,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(25),
              ),
              alignment: Alignment.center,
              child: Text(
                context.l10n.event_registerMe,
                style: const TextStyle(
                  color: AppColors.darkBgPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// PENDING: yellow badge + "Tu solicitud está en revisión" + "Cancelar" button.
class _PendingBar extends StatelessWidget {
  const _PendingBar({required this.registration, this.onCancel});

  final EventRegistrationModel registration;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2A10),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined,
                  color: AppColors.warning, size: 14),
              const SizedBox(width: 6),
              Text(
                context.l10n.event_pendingBadgeSuffix,
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Message + cancel button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                context.l10n.event_requestUnderReview,
                style: const TextStyle(
                  color: AppColors.textOnDarkSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            if (onCancel != null) ...[
              const SizedBox(width: 12),
              GestureDetector(
                onTap: onCancel,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.darkBorderLight),
                  ),
                  child: Text(
                    context.l10n.cancel,
                    style: const TextStyle(
                      color: AppColors.textOnDarkSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// APPROVED: green check + "Inscrito" label on left + red "Cancelar inscripción" on right.
class _ApprovedBar extends StatelessWidget {
  const _ApprovedBar({required this.registration, this.onCancel});

  final EventRegistrationModel registration;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: icon + status text
        Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 24),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'TU ESTADO',
                  style: TextStyle(
                    color: AppColors.textOnDarkTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  registration.status.label,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),

        // Right: cancel button
        if (onCancel != null)
          GestureDetector(
            onTap: onCancel,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1F0F0F),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF5A1A1A)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close, color: AppColors.error, size: 13),
                  const SizedBox(width: 6),
                  Text(
                    context.l10n.event_cancelRegistration,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// REJECTED: red badge + explanation text.
class _RejectedBar extends StatelessWidget {
  const _RejectedBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.errorSubtle,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cancel_outlined,
                  color: AppColors.error, size: 14),
              const SizedBox(width: 6),
              Text(
                context.l10n.event_registrationRejected,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.event_rejectedMessage,
          style: const TextStyle(
            color: AppColors.textOnDarkSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// CANCELLED event state: grey badge + explanation.
class _CancelledEventBar extends StatelessWidget {
  const _CancelledEventBar();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.darkTertiary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.block_outlined,
                  color: AppColors.textOnDarkTertiary, size: 14),
              const SizedBox(width: 6),
              Text(
                context.l10n.event_eventCancelled,
                style: const TextStyle(
                  color: AppColors.textOnDarkTertiary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.event_cancelledMessage,
          style: const TextStyle(
            color: AppColors.textOnDarkSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

/// READY_FOR_EDIT: "Editar inscripción" outlined orange button.
class _ReadyForEditBar extends StatelessWidget {
  const _ReadyForEditBar({this.onEdit});

  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onEdit,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.primary, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.edit_outlined, color: AppColors.primary, size: 14),
            const SizedBox(width: 8),
            Text(
              context.l10n.event_editRegistration,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// LIVE + APPROVED USER: full-width orange "Seguir rodada en vivo" button.
class _LiveUserBar extends StatelessWidget {
  const _LiveUserBar({required this.onFollowLive});

  final VoidCallback onFollowLive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onFollowLive,
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.navigation_rounded,
                color: AppColors.darkBgPrimary, size: 18),
            const SizedBox(width: 10),
            Text(
              context.l10n.event_followRideLive,
              style: const TextStyle(
                color: AppColors.darkBgPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
