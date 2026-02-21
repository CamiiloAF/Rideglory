import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/events/constants/registration_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_registration_model.dart';
import 'package:rideglory/features/events/domain/model/rider_profile_model.dart';
import 'package:rideglory/features/events/domain/use_cases/add_event_registration_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_rider_profile_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/save_rider_profile_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_registration_use_case.dart';
import 'package:rideglory/features/vehicles/domain/models/vehicle_model.dart';

part 'registration_form_cubit.freezed.dart';
part 'registration_form_state.dart';

@injectable
class RegistrationFormCubit extends Cubit<RegistrationFormState> {
  RegistrationFormCubit(
    this._addRegistrationUseCase,
    this._updateRegistrationUseCase,
    this._getRiderProfileUseCase,
    this._saveRiderProfileUseCase,
    this._authService,
  ) : super(const RegistrationFormState.initial());

  final formKey = GlobalKey<FormBuilderState>();

  final AddEventRegistrationUseCase _addRegistrationUseCase;
  final UpdateEventRegistrationUseCase _updateRegistrationUseCase;
  final GetRiderProfileUseCase _getRiderProfileUseCase;
  final SaveRiderProfileUseCase _saveRiderProfileUseCase;
  final AuthService _authService;

  String? _eventId;
  RiderProfileModel? riderProfile;

  void initialize({
    required String eventId,
    EventRegistrationModel? existingRegistration,
  }) {
    _eventId = eventId;
    if (existingRegistration != null) {
      emit(RegistrationFormState.editing(registration: existingRegistration));
    } else {
      emit(const RegistrationFormState.initial());
    }
    _loadRiderProfile();
  }

  Future<void> _loadRiderProfile() async {
    final result = await _getRiderProfileUseCase();
    result.fold((_) => null, (profile) {
      riderProfile = profile;
    });
  }

  void preloadFromVehicle(VehicleModel vehicle) {
    formKey.currentState?.patchValue({
      RegistrationFormFields.vehicleBrand: vehicle.brand ?? '',
      RegistrationFormFields.vehicleReference: vehicle.model ?? '',
      RegistrationFormFields.licensePlate: vehicle.licensePlate ?? '',
      RegistrationFormFields.vin: vehicle.vin ?? '',
    });
  }

  void preloadFromRiderProfile() {
    if (riderProfile == null) return;
    final profile = riderProfile!;
    formKey.currentState?.patchValue({
      if (profile.firstName != null)
        RegistrationFormFields.firstName: profile.firstName,
      if (profile.lastName != null)
        RegistrationFormFields.lastName: profile.lastName,
      if (profile.identificationNumber != null)
        RegistrationFormFields.identificationNumber:
            profile.identificationNumber,
      if (profile.birthDate != null)
        RegistrationFormFields.birthDate: profile.birthDate,
      if (profile.phone != null) RegistrationFormFields.phone: profile.phone,
      if (profile.email != null) RegistrationFormFields.email: profile.email,
      if (profile.residenceCity != null)
        RegistrationFormFields.residenceCity: profile.residenceCity,
      if (profile.eps != null) RegistrationFormFields.eps: profile.eps,
      if (profile.medicalInsurance != null)
        RegistrationFormFields.medicalInsurance: profile.medicalInsurance,
      if (profile.bloodType != null)
        RegistrationFormFields.bloodType: profile.bloodType,
      if (profile.emergencyContactName != null)
        RegistrationFormFields.emergencyContactName:
            profile.emergencyContactName,
      if (profile.emergencyContactPhone != null)
        RegistrationFormFields.emergencyContactPhone:
            profile.emergencyContactPhone,
    });
  }

  Future<void> saveRegistration() async {
    final registration = _buildRegistration();
    if (registration == null) return;

    emit(const RegistrationFormState.loading());

    final isEditing = state.maybeWhen(
      editing: (_) => true,
      orElse: () => false,
    );

    final result = isEditing
        ? await _updateRegistrationUseCase(registration)
        : await _addRegistrationUseCase(registration);

    result.fold(
      (error) => emit(RegistrationFormState.error(message: error.message)),
      (saved) async {
        await _saveRiderProfileUseCase(_buildRiderProfile(registration));
        emit(RegistrationFormState.success(registration: saved));
      },
    );
  }

  EventRegistrationModel? _buildRegistration() {
    if (!(formKey.currentState?.saveAndValidate() ?? false)) return null;

    final formData = formKey.currentState!.value;
    final userId = _authService.currentUser?.uid ?? '';

    return EventRegistrationModel(
      id: state.maybeWhen(editing: (r) => r.id, orElse: () => null),
      eventId: _eventId ?? '',
      userId: userId,
      firstName: formData[RegistrationFormFields.firstName] as String,
      lastName: formData[RegistrationFormFields.lastName] as String,
      identificationNumber:
          formData[RegistrationFormFields.identificationNumber] as String,
      birthDate: formData[RegistrationFormFields.birthDate] as DateTime,
      phone: formData[RegistrationFormFields.phone] as String,
      email: formData[RegistrationFormFields.email] as String,
      residenceCity: formData[RegistrationFormFields.residenceCity] as String,
      eps: formData[RegistrationFormFields.eps] as String,
      medicalInsurance:
          formData[RegistrationFormFields.medicalInsurance] as String?,
      bloodType: formData[RegistrationFormFields.bloodType] as BloodType,
      emergencyContactName:
          formData[RegistrationFormFields.emergencyContactName] as String,
      emergencyContactPhone:
          formData[RegistrationFormFields.emergencyContactPhone] as String,
      vehicleBrand: formData[RegistrationFormFields.vehicleBrand] as String,
      vehicleReference:
          formData[RegistrationFormFields.vehicleReference] as String,
      licensePlate: formData[RegistrationFormFields.licensePlate] as String,
      vin: formData[RegistrationFormFields.vin] as String?,
    );
  }

  RiderProfileModel _buildRiderProfile(EventRegistrationModel reg) {
    return RiderProfileModel(
      userId: reg.userId,
      firstName: reg.firstName,
      lastName: reg.lastName,
      identificationNumber: reg.identificationNumber,
      birthDate: reg.birthDate,
      phone: reg.phone,
      email: reg.email,
      residenceCity: reg.residenceCity,
      eps: reg.eps,
      medicalInsurance: reg.medicalInsurance,
      bloodType: reg.bloodType,
      emergencyContactName: reg.emergencyContactName,
      emergencyContactPhone: reg.emergencyContactPhone,
    );
  }
}
