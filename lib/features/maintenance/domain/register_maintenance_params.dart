import 'package:freezed_annotation/freezed_annotation.dart';

import 'maintenance_reminder.dart';

part 'register_maintenance_params.freezed.dart';

/// Datos para registrar (o editar) un mantenimiento. `reminder` es el
/// intervalo elegido en el paso 3; el repositorio lo traduce a
/// `next_date`/`next_odometer` a partir de [serviceDate] y [odometer].
@freezed
abstract class RegisterMaintenanceParams with _$RegisterMaintenanceParams {
  const factory RegisterMaintenanceParams({
    required String vehicleId,
    required String type,
    required DateTime serviceDate,
    required int odometer,
    double? cost,
    String? workshop,
    String? notes,
    MaintenanceReminder? reminder,
  }) = _RegisterMaintenanceParams;
}
