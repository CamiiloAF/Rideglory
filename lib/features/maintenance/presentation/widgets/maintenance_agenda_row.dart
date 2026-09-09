import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../design_system/components/app_status_chip.dart';
import '../../../../design_system/components/record_row.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/maintenance_agenda_item.dart';
import 'maintenance_type_labels.dart';

/// Una fila de la sección "PRÓXIMOS": tipo, moto + urgencia como texto, y
/// cuánto falta (o se pasó) en km o días. El ícono cambia a alerta cuando
/// está vencido, sin importar el tipo (regla de contexto moto: legible en
/// menos de 2s, no solo por color).
class MaintenanceAgendaRow extends StatelessWidget {
  const MaintenanceAgendaRow({required this.item, this.onTap, super.key});

  final MaintenanceAgendaItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final urgencyLabel = switch (item.urgency) {
      MaintenanceUrgency.overdue => l10n.maintenance_urgency_overdue,
      MaintenanceUrgency.dueSoon => l10n.maintenance_urgency_due_soon,
      MaintenanceUrgency.upcoming => l10n.maintenance_urgency_upcoming,
    };
    final valueLabel = item.metric == MaintenanceAgendaMetric.kilometers
        ? l10n.maintenance_value_km('${item.value}')
        : l10n.maintenance_value_days('${item.value}');
    final tone = switch (item.urgency) {
      MaintenanceUrgency.overdue => AppStatusTone.error,
      MaintenanceUrgency.dueSoon => AppStatusTone.warning,
      MaintenanceUrgency.upcoming => null,
    };
    final icon = item.urgency == MaintenanceUrgency.overdue
        ? LucideIcons.alertTriangle
        : maintenanceTypeIcon(context, item.type);

    return RecordRow(
      title: item.type,
      subtitle: '${item.vehicleDisplayName} · $urgencyLabel',
      primaryValue: valueLabel,
      icon: icon,
      tone: tone,
      onTap: onTap,
    );
  }
}
