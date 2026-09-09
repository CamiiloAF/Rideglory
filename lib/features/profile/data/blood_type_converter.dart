import 'package:json_annotation/json_annotation.dart';

import '../domain/blood_type.dart';

/// Mapea `BloodType` (dominio puro) al valor `snake_case` del enum
/// `public.blood_type` en Postgres, sin acoplar `domain/` a
/// `json_annotation`.
class BloodTypeConverter implements JsonConverter<BloodType?, String?> {
  const BloodTypeConverter();

  static const _values = {
    'o_positive': BloodType.oPositive,
    'o_negative': BloodType.oNegative,
    'a_positive': BloodType.aPositive,
    'a_negative': BloodType.aNegative,
    'b_positive': BloodType.bPositive,
    'b_negative': BloodType.bNegative,
    'ab_positive': BloodType.abPositive,
    'ab_negative': BloodType.abNegative,
  };

  @override
  BloodType? fromJson(String? json) => json == null ? null : _values[json];

  @override
  String? toJson(BloodType? object) {
    if (object == null) {
      return null;
    }
    return _values.entries.firstWhere((entry) => entry.value == object).key;
  }
}
