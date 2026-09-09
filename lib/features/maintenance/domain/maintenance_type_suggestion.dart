/// Catálogo fijo de sugerencias del paso 1 de registro (Pencil `Yhgp2`).
/// El texto visible y el ícono viven en presentación (`l10n` + `lucide`);
/// aquí solo el identificador puro.
enum MaintenanceTypeSuggestion {
  oilChange,
  tireChange,
  brakePads,
  driveKit,
  generalCheck,
  other;

  static const List<MaintenanceTypeSuggestion> orderedChoices = [
    oilChange,
    tireChange,
    brakePads,
    driveKit,
    generalCheck,
    other,
  ];
}
