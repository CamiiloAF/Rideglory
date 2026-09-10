import 'package:flutter/material.dart';

import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Diálogo "¿Cerrar tu SOS?" antes de disparar `SosCubit.closeMine()`. El
/// SOS solo lo cierra la propia persona o el organizador (D19) — nunca una
/// desconexión ni el fin del evento, así que esta confirmación explícita
/// es obligatoria.
class SosCloseConfirmDialog extends StatelessWidget {
  const SosCloseConfirmDialog({super.key});

  static Future<bool> show(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const SosCloseConfirmDialog(),
    );
    return confirmed ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Dialog(
      backgroundColor: colors.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              context.l10n.sos_close_confirm_title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.sos_close_confirm_body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: context.l10n.sos_close_confirm_cta,
              destructive: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            AppSecondaryButton(
              label: context.l10n.sos_close_confirm_cancel,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
