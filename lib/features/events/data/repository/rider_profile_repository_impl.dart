import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/http/rest_client_functions.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/events/domain/model/rider_profile_model.dart';
import 'package:rideglory/features/events/domain/repository/rider_profile_repository.dart';
import 'package:rideglory/features/users/data/service/user_service.dart';

@Injectable(as: RiderProfileRepository)
class RiderProfileRepositoryImpl implements RiderProfileRepository {
  RiderProfileRepositoryImpl(this._userService, this._authService);

  final UserService _userService;
  final AuthService _authService;

  @override
  Future<Either<DomainException, RiderProfileModel?>> getMyRiderProfile() {
    return executeService(
      function: () async {
        final user = await _userService.getCurrentUser();
        return RiderProfileModel(
          id: user.id,
          userId: user.id,
          fullName: user.fullName,
          identificationNumber: user.identificationNumber,
          birthDate: user.birthDate,
          phone: user.phone,
          email: user.email,
          residenceCity: user.residenceCity,
          eps: user.eps,
          medicalInsurance: user.medicalInsurance,
          bloodType: user.bloodType,
          emergencyContactName: user.emergencyContactName,
          emergencyContactPhone: user.emergencyContactPhone,
          updatedDate: user.updatedAt,
        );
      },
    );
  }

  @override
  Future<Either<DomainException, RiderProfileModel>> saveRiderProfile(
    RiderProfileModel profile,
  ) {
    final userId = _authService.currentUser?.id ?? profile.userId;
    return executeService(
      function: () async {
        final body = <String, dynamic>{
          if (profile.fullName != null) 'fullName': profile.fullName,
          if (profile.identificationNumber != null)
            'identificationNumber': profile.identificationNumber,
          if (profile.birthDate != null)
            'birthDate': profile.birthDate!.toIso8601String(),
          if (profile.phone != null) 'phone': profile.phone,
          if (profile.residenceCity != null)
            'residenceCity': profile.residenceCity,
          if (profile.eps != null) 'eps': profile.eps,
          if (profile.medicalInsurance != null)
            'medicalInsurance': profile.medicalInsurance,
          if (profile.bloodType != null)
            'bloodType': profile.bloodType!.name
                .replaceAllMapped(RegExp(r'([A-Z])'), (m) => '_${m[1]}')
                .toUpperCase(),
          if (profile.emergencyContactName != null)
            'emergencyContactName': profile.emergencyContactName,
          if (profile.emergencyContactPhone != null)
            'emergencyContactPhone': profile.emergencyContactPhone,
        };
        final updated = await _userService.updateUser(userId, body);
        return profile.copyWith(updatedDate: updated.updatedAt);
      },
    );
  }
}
