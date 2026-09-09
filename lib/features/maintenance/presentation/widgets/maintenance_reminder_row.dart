import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_switch.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radii.dart';

/// Fila de recordatorio: ícono, label + subtítulo, y opcionalmente un
/// switch y/o chevron. Es una variación de `SettingsRow` (Pencil `jCMG0`)
/// que combina switch + chevron a la vez, algo que `SettingsRow` no
/// soporta hoy — se resolvió como widget propio de esta feature en vez de
/// tocar un componente compartido para un caso que solo aquí aplica.
///
/// Pencil: `jCMG0` (usado como "Fila recordatorio" / "Ajuste avisar").
class MaintenanceReminderRow extends StatelessWidget {
  const MaintenanceReminderRow({
    required this.label,
    required this.subtitle,
    this.switchValue,
    this.onSwitchChanged,
    this.showChevron = false,
    this.onTap,
    super.key,
  });

  final String label;
  final String subtitle;

  /// `null` = no mostrar switch.
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final bool showChevron;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.md),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadii.md),
        ),
        child: Row(
          children: [
            Icon(LucideIcons.bell, size: 20, color: colors.text),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.text,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (switchValue != null) ...[
              const SizedBox(width: 8),
              AppSwitch(value: switchValue!, onChanged: onSwitchChanged),
            ],
            if (showChevron) ...[
              const SizedBox(width: 8),
              Icon(
                LucideIcons.chevronRight,
                size: 18,
                color: colors.textSecondary,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
