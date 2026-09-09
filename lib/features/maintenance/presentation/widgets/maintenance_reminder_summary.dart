import 'package:flutter/widgets.dart';

import '../../../../core/utils/thousands_input_formatter.dart';
import '../../../../l10n/l10n_extensions.dart';
import '../../domain/maintenance_reminder.dart';

/// Texto "Cada 7.500 km o 12 meses" (o solo uno de los dos) para el
/// resumen del recordatorio.
String maintenanceReminderSummary(
  BuildContext context,
  MaintenanceReminder reminder,
) {
  final l10n = context.l10n;
  final km = reminder.everyKm;
  final months = reminder.everyMonths;
  if (km != null && months != null) {
    return l10n.maintenance_reminder_both(
      ThousandsInputFormatter.format(km) ?? '$km',
      '$months',
    );
  }
  if (km != null) {
    return l10n.maintenance_reminder_km_only(
      ThousandsInputFormatter.format(km) ?? '$km',
    );
  }
  if (months != null) {
    return l10n.maintenance_reminder_months_only('$months');
  }
  return '';
}
