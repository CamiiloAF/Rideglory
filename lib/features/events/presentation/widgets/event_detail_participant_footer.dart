import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/registration_status.dart';

/// Footer de EV2 para un rider que no organiza la rodada: Inscribirme, o
/// la insignia "Inscrito" + Cancelar inscripción.
class EventDetailParticipantFooter extends StatelessWidget {
  const EventDetailParticipantFooter({
    required this.registrationStatus,
    required this.spotsLabel,
    required this.canRegister,
    required this.isBusy,
    required this.onRegister,
    required this.onCancelRegistration,
    super.key,
  });

  final RegistrationStatus? registrationStatus;
  final String spotsLabel;
  final bool canRegister;
  final bool isBusy;
  final VoidCallback onRegister;
  final VoidCallback onCancelRegistration;

  bool get _isActive =>
      registrationStatus == RegistrationStatus.approved ||
      registrationStatus == RegistrationStatus.pending;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return DecoratedBox(
      decoration: BoxDecoration(color: colors.bg),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_isActive) ...[
                Container(
                  height: 36,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.successSoft,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colors.success),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.check, size: 16, color: colors.success),
                      const SizedBox(width: 6),
                      Text(
                        context.l10n.events_detail_registered_badge,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: colors.success,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                spotsLabel,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              if (_isActive)
                AppSecondaryButton(
                  label: context.l10n.events_detail_cancel_registration_cta,
                  icon: LucideIcons.x,
                  destructive: true,
                  onPressed: isBusy ? null : onCancelRegistration,
                )
              else
                AppPrimaryButton(
                  label: context.l10n.events_detail_register_cta,
                  onPressed: (isBusy || !canRegister) ? null : onRegister,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
