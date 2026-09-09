import 'package:freezed_annotation/freezed_annotation.dart';

part 'maintenance_reminder.freezed.dart';

/// Intervalo del recordatorio del próximo servicio: "cada X km" y/o "cada Y
/// meses", se cumple el que llegue primero (hoja de intervalo, Pencil `Z6b3T`).
@freezed
abstract class MaintenanceReminder with _$MaintenanceReminder {
  const factory MaintenanceReminder({int? everyKm, int? everyMonths}) =
      _MaintenanceReminder;

  const MaintenanceReminder._();

  bool get isEmpty => everyKm == null && everyMonths == null;
}
