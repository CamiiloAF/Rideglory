import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/models/vehicle.dart';
import '../../domain/models/vehicle_document_alert.dart';

part 'vehicle_dto.freezed.dart';
part 'vehicle_dto.g.dart';

/// DTO de la fila `vehicles`. Mapea `snake_case` de Postgres a `camelCase`.
@freezed
abstract class VehicleDto with _$VehicleDto {
  const factory VehicleDto({
    required String id,
    @JsonKey(name: 'owner_id') required String ownerId,
    required String name,
    required String brand,
    String? model,
    int? year,
    @JsonKey(name: 'engine_cc') int? engineCc,
    @JsonKey(name: 'license_plate') String? licensePlate,
    @JsonKey(name: 'current_mileage') required int currentMileage,
    @JsonKey(name: 'image_path') String? imagePath,
    @JsonKey(name: 'is_main') required bool isMain,
    @JsonKey(name: 'archived_at') DateTime? archivedAt,
  }) = _VehicleDto;

  const VehicleDto._();

  factory VehicleDto.fromJson(Map<String, dynamic> json) => _$VehicleDtoFromJson(json);

  /// [imageUrl] es la URL firmada, resuelta aparte por el datasource: nunca
  /// viaja en la fila de Postgres.
  Vehicle toDomain({String? imageUrl, VehicleDocumentAlert? documentAlert}) {
    return Vehicle(
      id: id,
      ownerId: ownerId,
      name: name,
      brand: brand,
      model: model ?? '',
      year: year,
      engineCc: engineCc,
      licensePlate: licensePlate,
      currentMileage: currentMileage,
      imagePath: imagePath,
      imageUrl: imageUrl,
      isMain: isMain,
      archivedAt: archivedAt,
      documentAlert: documentAlert,
    );
  }
}
