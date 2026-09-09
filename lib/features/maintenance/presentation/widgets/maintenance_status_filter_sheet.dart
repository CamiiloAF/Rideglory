import 'package:flutter/material.dart';

import '../../../../design_system/components/suggestion_chip.dart';
import '../../../../design_system/tokens/app_colors.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/maintenance_agenda_item.dart';

/// Hoja para filtrar la agenda por estado (Todos/Vencidos/Este mes/Al día).
/// No hay un frame propio en el `.pen` para esta hoja; se construyó con
/// los componentes ya aprobados (`SuggestionChip`) siguiendo el mismo
/// lenguaje visual de las demás hojas de la app.
class MaintenanceStatusFilterSheet extends StatelessWidget {
  const MaintenanceStatusFilterSheet({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final MaintenanceUrgency? selected;
  final ValueChanged<MaintenanceUrgency?> onSelected;

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
            Text(
              l10n.maintenance_filter_sheet_title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SuggestionChip(
                  label: l10n.maintenance_filter_status_all,
                  selected: selected == null,
                  onTap: () => onSelected(null),
                ),
                SuggestionChip(
                  label: l10n.maintenance_filter_status_overdue,
                  selected: selected == MaintenanceUrgency.overdue,
                  onTap: () => onSelected(MaintenanceUrgency.overdue),
                ),
                SuggestionChip(
                  label: l10n.maintenance_filter_status_due_soon,
                  selected: selected == MaintenanceUrgency.dueSoon,
                  onTap: () => onSelected(MaintenanceUrgency.dueSoon),
                ),
                SuggestionChip(
                  label: l10n.maintenance_filter_status_upcoming,
                  selected: selected == MaintenanceUrgency.upcoming,
                  onTap: () => onSelected(MaintenanceUrgency.upcoming),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
