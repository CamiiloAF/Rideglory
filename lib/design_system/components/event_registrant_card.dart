import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../tokens/app_colors.dart';
import '../tokens/app_radii.dart';
import 'internal/registrant_call_button.dart';

/// Tarjeta de un inscrito para el organizador (EV5): nombre + moto/tipo de
/// sangre, y los dos botones de llamada (≥56dp, contexto moto).
/// [onCallEmergencyContact] es `null` cuando el rider no permitió el
/// contacto de emergencia visible, no cuando el desarrollador olvidó
/// pasarlo. Las etiquetas se pasan desde afuera: este componente no
/// resuelve `l10n`.
///
/// Pencil: ZiSuN
class EventRegistrantCard extends StatelessWidget {
  const EventRegistrantCard({
    required this.name,
    required this.subtitle,
    required this.callLabel,
    required this.emergencyContactLabel,
    this.onCall,
    this.onCallEmergencyContact,
    super.key,
  });

  final String name;
  final String subtitle;
  final String callLabel;
  final String emergencyContactLabel;
  final VoidCallback? onCall;
  final VoidCallback? onCallEmergencyContact;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.md),
        border: Border.all(color: colors.borderStrong),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colors.block,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(LucideIcons.user, size: 20, color: colors.onBlock),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: RegistrantCallButton(
                  label: callLabel,
                  icon: LucideIcons.phone,
                  background: colors.accent,
                  foreground: colors.onAccent,
                  borderColor: null,
                  onPressed: onCall,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: RegistrantCallButton(
                  label: emergencyContactLabel,
                  icon: LucideIcons.siren,
                  background: colors.surface,
                  foreground: colors.errorText,
                  borderColor: colors.errorText,
                  onPressed: onCallEmergencyContact,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
