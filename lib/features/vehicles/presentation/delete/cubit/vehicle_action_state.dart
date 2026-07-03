part of 'vehicle_action_cubit.dart';

@freezed
class VehicleActionState with _$VehicleActionState {
  const factory VehicleActionState.initial() = _Initial;
  const factory VehicleActionState.loading() = _Loading;
  const factory VehicleActionState.archiveSuccess({
    required String archivedId,
  }) = _ArchiveSuccess;
  const factory VehicleActionState.unarchiveSuccess({
    required String unarchivedId,
  }) = _UnarchiveSuccess;
  const factory VehicleActionState.permanentDeleteSuccess({
    required String deletedId,
  }) = _PermanentDeleteSuccess;
  const factory VehicleActionState.error({required String message}) = _Error;
  const factory VehicleActionState.errorLastVehicle({required String message}) =
      _ErrorLastVehicle;
}
