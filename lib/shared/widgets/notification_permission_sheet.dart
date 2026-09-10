import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../design_system/components/app_primary_button.dart';
import '../../design_system/components/app_secondary_button.dart';
import '../../design_system/tokens/app_colors.dart';
import '../../l10n/l10n_extensions.dart';

/// Aviso propio antes del diálogo del sistema de permiso de notificaciones
/// (regla de producto D6): explica en español por qué se necesita el
/// permiso, y solo si el rider toca "Permitir" se dispara el diálogo nativo.
/// Único punto de entrada de este flujo — úsalo desde documentos y
/// mantenimiento en vez de pedir el permiso directo.
class NotificationPermissionSheet extends StatelessWidget {
  const NotificationPermissionSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final l10n = context.l10n;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.accentSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(LucideIcons.bell, size: 24, color: colors.accentText),
            ),
            const SizedBox(height: 14),
            Text(
              l10n.notification_permission_sheet_title,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.notification_permission_sheet_body,
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: l10n.notification_permission_sheet_allow,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            AppSecondaryButton(
              label: l10n.notification_permission_sheet_cancel,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Muestra el aviso propio y, solo si el rider toca "Permitir", llama a
/// [requestSystemPermission] (el diálogo nativo). Devuelve `true` solo
/// cuando el permiso terminó concedido.
Future<bool> requestNotificationPermissionWithConsent(
  BuildContext context, {
  required Future<bool> Function() requestSystemPermission,
}) async {
  final consented = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const NotificationPermissionSheet(),
  );
  if (consented != true || !context.mounted) return false;
  return requestSystemPermission();
}
