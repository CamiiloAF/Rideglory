import 'package:flutter/widgets.dart';

import '../../../../design_system/components/app_outlined_card.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/maintenance.dart';
import '../../domain/maintenance_history_entry.dart';
import 'maintenance_history_row.dart';
import 'maintenance_section_title.dart';

/// Historial agrupado por mes, más reciente primero, bajo un único
/// encabezado "HISTORIAL" (Pencil: `cusCF` + un `MaintenanceSectionTitle`
/// por mes).
class MaintenanceHistorySection extends StatelessWidget {
  const MaintenanceHistorySection({
    required this.groups,
    required this.onEntryTap,
    super.key,
  });

  final List<MaintenanceHistoryGroup> groups;
  final ValueChanged<Maintenance> onEntryTap;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        MaintenanceSectionTitle(context.l10n.maintenance_section_history),
        const SizedBox(height: 6),
        for (final group in groups) ...[
          MaintenanceSectionTitle(group.monthLabel),
          const SizedBox(height: 6),
          AppOutlinedCard(
            children: [
              for (final entry in group.entries)
                MaintenanceHistoryRow(
                  entry: entry,
                  onTap: () => onEntryTap(entry.maintenance),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}
