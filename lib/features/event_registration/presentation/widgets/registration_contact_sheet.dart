import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_contact_option_tile.dart';

/// Método de contacto elegido por el organizador en [RegistrationContactSheet].
enum RegistrationContactMethod { call, whatsapp }

/// Bottom sheet con las opciones de contacto (Llamar / WhatsApp) para el
/// organizador. Solo presenta las opciones: al tocar una, cierra el sheet
/// devolviendo el método elegido; el caller ([RegistrationContactTrigger])
/// ejecuta el intento de abrir la app externa y su feedback de error.
class RegistrationContactSheet extends StatelessWidget {
  const RegistrationContactSheet({super.key, required this.contactName});

  final String contactName;

  /// Verde de marca de WhatsApp (no vive en el tema porque es un color de marca
  /// externa, no una semántica de la app).
  static const Color _whatsappColor = Color(0xFF25D366);
  static const Color _whatsappSubtle = Color(0x1A25D366);

  /// Presenta el sheet y devuelve el método elegido, o `null` si se descartó.
  static Future<RegistrationContactMethod?> show({
    required BuildContext context,
    required String contactName,
  }) {
    return showModalBottomSheet<RegistrationContactMethod>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.darkBgPrimary.withValues(alpha: 0.82),
      builder: (_) => RegistrationContactSheet(contactName: contactName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.darkBorderPrimary)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 8),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkBorderPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.l10n.registration_contactSheetTitle(contactName),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textOnDarkPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  AppSpacing.gapLg,
                  RegistrationContactOptionTile(
                    icon: Icons.call_rounded,
                    iconColor: AppColors.primary,
                    iconBackgroundColor: AppColors.primarySubtle,
                    title: context.l10n.registration_callButton,
                    subtitle: context.l10n.registration_callOptionSubtitle,
                    onTap: () => Navigator.of(
                      context,
                    ).pop(RegistrationContactMethod.call),
                  ),
                  AppSpacing.gapMd,
                  RegistrationContactOptionTile(
                    icon: Icons.chat_rounded,
                    iconColor: _whatsappColor,
                    iconBackgroundColor: _whatsappSubtle,
                    title: context.l10n.registration_whatsappButton,
                    subtitle: context.l10n.registration_whatsappOptionSubtitle,
                    onTap: () => Navigator.of(
                      context,
                    ).pop(RegistrationContactMethod.whatsapp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
