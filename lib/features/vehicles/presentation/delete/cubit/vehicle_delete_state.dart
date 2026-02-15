part of 'vehicle_delete_cubit.dart';

@freezed
class VehicleDeleteState with _$VehicleDeleteState {
  const factory VehicleDeleteState.initial() = _Initial;
  const factory VehicleDeleteState.loading() = _Loading;
  const factory VehicleDeleteState.success({required String deletedId}) =
      _Success;
  const factory VehicleDeleteState.error({required String message}) = _Error;
}
