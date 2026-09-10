import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_vehicle_option.freezed.dart';

/// Una moto del garaje del rider, para el selector de inscripción (EV4).
@freezed
abstract class EventVehicleOption with _$EventVehicleOption {
  const factory EventVehicleOption({
    required String id,
    required String name,
    required String brand,
    String? model,
    String? licensePlate,
    String? imageUrl,
  }) = _EventVehicleOption;
}
