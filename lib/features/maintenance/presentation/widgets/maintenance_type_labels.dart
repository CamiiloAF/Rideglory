import 'package:flutter/widgets.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../l10n/l10n_extensions.dart';
import '../../domain/maintenance_type_suggestion.dart';

/// Etiqueta en español de una sugerencia de tipo de mantenimiento. El valor
/// que se guarda en la base es justo este texto (la app solo tiene locale
/// `es`, así que no hace falta un id separado del texto mostrado).
String maintenanceTypeSuggestionLabel(
  BuildContext context,
  MaintenanceTypeSuggestion suggestion,
) {
  final l10n = context.l10n;
  return switch (suggestion) {
    MaintenanceTypeSuggestion.oilChange => l10n.maintenance_type_oil_change,
    MaintenanceTypeSuggestion.tireChange => l10n.maintenance_type_tire_change,
    MaintenanceTypeSuggestion.brakePads => l10n.maintenance_type_brake_pads,
    MaintenanceTypeSuggestion.driveKit => l10n.maintenance_type_drive_kit,
    MaintenanceTypeSuggestion.generalCheck =>
      l10n.maintenance_type_general_check,
    MaintenanceTypeSuggestion.other => l10n.maintenance_type_other,
  };
}

IconData maintenanceTypeSuggestionIcon(MaintenanceTypeSuggestion suggestion) {
  return switch (suggestion) {
    MaintenanceTypeSuggestion.oilChange => LucideIcons.droplet,
    MaintenanceTypeSuggestion.tireChange => LucideIcons.circleDot,
    MaintenanceTypeSuggestion.brakePads => LucideIcons.disc,
    MaintenanceTypeSuggestion.driveKit => LucideIcons.link,
    MaintenanceTypeSuggestion.generalCheck => LucideIcons.wrench,
    MaintenanceTypeSuggestion.other => LucideIcons.plus,
  };
}

/// Ícono para una fila de agenda/historial a partir del texto libre del
/// tipo: si coincide con una sugerencia conocida usa su ícono, si no,
/// llave inglesa genérica.
IconData maintenanceTypeIcon(BuildContext context, String type) {
  for (final suggestion in MaintenanceTypeSuggestion.orderedChoices) {
    if (suggestion == MaintenanceTypeSuggestion.other) continue;
    if (maintenanceTypeSuggestionLabel(context, suggestion) == type) {
      return maintenanceTypeSuggestionIcon(suggestion);
    }
  }
  return LucideIcons.wrench;
}
