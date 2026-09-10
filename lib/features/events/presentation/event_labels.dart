import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../../l10n/l10n_extensions.dart';
import '../domain/event_difficulty.dart';

/// Etiquetas de dominio a texto en español. Sin `BuildContext` no hay
/// `l10n`, así que estas funciones viven en presentación, no en dominio.
String eventDifficultyLabel(BuildContext context, EventDifficulty difficulty) {
  return switch (difficulty) {
    EventDifficulty.easy => context.l10n.events_difficulty_easy,
    EventDifficulty.medium => context.l10n.events_difficulty_medium,
    EventDifficulty.hard => context.l10n.events_difficulty_hard,
  };
}

/// `Gratis` o `$ 180.000` (formato colombiano: punto de miles, sin
/// decimales).
String eventPriceLabel(BuildContext context, int price) {
  if (price <= 0) return context.l10n.events_card_free;
  final formatted = NumberFormat.decimalPattern('es_CO').format(price);
  return '\$ $formatted';
}

String eventDateLabel(DateTime dateTime) {
  final weekday = _weekdayAbbrev[dateTime.weekday - 1];
  final month = _monthAbbrev[dateTime.month - 1];
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final minute = dateTime.minute.toString().padLeft(2, '0');
  final period = dateTime.hour >= 12 ? 'p.m.' : 'a.m.';
  return '$weekday ${dateTime.day} $month · $hour:$minute $period';
}

const _weekdayAbbrev = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];

const _monthAbbrev = [
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
