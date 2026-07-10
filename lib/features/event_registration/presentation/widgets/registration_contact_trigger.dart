import 'package:flutter/material.dart';
import 'package:rideglory/core/extensions/l10n_extensions.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/presentation/widgets/registration_contact_sheet.dart';
import 'package:rideglory/shared/helpers/url_launcher_helper.dart';

/// Disparador de contacto que el organizador ve en el encabezado de la tarjeta
/// "Datos Personales" cuando el piloto autorizó el contacto directo. Al tocarlo
/// abre [RegistrationContactSheet] con las opciones Llamar / WhatsApp. Se oculta
/// para la vista del piloto o cuando el contacto no fue autorizado.
class RegistrationContactTrigger extends StatelessWidget {
  const RegistrationContactTrigger({
    super.key,
    required this.registration,
    required this.isOrganizerView,
  });

  final EventRegistrationModel registration;
  final bool isOrganizerView;

  @override
  Widget build(BuildContext context) {
    if (!isOrganizerView || !registration.allowOrganizerContact) {
      return const SizedBox.shrink();
    }

    return Semantics(
      button: true,
      label: context.l10n.registration_contactLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openSheet(context),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primarySubtle,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.call_rounded, color: AppColors.primary, size: 16),
                SizedBox(width: 4),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Abre el sheet de opciones y, según el método elegido, lanza el intento de
  /// abrir la app externa. Si ninguna app puede manejar el enlace, muestra un
  /// SnackBar en vez de fallar en silencio. El [ScaffoldMessenger] y el l10n se
  /// capturan antes del primer `await` para no usar el `context` tras cerrarse
  /// el sheet.
  Future<void> _openSheet(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;

    final method = await RegistrationContactSheet.show(
      context: context,
      contactName: registration.fullName,
    );
    if (method == null) return;

    final phone = registration.phone;
    if (phone == null) return;
    final (future, failureMessage) = switch (method) {
      RegistrationContactMethod.call => (
        UrlLauncherHelper.openPhone(phone),
        l10n.registration_couldNotOpenPhone,
      ),
      RegistrationContactMethod.whatsapp => (
        UrlLauncherHelper.openWhatsApp(phone),
        l10n.registration_couldNotOpenWhatsApp,
      ),
    };

    final launched = await future;
    if (launched) return;
    messenger.showSnackBar(SnackBar(content: Text(failureMessage)));
  }
}
