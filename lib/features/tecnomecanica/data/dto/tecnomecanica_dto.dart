import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/core/http/api_date_time.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';

part 'tecnomecanica_dto.g.dart';

@JsonSerializable(converters: apiJsonDateTimeConverters)
class TecnomecanicaDto extends TecnomecanicaModel {
  const TecnomecanicaDto({
    required super.id,
    required super.vehicleId,
    required super.certificateNumber,
    required super.cdaName,
    super.cdaCode,
    super.startDate,
    required super.expiryDate,
    super.documentUrl,
    super.createdAt,
    super.updatedAt,
  });

  factory TecnomecanicaDto.fromJson(Map<String, dynamic> json) =>
      _$TecnomecanicaDtoFromJson(json);

  Map<String, dynamic> toJson() => _$TecnomecanicaDtoToJson(this);
}

@JsonSerializable(converters: apiJsonDateTimeConverters)
class CreateTecnomecanicaRequestDto {
  const CreateTecnomecanicaRequestDto({
    required this.certificateNumber,
    required this.cdaName,
    this.cdaCode,
    this.startDate,
    required this.expiryDate,
    this.documentUrl,
  });

  final String certificateNumber;
  final String cdaName;
  final String? cdaCode;
  final DateTime? startDate;
  final DateTime expiryDate;
  final String? documentUrl;

  factory CreateTecnomecanicaRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateTecnomecanicaRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTecnomecanicaRequestDtoToJson(this);
}
