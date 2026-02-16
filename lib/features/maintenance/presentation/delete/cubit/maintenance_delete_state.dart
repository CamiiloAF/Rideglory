part of 'maintenance_delete_cubit.dart';

@freezed
class MaintenanceDeleteState with _$MaintenanceDeleteState {
  const factory MaintenanceDeleteState.initial() = _Initial;
  const factory MaintenanceDeleteState.loading() = _Loading;
  const factory MaintenanceDeleteState.success({required String deletedId}) =
      _Success;
  const factory MaintenanceDeleteState.error({required String message}) =
      _Error;
}
