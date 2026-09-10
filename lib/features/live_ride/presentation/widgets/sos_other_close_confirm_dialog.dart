import 'package:flutter/material.dart';

import '../../../../design_system/components/app_primary_button.dart';
import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// LV5c: confirmación del organizador antes de `SosCubit.closeOther`.
/// D19: solo el organizador o quien lanzó el SOS pueden cerrarlo, y nunca
/// sin esta confirmación explícita.
class SosOtherCloseConfirmDialog extends StatelessWidget {
  const SosOtherCloseConfirmDialog({required this.riderName, super.key});

  final String riderName;

  static Future<bool> show(
    BuildContext context, {
    required String riderName,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => SosOtherCloseConfirmDialog(riderName: riderName),
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
              context.l10n.sos_other_close_confirm_title(riderName),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.sos_other_close_confirm_body(riderName),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            AppPrimaryButton(
              label: context.l10n.sos_other_close_confirm_cta,
              destructive: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
            const SizedBox(height: 10),
            AppSecondaryButton(
              label: context.l10n.sos_other_close_confirm_cancel,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ],
        ),
      ),
    );
  }
}
