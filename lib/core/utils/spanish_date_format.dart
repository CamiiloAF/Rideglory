/// Formatos de fecha en español sin depender de la inicialización de
/// locale de `intl` (`initializeDateFormatting`), que no está configurada
/// en `main.dart`. Cubre justo lo que las pantallas de mantenimiento
/// necesitan; si otra feature necesita más, se amplía aquí.
abstract final class SpanishDateFormat {
  static const _shortMonths = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  static const _longMonths = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  /// `12 ago 2026`.
  static String short(DateTime date) {
    return '${date.day} ${_shortMonths[date.month - 1]} ${date.year}';
  }

  /// `12 de agosto de 2026`.
  static String long(DateTime date) {
    return '${date.day} de ${_longMonths[date.month - 1]} de ${date.year}';
  }

  /// `AGOSTO 2026`.
  static String monthYearUpper(DateTime date) {
    return '${_longMonths[date.month - 1].toUpperCase()} ${date.year}';
  }
}
