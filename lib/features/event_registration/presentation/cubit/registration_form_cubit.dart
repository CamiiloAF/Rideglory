import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/event_registration/constants/registration_form_fields.dart';
import 'package:rideglory/features/event_registration/domain/model/event_registration_model.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/add_event_registration_use_case.dart';
import 'package:rideglory/features/event_registration/domain/use_cases/update_event_registration_use_case.dart';
import 'package:rideglory/features/events/domain/model/rider_profile_model.dart';
import 'package:rideglory/features/events/domain/use_cases/get_rider_profile_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/save_rider_profile_use_case.dart';

@injectable
class RegistrationFormCubit extends Cubit<ResultState<EventRegistrationModel>> {
  RegistrationFormCubit(
    this._addRegistrationUseCase,
    this._updateRegistrationUseCase,
    this._getRiderProfileUseCase,
    this._saveRiderProfileUseCase,
    this._authService,
    this._analytics,
  ) : super(const ResultState.initial());

  final formKey = GlobalKey<FormBuilderState>();

  final AddEventRegistrationUseCase _addRegistrationUseCase;
  final UpdateEventRegistrationUseCase _updateRegistrationUseCase;
  final GetRiderProfileUseCase _getRiderProfileUseCase;
  final SaveRiderProfileUseCase _saveRiderProfileUseCase;
  final AuthService _authService;
  final AnalyticsService _analytics;

  String? _eventId;
  String? _eventName;
  EventRegistrationModel? _editingRegistration;
  RiderProfileModel? _riderProfile;
  bool _saveToProfile = false;
  bool _preloadedFromProfile = false;
  bool _terminalEventEmitted = false;

  bool get isEditing => _editingRegistration != null;
  bool get saveToProfile => _saveToProfile;
  bool get isPreloadedFromProfile => _preloadedFromProfile;

  /// Marks the terminal analytics event as already emitted.
  /// Only for use in tests that need to verify the idempotent [close()] behavior
  /// but cannot drive a successful [saveRegistration()] without a real
  /// [FormBuilderState] in a widget tree.
  @visibleForTesting
  void markTerminalEventEmittedForTesting() {
    _terminalEventEmitted = true;
  }

  /// Unit-test seam: when non-null, [_buildRegistration] returns its result
  /// instead of reading from the widget-bound [FormBuilderState].
  ///
  /// Allows unit tests to exercise the positive path of [saveRegistration]
  /// (including [AnalyticsEvents.registrationSubmitAttempted] intent and the
  /// `_terminalEventEmitted = true` assignment on success) without a real
  /// widget tree. NEVER set from production code.
  @visibleForTesting
  EventRegistrationModel? Function()? buildRegistrationOverride;

  void toggleSaveToProfile([bool? value]) {
    _saveToProfile = value ?? !_saveToProfile;
  }

  /// Emite [registrationStarted] al abrir el wizard de inscripción.
  void onWizardStarted() {
    _analytics.logEvent(AnalyticsEvents.registrationStarted).ignore();
  }

  /// Emite [registrationStepAdvanced] cuando el rider avanza al siguiente paso.
  /// [stepIndex] es el índice del paso al que se navega (0-based).
  /// [stepName] es el nombre canónico del paso destino.
  void onStepAdvanced(int stepIndex, String stepName) {
    _analytics.logEvent(AnalyticsEvents.registrationStepAdvanced, {
      AnalyticsParams.stepIndex: stepIndex,
      AnalyticsParams.stepName: stepName,
    }).ignore();
  }

  /// Emite [registrationStepBack] cuando el rider retrocede al paso anterior.
  /// [stepIndex] es el índice del paso al que se regresa (0-based).
  /// [stepName] es el nombre canónico del paso destino.
  void onStepBack(int stepIndex, String stepName) {
    _analytics.logEvent(AnalyticsEvents.registrationStepBack, {
      AnalyticsParams.stepIndex: stepIndex,
      AnalyticsParams.stepName: stepName,
    }).ignore();
  }

  void initialize({
    required String eventId,
    required String eventName,
    EventRegistrationModel? existingRegistration,
  }) {
    _eventId = eventId;
    _eventName = eventName;
    _editingRegistration = existingRegistration;

    if (existingRegistration != null) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _preloadFromExistingRegistration(existingRegistration);
      });
    }

    emit(const ResultState.initial());
    if (existingRegistration == null) {
      Future<void>.delayed(const Duration(milliseconds: 50), () {
        _prefillFromAuthenticatedUser();
      });
    }
    _loadRiderProfile();
  }

  void _preloadFromExistingRegistration(
    EventRegistrationModel? existingRegistration,
  ) {
    if (existingRegistration == null) {
      return;
    }
    formKey.currentState?.patchValue({
      RegistrationFormFields.fullName: existingRegistration.fullName,
      RegistrationFormFields.identificationNumber:
          existingRegistration.identificationNumber,
      RegistrationFormFields.birthDate: existingRegistration.birthDate,
      RegistrationFormFields.phone: existingRegistration.phone,
      RegistrationFormFields.email: existingRegistration.email,
      RegistrationFormFields.residenceCity: existingRegistration.residenceCity,
      RegistrationFormFields.eps: existingRegistration.eps,
      if (existingRegistration.medicalInsurance != null)
        RegistrationFormFields.medicalInsurance:
            existingRegistration.medicalInsurance,
      RegistrationFormFields.bloodType: existingRegistration.bloodType,
      RegistrationFormFields.emergencyContactName:
          existingRegistration.emergencyContactName,
      RegistrationFormFields.emergencyContactPhone:
          existingRegistration.emergencyContactPhone,
      if (existingRegistration.vehicleId != null)
        RegistrationFormFields.vehicleId: existingRegistration.vehicleId,
      RegistrationFormFields.shareMedicalInfo:
          existingRegistration.shareMedicalInfo,
      RegistrationFormFields.allowOrganizerContact:
          existingRegistration.allowOrganizerContact,
    });
  }

  Future<void> _loadRiderProfile() async {
    final result = await _getRiderProfileUseCase();
    result.fold((_) {}, (profile) {
      _riderProfile = profile;
      if (_editingRegistration != null) {
        return;
      }
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        preloadFromRiderProfile();
      });
    });
  }

  /// Clears all registration fields (create mode only). Rider profile cache is kept.
  void resetFormToEmpty() {
    if (isEditing) {
      return;
    }
    _saveToProfile = false;
    formKey.currentState?.reset();
  }

  void _prefillFromAuthenticatedUser() {
    final user = _authService.currentUser;
    if (user == null) {
      return;
    }
    formKey.currentState?.patchValue({
      if (user.fullName.isNotBlank)
        RegistrationFormFields.fullName: user.fullName!.trim(),
      if (user.identificationNumber.isNotBlank)
        RegistrationFormFields.identificationNumber: user.identificationNumber,
      if (user.birthDate != null)
        RegistrationFormFields.birthDate: user.birthDate,
      if (user.phone.isNotBlank) RegistrationFormFields.phone: user.phone,
      if (user.email.isNotBlank) RegistrationFormFields.email: user.email,
      if (user.residenceCity.isNotBlank)
        RegistrationFormFields.residenceCity: user.residenceCity,
      if (user.eps.isNotBlank) RegistrationFormFields.eps: user.eps,
      if (user.medicalInsurance.isNotBlank)
        RegistrationFormFields.medicalInsurance: user.medicalInsurance,
      if (user.bloodType != null)
        RegistrationFormFields.bloodType: user.bloodType,
      if (user.emergencyContactName.isNotBlank)
        RegistrationFormFields.emergencyContactName: user.emergencyContactName,
      if (user.emergencyContactPhone.isNotBlank)
        RegistrationFormFields.emergencyContactPhone:
            user.emergencyContactPhone,
    });
  }

  void preloadFromRiderProfile() {
    if (_riderProfile == null) return;
    final profile = _riderProfile!;
    _preloadedFromProfile = true;
    emit(const ResultState.initial());
    formKey.currentState?.patchValue({
      if (profile.fullName.isNotBlank)
        RegistrationFormFields.fullName: profile.fullName,
      if (profile.identificationNumber.isNotBlank)
        RegistrationFormFields.identificationNumber:
            profile.identificationNumber,
      if (profile.birthDate != null)
        RegistrationFormFields.birthDate: profile.birthDate,
      if (profile.phone.isNotBlank) RegistrationFormFields.phone: profile.phone,
      if (profile.email.isNotBlank) RegistrationFormFields.email: profile.email,
      if (profile.residenceCity.isNotBlank)
        RegistrationFormFields.residenceCity: profile.residenceCity,
      if (profile.eps.isNotBlank) RegistrationFormFields.eps: profile.eps,
      if (profile.medicalInsurance.isNotBlank)
        RegistrationFormFields.medicalInsurance: profile.medicalInsurance,
      if (profile.bloodType != null)
        RegistrationFormFields.bloodType: profile.bloodType,
      if (profile.emergencyContactName.isNotBlank)
        RegistrationFormFields.emergencyContactName:
            profile.emergencyContactName,
      if (profile.emergencyContactPhone.isNotBlank)
        RegistrationFormFields.emergencyContactPhone:
            profile.emergencyContactPhone,
    });
  }

  /// Validates only the given field names (one wizard step). Returns true when
  /// every field passes. Validating a single field also surfaces its error UI.
  bool validateStepFields(List<String> fieldNames) {
    final formState = formKey.currentState;
    if (formState == null) return false;
    var isValid = true;
    for (final fieldName in fieldNames) {
      final fieldValidates = formState.fields[fieldName]?.validate() ?? true;
      isValid = isValid && fieldValidates;
    }
    return isValid;
  }

  Future<void> saveRegistration() async {
    final registration = _buildRegistration();

    if (registration == null) return;

    _analytics.logEvent(AnalyticsEvents.registrationSubmitAttempted, {
      AnalyticsParams.formMode: isEditing
          ? AnalyticsParams.formModeEdit
          : AnalyticsParams.formModeCreate,
    }).ignore();
    emit(const ResultState.loading());

    final result = isEditing
        ? await _updateRegistrationUseCase(
            registration.copyWith(),
            saveToProfile: _saveToProfile,
          )
        : await _addRegistrationUseCase(
            registration,
            saveToProfile: _saveToProfile,
          );

    result.fold(
      (error) {
        _analytics.logEvent(AnalyticsEvents.registrationSubmitFailed, {
          AnalyticsParams.formMode: isEditing
              ? AnalyticsParams.formModeEdit
              : AnalyticsParams.formModeCreate,
          AnalyticsParams.failureCategory: _categorizeFailure(error),
        }).ignore();
        emit(ResultState.error(error: error));
      },
      (saved) async {
        _terminalEventEmitted = true;
        _analytics.logEvent(AnalyticsEvents.registrationSubmitted, {
          AnalyticsParams.formMode: isEditing
              ? AnalyticsParams.formModeEdit
              : AnalyticsParams.formModeCreate,
        }).ignore();
        if (_saveToProfile) {
          await _saveRiderProfileUseCase(_buildRiderProfile(registration));
        }
        emit(ResultState.data(data: saved));
      },
    );
  }

  String _categorizeFailure(DomainException error) {
    final msg = error.message.toLowerCase();
    if (msg.contains('network') ||
        msg.contains('timeout') ||
        msg.contains('connection') ||
        msg.contains('socket')) {
      return AnalyticsParams.failureCategoryNetwork;
    }
    if (msg.contains('404') || msg.contains('not found')) {
      return AnalyticsParams.failureCategoryNotFound;
    }
    if (msg.contains('valid') || msg.contains('required')) {
      return AnalyticsParams.failureCategoryValidation;
    }
    return AnalyticsParams.failureCategoryUnknown;
  }

  EventRegistrationModel? _buildRegistration() {
    // Unit-test seam: bypasses the widget-bound FormBuilderState.
    if (buildRegistrationOverride != null) return buildRegistrationOverride!();
    if (!(formKey.currentState?.saveAndValidate() ?? false)) return null;

    final formData = formKey.currentState!.value;
    final userId = _authService.currentUser?.id ?? '';

    return EventRegistrationModel(
      id: _editingRegistration?.id,
      eventId: _eventId ?? '',
      eventName: _eventName ?? '',
      userId: userId,
      fullName: formData[RegistrationFormFields.fullName] as String,
      identificationNumber:
          formData[RegistrationFormFields.identificationNumber] as String,
      birthDate: formData[RegistrationFormFields.birthDate] as DateTime,
      phone: formData[RegistrationFormFields.phone] as String,
      email: formData[RegistrationFormFields.email] as String,
      residenceCity: formData[RegistrationFormFields.residenceCity] as String,
      eps: formData[RegistrationFormFields.eps] as String,
      medicalInsurance:
          formData[RegistrationFormFields.medicalInsurance] as String?,
      bloodType: formData[RegistrationFormFields.bloodType] as BloodType?,
      emergencyContactName:
          formData[RegistrationFormFields.emergencyContactName] as String,
      emergencyContactPhone:
          formData[RegistrationFormFields.emergencyContactPhone] as String,
      vehicleId: formData[RegistrationFormFields.vehicleId] as String?,
    );
  }

  RiderProfileModel _buildRiderProfile(EventRegistrationModel reg) {
    return RiderProfileModel(
      userId: reg.userId,
      fullName: reg.fullName,
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

  @override
  Future<void> close() {
    if (!_terminalEventEmitted) {
      _analytics.logEvent(AnalyticsEvents.registrationAbandoned).ignore();
    }
    return super.close();
  }
}

/// True when non-null, not empty, and not only whitespace.
extension _NullableStringIsNotBlank on String? {
  bool get isNotBlank => this != null && this!.trim().isNotEmpty;
}
