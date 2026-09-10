import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_status_chip.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Icono + título + cuerpo + chip de LV4a (pendiente) o LV4b (confirmado).
/// **`pending` nunca dice "enviado"**: dice que no salió y que se está
/// reintentando (regla de seguridad del rider).
class SosActiveStatusHeader extends StatelessWidget {
  const SosActiveStatusHeader({required this.isConfirmed, super.key});

  final bool isConfirmed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    final iconBackground = isConfirmed
        ? colors.successSoft
        : colors.warningSoft;
    final iconColor = isConfirmed ? colors.success : colors.warning;
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: iconBackground,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            isConfirmed ? LucideIcons.checkCircle2 : LucideIcons.cloudOff,
            size: 26,
            color: iconColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          isConfirmed
              ? context.l10n.sos_confirmed_title
              : context.l10n.sos_pending_title,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          isConfirmed
              ? context.l10n.sos_confirmed_body
              : context.l10n.sos_pending_body,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13.5,
            height: 1.4,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 10),
        AppStatusChip(
          icon: isConfirmed ? LucideIcons.check : LucideIcons.clock,
          label: isConfirmed
              ? context.l10n.sos_confirmed_chip
              : context.l10n.sos_pending_chip,
          tone: isConfirmed ? AppStatusTone.success : AppStatusTone.warning,
        ),
      ],
    );
  }
}
