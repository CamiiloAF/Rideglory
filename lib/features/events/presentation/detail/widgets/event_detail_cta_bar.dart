import 'dart:math' show max;

import 'package:flutter/material.dart';
import 'package:rideglory/core/theme/app_colors.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/shared/widgets/form/app_button.dart';

class EventDetailCTABar extends StatelessWidget {
  const EventDetailCTABar({
    super.key,
    required this.event,
    required this.registration,
    required this.onRegister,
  });

  final EventModel event;
  final EventRegistrationModel? registration;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final notRegistered = registration == null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
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
          ? AppButton(
              label: 'Inscribirse ahora',
              icon: Icons.how_to_reg_outlined,
              isFullWidth: true,
              onPressed: onRegister,
            )
          : _RegistrationStatusBadge(registration: registration!),
    );
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
          const SizedBox(width: 8),
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
