import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';

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
    final currentUserId = context.watch<AuthCubit>().state.currentUser?.id;
    if (event.ownerId == currentUserId) {
      return const SizedBox.shrink();
    }

    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final notRegistered = registration == null;

    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        border: Border(
          top: BorderSide(color: context.colorScheme.outlineVariant),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, max(16.0, bottomPadding)),
      child: notRegistered
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.event_totalParticipation,
                        style: TextStyle(
                          color: context.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                      AppSpacing.gapXxs,
                      Text(
                        event.isFree
                            ? context.l10n.event_free
                            : '${(event.price ?? 0).toStringAsFixed(2)}€',
                        style: TextStyle(
                          color: context.colorScheme.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                AppSpacing.hGapLg,
                Expanded(
                  flex: 2,
                  child: AppButton(
                    label: context.l10n.event_registerMe,
                    isFullWidth: true,
                    onPressed: onRegister,
                  ),
                ),
              ],
            )
          : _buildRegisteredContent(context, registration!),
    );
  }

  Widget _buildRegisteredContent(
    BuildContext context,
    EventRegistrationModel registration,
  ) {
    final shouldShowFollowLive =
        event.state == EventState.inProgress &&
        registration.status == RegistrationStatus.approved &&
        onFollowLive != null;
    if (shouldShowFollowLive) {
      return AppButton(
        label: context.l10n.event_followRideLive,
        isFullWidth: true,
        onPressed: onFollowLive,
      );
    }

    final badge = _RegistrationStatusBadge(registration: registration);
    final isTappable = onRegistrationStatusTap != null &&
        (registration.status == RegistrationStatus.pending ||
            registration.status == RegistrationStatus.approved ||
            registration.status == RegistrationStatus.readyForEdit);
    if (isTappable) {
      return InkWell(
        onTap: () => onRegistrationStatusTap!(registration),
        borderRadius: BorderRadius.circular(8),
        child: badge,
      );
    }
    return badge;
  }
}

class _RegistrationStatusBadge extends StatelessWidget {
  const _RegistrationStatusBadge({required this.registration});

  final EventRegistrationModel registration;

  Color get _color => switch (registration.status) {
    RegistrationStatus.pending => AppColors.warning,
    RegistrationStatus.approved => AppColors.success,
    RegistrationStatus.rejected => AppColors.error,
    RegistrationStatus.cancelled => AppColors.darkTextSecondary,
    RegistrationStatus.readyForEdit => AppColors.info,
  };

  String get _label => switch (registration.status) {
    RegistrationStatus.pending => 'Inscripción pendiente',
    RegistrationStatus.approved => 'Inscripción aprobada',
    RegistrationStatus.rejected => 'Inscripción rechazada',
    RegistrationStatus.cancelled => 'Inscripción cancelada',
    RegistrationStatus.readyForEdit => 'Lista para editar',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: _color, size: 20),
          AppSpacing.hGapSm,
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
