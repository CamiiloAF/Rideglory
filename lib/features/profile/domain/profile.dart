import 'package:freezed_annotation/freezed_annotation.dart';

import 'blood_type.dart';

part 'profile.freezed.dart';

/// Perfil del rider. `email` viene de `auth.users`, no de la tabla
/// `profiles` — Supabase Auth es la única fuente de verdad para el correo.
@freezed
abstract class Profile with _$Profile {
  const factory Profile({
    required String id,
    required String email,
    String? fullName,
    String? phone,
    DateTime? birthDate,
    String? residenceCity,
    String? eps,
    String? medicalInsurance,
    BloodType? bloodType,
    String? emergencyContactName,
    String? emergencyContactPhone,
    String? emergencyContactRelationship,
  }) = _Profile;

  const Profile._();

  bool get hasEmergencyContact =>
      (emergencyContactName?.isNotEmpty ?? false) &&
      (emergencyContactPhone?.isNotEmpty ?? false);
}
