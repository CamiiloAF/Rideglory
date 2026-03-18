import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
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
  });

  final EventModel event;
  final EventRegistrationModel? registration;
  final VoidCallback onRegister;
  final void Function(EventRegistrationModel)? onRegistrationStatusTap;

  @override
  Widget build(BuildContext context) {
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
                      SizedBox(height: 2),
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
                SizedBox(width: 16),
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
          : _buildRegisteredContent(registration!),
    );
  }

  Widget _buildRegisteredContent(EventRegistrationModel registration) {
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
    RegistrationStatus.pending => Colors.orange,
    RegistrationStatus.approved => Colors.green,
    RegistrationStatus.rejected => Colors.red,
    RegistrationStatus.cancelled => Colors.grey,
    RegistrationStatus.readyForEdit => Colors.blue,
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
          SizedBox(width: 8),
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
