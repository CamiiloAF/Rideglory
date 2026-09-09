import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/exceptions/domain_exception.dart';
import '../domain/blood_type.dart';
import '../domain/consent_entry.dart';
import '../domain/delete_account_summary.dart';
import '../domain/profile.dart';
import '../domain/profile_error_code.dart';
import '../domain/profile_repository.dart';
import '../domain/rider_vehicle_preview.dart';
import 'blood_type_converter.dart';
import 'consent_entry_dto.dart';
import 'profile_dto.dart';
import 'profile_error_mapper.dart';

@LazySingleton(as: ProfileRepository)
class ProfileRepositoryImpl implements ProfileRepository {
  ProfileRepositoryImpl(this._supabaseClient);

  final supabase.SupabaseClient _supabaseClient;

  String get _userId {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      throw StateError('No hay sesión activa.');
    }
    return userId;
  }

  @override
  Future<Either<DomainException, Profile>> getProfile() async {
    try {
      final user = _supabaseClient.auth.currentUser;
      if (user == null) {
        return const Left(DomainException(message: ProfileErrorCode.unknown));
      }
      final json = await _supabaseClient
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();
      final dto = ProfileDto.fromJson(json);
      return Right(dto.toDomain(user.email ?? ''));
    } catch (error) {
      return Left(mapProfileError(error));
    }
  }

  @override
  Future<Either<DomainException, Profile>> updateProfile({
    String? fullName,
    String? phone,
    DateTime? birthDate,
    String? residenceCity,
    String? eps,
    String? medicalInsurance,
    BloodType? bloodType,
  }) async {
    try {
      const bloodTypeConverter = BloodTypeConverter();
      final payload = <String, dynamic>{
        if (fullName != null) 'full_name': fullName,
        if (phone != null) 'phone': phone,
        if (birthDate != null)
          'birth_date':
              '${birthDate.year.toString().padLeft(4, '0')}-${birthDate.month.toString().padLeft(2, '0')}-${birthDate.day.toString().padLeft(2, '0')}',
        if (residenceCity != null) 'residence_city': residenceCity,
        if (eps != null) 'eps': eps,
        if (medicalInsurance != null) 'medical_insurance': medicalInsurance,
        if (bloodType != null)
          'blood_type': bloodTypeConverter.toJson(bloodType),
      };
      await _supabaseClient.from('profiles').update(payload).eq('id', _userId);
      return getProfile();
    } catch (error) {
      return Left(mapProfileError(error));
    }
  }

  @override
  Future<Either<DomainException, Profile>> updateEmergencyContact({
    required String name,
    required String phone,
    String? relationship,
  }) async {
    try {
      await _supabaseClient
          .from('profiles')
          .update({
            'emergency_contact_name': name,
            'emergency_contact_phone': phone,
            'emergency_contact_relationship': relationship,
          })
          .eq('id', _userId);
      return getProfile();
    } catch (error) {
      return Left(mapProfileError(error));
    }
  }

  @override
  Future<Either<DomainException, List<RiderVehiclePreview>>>
  getRiderVehiclePreviews() async {
    try {
      final rows = await _supabaseClient
          .from('vehicles')
          .select('id, name, image_path')
          .eq('owner_id', _userId)
          .isFilter('archived_at', null)
          .order('created_at');
      final previews = <RiderVehiclePreview>[];
      for (final row in rows as List<dynamic>) {
        final map = row as Map<String, dynamic>;
        final imagePath = map['image_path'] as String?;
        String? imageUrl;
        if (imagePath != null) {
          imageUrl = await _supabaseClient.storage
              .from('vehicle-images')
              .createSignedUrl(imagePath, 3600);
        }
        previews.add(
          RiderVehiclePreview(
            id: map['id'] as String,
            name: map['name'] as String,
            imageUrl: imageUrl,
          ),
        );
      }
      return Right(previews);
    } catch (error) {
      return Left(mapProfileError(error));
    }
  }

  @override
  Future<Either<DomainException, DeleteAccountSummary>>
  getDeleteAccountSummary() async {
    try {
      final vehicles = await _supabaseClient
          .from('vehicles')
          .select('id')
          .eq('owner_id', _userId);
      final vehicleIds = (vehicles as List<dynamic>)
          .map((row) => (row as Map<String, dynamic>)['id'] as String)
          .toList();

      var maintenanceCount = 0;
      var documentCount = 0;
      if (vehicleIds.isNotEmpty) {
        final maintenances = await _supabaseClient
            .from('maintenances')
            .select('id')
            .inFilter('vehicle_id', vehicleIds);
        maintenanceCount = (maintenances as List<dynamic>).length;

        final documents = await _supabaseClient
            .from('vehicle_documents')
            .select('id')
            .inFilter('vehicle_id', vehicleIds);
        documentCount = (documents as List<dynamic>).length;
      }

      return Right(
        DeleteAccountSummary(
          vehicleCount: vehicleIds.length,
          maintenanceCount: maintenanceCount,
          documentCount: documentCount,
        ),
      );
    } catch (error) {
      return Left(mapProfileError(error));
    }
  }

  @override
  Future<Either<DomainException, List<ConsentEntry>>> getConsentLog() async {
    try {
      final rows = await _supabaseClient
          .from('consent_log')
          .select()
          .eq('user_id', _userId)
          .order('accepted_at', ascending: false);
      final entries = (rows as List<dynamic>)
          .map(
            (row) => ConsentEntryDto.fromJson(
              row as Map<String, dynamic>,
            ).toDomain(),
          )
          .toList();
      return Right(entries);
    } catch (error) {
      return Left(mapProfileError(error));
    }
  }

  @override
  Future<Either<DomainException, void>> deleteAccount() async {
    try {
      await _supabaseClient.functions.invoke('delete-account');
      return const Right(null);
    } on supabase.FunctionException catch (error) {
      final body = error.details;
      final errorCode = body is Map ? body['error'] as String? : null;
      if (errorCode == 'active_event_owner') {
        return const Left(
          DomainException(message: ProfileErrorCode.activeEventOrganizer),
        );
      }
      return const Left(DomainException(message: ProfileErrorCode.unknown));
    } catch (error) {
      return Left(mapProfileError(error));
    }
  }
}
