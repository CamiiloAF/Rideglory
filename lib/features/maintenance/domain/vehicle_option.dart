import 'package:freezed_annotation/freezed_annotation.dart';

part 'vehicle_option.freezed.dart';

/// Moto mínima para el selector de mantenimiento: id, nombre para mostrar,
/// placa y kilometraje actual. Se lee de `vehicles`; esta feature no
/// depende de `garage`, que se construye en paralelo.
@freezed
abstract class VehicleOption with _$VehicleOption {
  const factory VehicleOption({
    required String id,
    required String displayName,
    required String chipLabel,
    String? licensePlate,
    required int currentMileage,
    required bool isMain,
  }) = _VehicleOption;
}
