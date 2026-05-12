import 'package:intl/intl.dart';

/// Single source of truth for date/time formatting in the app. All UI date and
/// time strings must go through these getters so the format stays consistent
/// end-to-end.
extension DateFormatExtension on DateTime {
  /// Canonical UI date format: "d MMM yyyy" in Spanish (e.g. "5 may 2026").
  String get formattedDate => DateFormat('d MMM yyyy', 'es').format(this);

  /// Canonical UI time format: 12h with AM/PM in Spanish (e.g. "07:30 a. m.").
  String get formattedTime => DateFormat('hh:mm a', 'es').format(this);

  /// Convenience for "`<date>` • `<time>`" used in cards and lists.
  String get formattedDateTime => '$formattedDate • $formattedTime';

  /// RFC 3339 instant in UTC for REST APIs (matches [ApiDateTimeConverter]).
  String toApiIso8601String() => toUtc().toIso8601String();
}

extension NullableDateFormatExtension on DateTime? {
  String? get formattedDate => this?.formattedDate;
  String? get formattedTime => this?.formattedTime;
  String? get formattedDateTime => this?.formattedDateTime;
  String? toApiIso8601String() => this?.toUtc().toIso8601String();
}
