import 'package:freezed_annotation/freezed_annotation.dart';

part 'rider_vehicle_preview.freezed.dart';

/// Vista mínima de una moto del garaje para la ficha del rider. El resto de
/// datos del vehículo son responsabilidad de `features/garage` — F4 solo
/// necesita mostrar la miniatura.
@freezed
abstract class RiderVehiclePreview with _$RiderVehiclePreview {
  const factory RiderVehiclePreview({
    required String id,
    required String name,
    String? imageUrl,
  }) = _RiderVehiclePreview;
}
