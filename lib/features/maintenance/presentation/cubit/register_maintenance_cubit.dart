import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/maintenance.dart';
import '../../domain/maintenance_reminder.dart';
import '../../domain/maintenance_type_suggestion.dart';
import '../../domain/register_maintenance_params.dart';
import '../../domain/usecases/register_maintenance_use_case.dart';
import '../../domain/usecases/update_maintenance_use_case.dart';
import '../../domain/vehicle_option.dart';
import 'register_maintenance_state.dart';

/// Asistente de 3 pasos para registrar o editar un mantenimiento. Un mismo
/// cubit sirve para ambos casos: [start] fija la moto y, si [existing] no
/// es nulo, prellena todos los campos y guarda actualiza en vez de insertar.
@injectable
class RegisterMaintenanceCubit extends Cubit<RegisterMaintenanceState> {
  RegisterMaintenanceCubit(this._register, this._update)
    : super(
        const RegisterMaintenanceState(
          vehicle: VehicleOption(
            id: '',
            displayName: '',
            chipLabel: '',
            currentMileage: 0,
            isMain: false,
          ),
        ),
      );

  final RegisterMaintenanceUseCase _register;
  final UpdateMaintenanceUseCase _update;

  void start(VehicleOption vehicle, {Maintenance? existing}) {
    if (existing == null) {
      emit(
        RegisterMaintenanceState(
          vehicle: vehicle,
          odometer: vehicle.currentMileage,
          serviceDate: DateTime.now(),
        ),
      );
      return;
    }
    // Al editar, el tipo ya es texto libre guardado en la base (puede o no
    // coincidir con una sugerencia); se trata siempre como "Otro" con ese
    // texto prellenado, que es correcto en ambos casos.
    emit(
      RegisterMaintenanceState(
        vehicle: vehicle,
        editingId: existing.id,
        typeSuggestion: MaintenanceTypeSuggestion.other,
        customType: existing.type,
        odometer: existing.odometer,
        serviceDate: existing.serviceDate,
        workshop: existing.workshop,
        cost: existing.cost,
        notes: existing.notes,
        reminderEnabled: existing.hasReminder,
        reminder: existing.hasReminder
            ? MaintenanceReminder(
                everyKm: existing.nextOdometer == null
                    ? null
                    : existing.nextOdometer! - existing.odometer,
                everyMonths: existing.nextDate == null
                    ? null
                    : _monthsBetween(existing.serviceDate, existing.nextDate!),
              )
            : null,
      ),
    );
  }

  void selectTypeSuggestion(
    MaintenanceTypeSuggestion suggestion,
    String label,
  ) {
    emit(
      state.copyWith(typeSuggestion: suggestion, typeSuggestionLabel: label),
    );
  }

  /// Vuelve de la vista de texto libre ("Otro") a la lista de sugerencias.
  void clearTypeSelection() {
    emit(
      state.copyWith(
        typeSuggestion: null,
        typeSuggestionLabel: null,
        customType: '',
      ),
    );
  }

  void updateCustomType(String value) {
    emit(state.copyWith(customType: value));
  }

  void updateOdometer(int? value) {
    emit(state.copyWith(odometer: value));
  }

  void updateServiceDate(DateTime value) {
    emit(state.copyWith(serviceDate: value));
  }

  void updateWorkshop(String value) {
    emit(state.copyWith(workshop: value.isEmpty ? null : value));
  }

  void updateCost(double? value) {
    emit(state.copyWith(cost: value));
  }

  void updateNotes(String value) {
    emit(state.copyWith(notes: value.isEmpty ? null : value));
  }

  void toggleReminder(bool enabled) {
    emit(state.copyWith(reminderEnabled: enabled));
  }

  void setReminder(MaintenanceReminder reminder) {
    emit(
      state.copyWith(reminder: reminder, reminderEnabled: !reminder.isEmpty),
    );
  }

  void nextStep() {
    if (state.step >= 2) return;
    emit(state.copyWith(step: state.step + 1));
  }

  void previousStep() {
    if (state.step <= 0) return;
    emit(state.copyWith(step: state.step - 1));
  }

  String resolveType() => state.isOtherType
      ? state.customType.trim()
      : (state.typeSuggestionLabel ?? '');

  Future<void> submit() async {
    final odometer = state.odometer;
    final serviceDate = state.serviceDate;
    if (odometer == null || serviceDate == null) return;

    emit(state.copyWith(submission: const ResultState.loading()));

    final params = RegisterMaintenanceParams(
      vehicleId: state.vehicle.id,
      type: resolveType(),
      serviceDate: serviceDate,
      odometer: odometer,
      cost: state.cost,
      workshop: state.workshop,
      notes: state.notes,
      reminder: state.reminderEnabled ? state.reminder : null,
    );

    final result = state.isEditing
        ? await _update(state.editingId!, params)
        : await _register(params);

    result.fold(
      (error) =>
          emit(state.copyWith(submission: ResultState.error(error: error))),
      (maintenance) =>
          emit(state.copyWith(submission: ResultState.data(data: maintenance))),
    );
  }

  static int _monthsBetween(DateTime from, DateTime to) {
    return (to.year - from.year) * 12 + (to.month - from.month);
  }
}
