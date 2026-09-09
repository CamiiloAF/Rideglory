import 'package:json_annotation/json_annotation.dart';

import '../domain/blood_type.dart';
import '../domain/profile.dart';
import 'blood_type_converter.dart';

part 'profile_dto.g.dart';

/// DTO de la fila `public.profiles`. `email` no está en esta tabla: se
/// inyecta desde `auth.users` al construir el [Profile] de dominio.
@JsonSerializable()
class ProfileDto {
  ProfileDto({
    required this.id,
    this.fullName,
    this.phone,
    this.birthDate,
    this.residenceCity,
    this.eps,
    this.medicalInsurance,
    this.bloodType,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.emergencyContactRelationship,
  });

  factory ProfileDto.fromJson(Map<String, dynamic> json) =>
      _$ProfileDtoFromJson(json);

  final String id;
  @JsonKey(name: 'full_name')
  final String? fullName;
  final String? phone;
  @JsonKey(name: 'birth_date')
  final DateTime? birthDate;
  @JsonKey(name: 'residence_city')
  final String? residenceCity;
  final String? eps;
  @JsonKey(name: 'medical_insurance')
  final String? medicalInsurance;
  @BloodTypeConverter()
  @JsonKey(name: 'blood_type')
  final BloodType? bloodType;
  @JsonKey(name: 'emergency_contact_name')
  final String? emergencyContactName;
  @JsonKey(name: 'emergency_contact_phone')
  final String? emergencyContactPhone;
  @JsonKey(name: 'emergency_contact_relationship')
  final String? emergencyContactRelationship;

  Map<String, dynamic> toJson() => _$ProfileDtoToJson(this);

  Profile toDomain(String email) => Profile(
    id: id,
    email: email,
    fullName: fullName,
    phone: phone,
    birthDate: birthDate,
    residenceCity: residenceCity,
    eps: eps,
    medicalInsurance: medicalInsurance,
    bloodType: bloodType,
    emergencyContactName: emergencyContactName,
    emergencyContactPhone: emergencyContactPhone,
    emergencyContactRelationship: emergencyContactRelationship,
  );
}
