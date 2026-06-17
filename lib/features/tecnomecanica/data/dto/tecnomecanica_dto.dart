import 'package:json_annotation/json_annotation.dart';
import 'package:rideglory/core/http/api_date_time.dart';
import 'package:rideglory/features/tecnomecanica/domain/models/tecnomecanica_model.dart';

part 'tecnomecanica_dto.g.dart';

@JsonSerializable(converters: apiJsonDateTimeConverters)
class TecnomecanicaDto extends TecnomecanicaModel {
  const TecnomecanicaDto({
    required super.id,
    required super.vehicleId,
    required super.cdaName,
    required super.startDate,
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
    required this.cdaName,
    required this.startDate,
    required this.expiryDate,
    this.documentUrl,
  });

  final String cdaName;
  final DateTime startDate;
  final DateTime expiryDate;
  final String? documentUrl;

  factory CreateTecnomecanicaRequestDto.fromJson(Map<String, dynamic> json) =>
      _$CreateTecnomecanicaRequestDtoFromJson(json);

  Map<String, dynamic> toJson() => _$CreateTecnomecanicaRequestDtoToJson(this);
}
