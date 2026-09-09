import 'package:freezed_annotation/freezed_annotation.dart';

import 'vehicle_document_alert.dart';

part 'vehicle.freezed.dart';

/// Una moto del garaje del rider.
@freezed
abstract class Vehicle with _$Vehicle {
  const factory Vehicle({
    required String id,
    required String ownerId,
    required String name,
    required String brand,
    required String model,
    required int currentMileage,
    required bool isMain,
    int? year,
    int? engineCc,
    String? licensePlate,
    String? imagePath,
    String? imageUrl,
    DateTime? archivedAt,
    VehicleDocumentAlert? documentAlert,
  }) = _Vehicle;

  const Vehicle._();

  bool get isArchived => archivedAt != null;
}
