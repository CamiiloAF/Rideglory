extension DateFormatExtension on DateTime {
  String toFormattedString() {
    return '$day/$month/$year';
  }

  /// RFC 3339 instant in UTC for REST APIs (matches [ApiDateTimeConverter]).
  String toApiIso8601String() => toUtc().toIso8601String();
}

extension NullableDateTimeApiIsoExtension on DateTime? {
  String? toApiIso8601String() => this?.toUtc().toIso8601String();
}
