import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/presentation/registration_detail_extra.dart';
import 'package:rideglory/shared/helpers/url_launcher_helper.dart';

/// Acciones de contacto (Llamar / WhatsApp) que el organizador ve en el detalle
/// de una inscripción cuando el piloto autorizó el contacto directo. Se oculta
/// para la vista del piloto o cuando el contacto no fue autorizado.
class RegistrationContactActions extends StatelessWidget {
  const RegistrationContactActions({super.key, required this.extra});

  final RegistrationDetailExtra extra;

  @override
  Widget build(BuildContext context) {
    if (!extra.isOrganizerView) return const SizedBox.shrink();
    if (!extra.registration.allowOrganizerContact) {
      return const SizedBox.shrink();
    }

    final phone = extra.registration.phone;

    return Row(
      children: [
        Expanded(
          child: AppButton(
            label: context.l10n.registration_callButton,
            icon: Icons.call_rounded,
            variant: AppButtonVariant.ghost,
            style: AppButtonStyle.outlined,
            onPressed: () => UrlLauncherHelper.openPhone(phone),
            isFullWidth: true,
          ),
        ),
        AppSpacing.hGapMd,
        Expanded(
          child: AppButton(
            label: context.l10n.registration_whatsappButton,
            icon: Icons.chat_rounded,
            variant: AppButtonVariant.ghost,
            style: AppButtonStyle.outlined,
            onPressed: () => UrlLauncherHelper.openWhatsApp(phone),
            isFullWidth: true,
          ),
        ),
      ],
    );
  }
}
