import 'package:freezed_annotation/freezed_annotation.dart';

import '../../domain/models/vehicle_document.dart';

part 'vehicle_document_dto.freezed.dart';
part 'vehicle_document_dto.g.dart';

/// DTO de la fila `vehicle_documents`.
@freezed
abstract class VehicleDocumentDto with _$VehicleDocumentDto {
  const factory VehicleDocumentDto({
    required String id,
    @JsonKey(name: 'vehicle_id') required String vehicleId,
    required String kind,
    @JsonKey(name: 'expiry_date') required DateTime expiryDate,
    @JsonKey(name: 'reminder_enabled') required bool reminderEnabled,
    String? number,
    String? issuer,
    @JsonKey(name: 'start_date') DateTime? startDate,
    @JsonKey(name: 'file_path') String? filePath,
  }) = _VehicleDocumentDto;

  const VehicleDocumentDto._();

  factory VehicleDocumentDto.fromJson(Map<String, dynamic> json) =>
      _$VehicleDocumentDtoFromJson(json);

  VehicleDocument toDomain() {
    return VehicleDocument(
      id: id,
      vehicleId: vehicleId,
      kind: kind == 'soat' ? DocumentKind.soat : DocumentKind.rtm,
      expiryDate: expiryDate,
      reminderEnabled: reminderEnabled,
      number: number,
      issuer: issuer,
      startDate: startDate,
      filePath: filePath,
    );
  }
}
