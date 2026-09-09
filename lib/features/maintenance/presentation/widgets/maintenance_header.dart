import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/tokens/app_colors.dart';
import '../../../../design_system/tokens/app_radii.dart';
import '../../../../l10n/l10n_extensions.dart';

/// Encabezado de la pantalla principal: título grande y el botón de
/// filtro por estado, tal como en los tabs raíz de la app.
///
/// Pencil: `ViTPl` (dentro de `V3B6C`).
class MaintenanceHeader extends StatelessWidget {
  const MaintenanceHeader({required this.onFilterTap, super.key});

  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            context.l10n.maintenance_page_title,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: colors.text,
            ),
          ),
          Semantics(
            button: true,
            label: context.l10n.maintenance_filter_action_label,
            child: InkWell(
              onTap: onFilterTap,
              borderRadius: BorderRadius.circular(AppRadii.sm),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: Border.all(color: colors.borderStrong),
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.slidersHorizontal,
                  size: 20,
                  color: colors.text,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
