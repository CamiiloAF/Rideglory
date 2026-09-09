import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance.freezed.dart';

/// Un registro de mantenimiento de una moto: lo que se hizo, cuándo, a
/// cuánto iba el odómetro, y opcionalmente el recordatorio del siguiente.
@freezed
abstract class Maintenance with _$Maintenance {
  const factory Maintenance({
    required String id,
    required String vehicleId,
    required String vehicleDisplayName,
    required String type,
    required DateTime serviceDate,
    required int odometer,
    double? cost,
    String? workshop,
    String? notes,
    DateTime? nextDate,
    int? nextOdometer,
  }) = _Maintenance;

  const Maintenance._();

  bool get hasReminder => nextDate != null || nextOdometer != null;
}
