class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.identificationNumber,
    this.birthDate,
    this.phone,
    this.residenceCity,
    this.eps,
    this.medicalInsurance,
    this.bloodType,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.isDeleted = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String? fullName;
  final String? email;
  final String? identificationNumber;
  final DateTime? birthDate;
  final String? phone;
  final String? residenceCity;
  final String? eps;
  final String? medicalInsurance;
  final String? bloodType;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final bool isDeleted;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}
