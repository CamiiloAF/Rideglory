part of 'maintenance_form_cubit.dart';

@freezed
class MaintenanceFormState with _$MaintenanceFormState {
  const factory MaintenanceFormState.initial() = _Initial;
  const factory MaintenanceFormState.editing({
    required MaintenanceModel maintenance,
  }) = _Editing;
  const factory MaintenanceFormState.loading() = _Loading;
  const factory MaintenanceFormState.success({
    required MaintenanceModel maintenance,
  }) = _Success;
  const factory MaintenanceFormState.error({required String message}) = _Error;
}
