import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/maintenance.dart';
import '../../domain/maintenance_reminder.dart';
import '../../domain/maintenance_type_suggestion.dart';
import '../../domain/vehicle_option.dart';

part 'register_maintenance_state.freezed.dart';

/// Registrar (o editar) un mantenimiento en 3 pasos (Pencil `Yhgp2` /
/// `x74Sa` / `g3rONd`).
@freezed
abstract class RegisterMaintenanceState with _$RegisterMaintenanceState {
  const factory RegisterMaintenanceState({
    required VehicleOption vehicle,

    /// `null` al crear; el id del registro que se está editando.
    String? editingId,
    @Default(0) int step,
    MaintenanceTypeSuggestion? typeSuggestion,

    /// Etiqueta en español de [typeSuggestion], resuelta por la vista desde
    /// `l10n` (el cubit no tiene `BuildContext` y no puede tener strings de
    /// UI incrustados). Ignorada cuando [isOtherType].
    String? typeSuggestionLabel,
    @Default('') String customType,
    int? odometer,
    DateTime? serviceDate,
    String? workshop,
    double? cost,
    String? notes,
    @Default(false) bool reminderEnabled,
    MaintenanceReminder? reminder,
    @Default(ResultState<Maintenance>.initial())
    ResultState<Maintenance> submission,
  }) = _RegisterMaintenanceState;

  const RegisterMaintenanceState._();

  bool get isEditing => editingId != null;

  bool get isOtherType => typeSuggestion == MaintenanceTypeSuggestion.other;

  bool get canContinueStep1 =>
      typeSuggestion != null && (!isOtherType || customType.trim().isNotEmpty);

  bool get canContinueStep2 => odometer != null && odometer! >= 0;

  bool get isBelowCurrentOdometer =>
      odometer != null && odometer! < vehicle.currentMileage;

  bool get isSubmitting => submission is Loading<Maintenance>;
}
