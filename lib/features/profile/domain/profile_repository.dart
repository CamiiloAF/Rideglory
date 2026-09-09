import 'package:dartz/dartz.dart';

import '../../../core/exceptions/domain_exception.dart';
import 'blood_type.dart';
import 'consent_entry.dart';
import 'delete_account_summary.dart';
import 'profile.dart';
import 'rider_vehicle_preview.dart';

abstract class ProfileRepository {
  Future<Either<DomainException, Profile>> getProfile();

  Future<Either<DomainException, Profile>> updateProfile({
    String? fullName,
    String? phone,
    DateTime? birthDate,
    String? residenceCity,
    String? eps,
    String? medicalInsurance,
    BloodType? bloodType,
  });

  Future<Either<DomainException, Profile>> updateEmergencyContact({
    required String name,
    required String phone,
    String? relationship,
  });

  Future<Either<DomainException, List<RiderVehiclePreview>>>
  getRiderVehiclePreviews();

  Future<Either<DomainException, DeleteAccountSummary>>
  getDeleteAccountSummary();

  Future<Either<DomainException, List<ConsentEntry>>> getConsentLog();

  /// Llama a la Edge Function `delete-account`. `Left` con
  /// `ProfileErrorCode.activeEventOrganizer` cuando el rider organiza una
  /// rodada que no ha terminado (Pencil: XryZO).
  Future<Either<DomainException, void>> deleteAccount();
}
