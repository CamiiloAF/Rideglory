import 'package:flutter/widgets.dart';

import '../../../../core/utils/spanish_date_format.dart';
import '../../../../core/utils/thousands_input_formatter.dart';
import '../../../../design_system/components/record_row.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/maintenance_history_entry.dart';
import 'maintenance_type_labels.dart';

/// Una fila del historial: tipo, moto + taller (o fecha si no hay taller),
/// kilometraje, costo y cuánto duró el anterior del mismo tipo.
class MaintenanceHistoryRow extends StatelessWidget {
  const MaintenanceHistoryRow({required this.entry, this.onTap, super.key});

  final MaintenanceHistoryEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maintenance = entry.maintenance;
    final subtitle = maintenance.workshop?.trim().isNotEmpty == true
        ? '${maintenance.vehicleDisplayName} · ${maintenance.workshop}'
        : '${maintenance.vehicleDisplayName} · ${SpanishDateFormat.short(maintenance.serviceDate)}';

    return RecordRow(
      title: maintenance.type,
      subtitle: subtitle,
      primaryValue: l10n.maintenance_value_km(
        ThousandsInputFormatter.format(maintenance.odometer) ??
            '${maintenance.odometer}',
      ),
      secondaryValue: maintenance.cost != null
          ? ThousandsInputFormatter.formatCurrency(maintenance.cost!)
          : null,
      durationNote: entry.durationKm != null
          ? l10n.maintenance_detail_duration(
              ThousandsInputFormatter.format(entry.durationKm) ??
                  '${entry.durationKm}',
            )
          : null,
      icon: maintenanceTypeIcon(context, maintenance.type),
      onTap: onTap,
    );
  }
}
