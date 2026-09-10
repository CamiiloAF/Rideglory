import 'package:flutter/material.dart';

import '../../../../design_system/components/app_secondary_button.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import 'sos_hold_button.dart';

/// LV3: hoja de confirmación del SOS. `onConfirmed` dispara
/// `SosCubit.raise()` desde quien la abre — esta hoja solo conoce el
/// gesto, no el envío.
///
/// Pencil: k4dms
class SosConfirmSheet extends StatelessWidget {
  const SosConfirmSheet({required this.onConfirmed, super.key});

  final VoidCallback onConfirmed;

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onConfirmed,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SosConfirmSheet(onConfirmed: onConfirmed),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.sos_confirm_title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.sos_confirm_body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.4,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            SosHoldButton(
              onConfirmed: () {
                Navigator.of(context).pop();
                onConfirmed();
              },
            ),
            const SizedBox(height: 18),
            AppSecondaryButton(
              label: context.l10n.sos_confirm_cancel_cta,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}
