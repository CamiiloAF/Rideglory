/// API date encoding for backends that expect RFC 3339 with UTC (`Z`), e.g. Prisma.
///
/// - **codegen DTOs:** `@JsonSerializable(converters: apiJsonDateTimeConverters)` covers
///   nullable [DateTime?]. For required [DateTime], wrap generated `toJson` (see
///   [EventDto], [MaintenanceDto], [EventRegistrationDto]) using [apiEncodeRequiredDateTime].
/// - **Manual maps:** use [NullableDateTimeApiIsoExtension] / `DateTime.toApiIso8601String` from
///   `date_extensions.dart`.
library;

import 'package:json_annotation/json_annotation.dart';

/// Required [DateTime] fields on DTOs (json_serializable skips global converters for non-null dates).
String apiEncodeRequiredDateTime(DateTime value) =>
    value.toUtc().toIso8601String();

/// RFC 3339 instants with UTC zone (`Z`) for strict REST parsers (e.g. Prisma).
class NullableApiDateTimeConverter
    implements JsonConverter<DateTime?, String?> {
  const NullableApiDateTimeConverter();

  @override
  DateTime? fromJson(String? json) {
    if (json == null || json.isEmpty) return null;
    return DateTime.tryParse(json)?.toLocal();
  }

  @override
  String? toJson(DateTime? object) => object?.toUtc().toIso8601String();
}

/// Use with `@JsonSerializable(converters: apiJsonDateTimeConverters)` on REST DTOs.
const apiJsonDateTimeConverters = <JsonConverter<dynamic, dynamic>>[
  NullableApiDateTimeConverter(),
];
