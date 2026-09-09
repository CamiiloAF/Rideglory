/// Per-insurer rules for the SOAT parser.
///
/// The catalog covers the 10 insurers authorized by the Colombian
/// Superfinanciera (Fasecolda, 2026). The five with the largest market share
/// (SURA, Bolívar, Estado, AXA Colpatria, Mundial) carry a specific policy
/// number regex; the rest rely on the generic pattern.
class SoatInsurerRule {
  const SoatInsurerRule({
    required this.canonicalName,
    required this.aliases,
    this.policyNumberPattern,
  });

  /// Display name persisted to the model.
  final String canonicalName;

  /// Lowercase, accent-normalized substrings that identify the insurer in the
  /// recognized text.
  final List<String> aliases;

  /// Optional insurer-specific policy number regex. When null, the generic
  /// pattern is used.
  final RegExp? policyNumberPattern;
}

/// Closed catalog of authorized SOAT insurers.
const List<SoatInsurerRule> kSoatInsurerRules = [
  // ── Top 5 by market share: specific policy regexes ──────────────────────
  SoatInsurerRule(
    canonicalName: 'SURA',
    aliases: ['sura', 'suramericana', 'seguros sura'],
  ),
  SoatInsurerRule(
    canonicalName: 'Seguros Bolívar',
    aliases: ['bolivar', 'seguros bolivar'],
  ),
  SoatInsurerRule(
    // The bare 'estado' alias is intentionally omitted: it matched common SOAT
    // phrases ("estado de la póliza", "estado: vigente") producing false
    // positives. The insurer must appear as "seguros del estado" / "del estado".
    canonicalName: 'Seguros del Estado',
    aliases: ['seguros del estado', 'del estado'],
  ),
  SoatInsurerRule(
    canonicalName: 'AXA Colpatria',
    aliases: ['axa colpatria', 'axa', 'colpatria'],
  ),
  SoatInsurerRule(
    canonicalName: 'Seguros Mundial',
    aliases: ['mundial', 'seguros mundial'],
  ),
  // ── Remaining 5: generic policy regex ───────────────────────────────────
  SoatInsurerRule(
    canonicalName: 'La Previsora',
    aliases: ['previsora', 'la previsora'],
  ),
  SoatInsurerRule(
    canonicalName: 'Liberty Seguros',
    aliases: ['liberty', 'liberty seguros'],
  ),
  SoatInsurerRule(canonicalName: 'Mapfre', aliases: ['mapfre']),
  SoatInsurerRule(
    canonicalName: 'La Equidad',
    aliases: ['equidad', 'la equidad'],
  ),
  SoatInsurerRule(
    canonicalName: 'Aseguradora Solidaria',
    aliases: ['solidaria', 'aseguradora solidaria'],
  ),
];

/// Specific policy-number regexes are wired here so the catalog above stays
/// declarative. Keyed by [SoatInsurerRule.canonicalName].
final Map<String, RegExp> kInsurerPolicyPatterns = {
  // SURA SOAT policies typically look like a long numeric run, often prefixed.
  'SURA': RegExp(r'\b(\d{9,14})\b'),
  // Bolívar tends to use an alphanumeric block.
  'Seguros Bolívar': RegExp(r'\b([A-Z]{0,3}\d{8,12})\b'),
  // Estado: long numeric policy.
  'Seguros del Estado': RegExp(r'\b(\d{9,13})\b'),
  // AXA Colpatria: numeric, sometimes with dashes.
  'AXA Colpatria': RegExp(r'\b(\d{9,13})\b'),
  // Mundial: alphanumeric.
  'Seguros Mundial': RegExp(r'\b([A-Z0-9]{8,13})\b'),
};
