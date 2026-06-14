import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/upload_event_image_request.dart';
import 'package:rideglory/features/events/domain/use_cases/create_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/upload_event_image_use_case.dart';
import 'package:rideglory/features/users/domain/use_cases/get_current_user_id_use_case.dart';
import 'package:rideglory/shared/models/address_location.dart';

part 'event_form_cubit.freezed.dart';

@freezed
abstract class EventFormState with _$EventFormState {
  const factory EventFormState({
    @Default(ResultState<EventModel>.initial())
    ResultState<EventModel> saveResult,
    @Default(0) int currentStep,
    @Default(<String>[]) List<String> waypoints,
    @Default(<AddressLocation?>[]) List<AddressLocation?> waypointLocations,
    @Default(false) bool showRouteError,
  }) = _EventFormState;
}

@injectable
class EventFormCubit extends Cubit<EventFormState> {
  EventFormCubit(
    this._createEventUseCase,
    this._updateEventUseCase,
    this._uploadEventImageUseCase,
    this._getCurrentUserIdUseCase,
    this._analytics,
  ) : super(const EventFormState());

  final formKey = GlobalKey<FormBuilderState>();

  final CreateEventUseCase _createEventUseCase;
  final UpdateEventUseCase _updateEventUseCase;
  final UploadEventImageUseCase _uploadEventImageUseCase;
  final GetCurrentUserIdUseCase _getCurrentUserIdUseCase;
  final AnalyticsService _analytics;

  EventModel? _editingEvent;
  bool _terminalEventEmitted = false;

  bool get isEditing => _editingEvent != null;
  EventModel? get editingEvent => _editingEvent;

  static String _stepName(int index) =>
      const ['basics', 'config', 'route', 'review'][index.clamp(0, 3)];

  void initialize({EventModel? event}) {
    _editingEvent = event;

    _analytics.logEvent(AnalyticsEvents.eventsCreateStarted, {
      AnalyticsParams.formMode: event != null
          ? AnalyticsParams.formModeEdit
          : AnalyticsParams.formModeCreate,
    }).ignore();

    final routePoints = event?.routePoints ?? const [];
    final waypointLocations =
        routePoints.map<AddressLocation?>((p) => p).toList();

    emit(
      EventFormState(
        currentStep: event != null ? 3 : 0,
        waypoints: event?.waypoints ?? const [],
        waypointLocations: waypointLocations,
      ),
    );
  }

  void addWaypoint(String waypoint) {
    if (state.waypoints.length >= 9) return;
    emit(
      state.copyWith(
        waypoints: [...state.waypoints, waypoint],
        waypointLocations: [...state.waypointLocations, null],
      ),
    );
  }

  void setWaypointLocation(int index, AddressLocation? location) {
    if (index < 0 || index >= state.waypointLocations.length) return;
    final updated = List<AddressLocation?>.from(state.waypointLocations);
    updated[index] = location;
    emit(state.copyWith(waypointLocations: updated));
  }

  void removeWaypoint(int index) {
    if (index < 0 || index >= state.waypoints.length) return;
    final updatedWaypoints = List<String>.from(state.waypoints)
      ..removeAt(index);
    final updatedLocations = List<AddressLocation?>.from(
      state.waypointLocations,
    );
    if (index < updatedLocations.length) updatedLocations.removeAt(index);
    emit(
      state.copyWith(
        waypoints: updatedWaypoints,
        waypointLocations: updatedLocations,
      ),
    );
  }

  void clearWaypoints() {
    emit(state.copyWith(waypoints: const [], waypointLocations: const []));
  }

  Map<String, dynamic>? _buildRouteGeoJson() {
    final points = <Map<String, dynamic>>[];
    for (var i = 0; i < state.waypoints.length; i++) {
      final loc = i < state.waypointLocations.length
          ? state.waypointLocations[i]
          : null;
      if (loc != null) {
        points.add({
          'lat': loc.latitude,
          'lng': loc.longitude,
          'label': state.waypoints[i],
        });
      }
    }
    if (points.isEmpty) return null;
    return {'routeType': 'custom', 'points': points};
  }

  Future<void> saveEvent(
    EventModel eventToSave, {
    String? localCoverImagePath,
    String? remoteCoverImageUrl,
  }) async {
    _analytics.logEvent(AnalyticsEvents.eventsPublishAttempted, {
      AnalyticsParams.formMode: isEditing
          ? AnalyticsParams.formModeEdit
          : AnalyticsParams.formModeCreate,
    }).ignore();
    emit(state.copyWith(saveResult: const ResultState.loading()));

    final result = isEditing
        ? await _saveExistingEvent(
            eventToSave,
            localCoverImagePath: localCoverImagePath,
            remoteCoverImageUrl: remoteCoverImageUrl,
          )
        : await _createNewEvent(
            eventToSave,
            localCoverImagePath: localCoverImagePath,
            remoteCoverImageUrl: remoteCoverImageUrl,
          );

    result.fold(
      (error) {
        _analytics.logEvent(AnalyticsEvents.eventsPublishFailed, {
          AnalyticsParams.formMode: isEditing
              ? AnalyticsParams.formModeEdit
              : AnalyticsParams.formModeCreate,
          AnalyticsParams.failureCategory: _categorizeFailure(error),
        }).ignore();
        emit(state.copyWith(saveResult: ResultState.error(error: error)));
      },
      (event) {
        _terminalEventEmitted = true;
        _analytics.logEvent(AnalyticsEvents.eventsPublished, {
          AnalyticsParams.formMode: isEditing
              ? AnalyticsParams.formModeEdit
              : AnalyticsParams.formModeCreate,
        }).ignore();
        emit(state.copyWith(saveResult: ResultState.data(data: event)));
      },
    );
  }

  Future<Either<DomainException, EventModel>> _saveExistingEvent(
    EventModel eventToSave, {
    String? localCoverImagePath,
    String? remoteCoverImageUrl,
  }) async {
    final eventId = eventToSave.id;
    if (eventId == null) {
      return const Left(
        DomainException(message: 'Event ID is required for update.'),
      );
    }

    if (localCoverImagePath != null) {
      final uploadResult = await _uploadEventImageUseCase(
        UploadEventImageRequest(
          eventId: eventId,
          localImagePath: localCoverImagePath,
        ),
      );
      return uploadResult.fold(
        Left.new,
        (imageUrl) =>
            _updateEventUseCase(eventToSave.copyWith(imageUrl: imageUrl)),
      );
    }

    if (remoteCoverImageUrl != null) {
      return _updateEventUseCase(
        eventToSave.copyWith(imageUrl: remoteCoverImageUrl),
      );
    }

    return _updateEventUseCase(eventToSave);
  }

  Future<Either<DomainException, EventModel>> _createNewEvent(
    EventModel eventToSave, {
    String? localCoverImagePath,
    String? remoteCoverImageUrl,
  }) async {
    if (localCoverImagePath != null) {
      final uploadResult = await _uploadEventImageUseCase(
        UploadEventImageRequest(
          ownerId: eventToSave.ownerId,
          localImagePath: localCoverImagePath,
        ),
      );
      return uploadResult.fold(
        Left.new,
        (imageUrl) =>
            _createEventUseCase(eventToSave.copyWith(imageUrl: imageUrl)),
      );
    }

    if (remoteCoverImageUrl != null) {
      return _createEventUseCase(
        eventToSave.copyWith(imageUrl: remoteCoverImageUrl),
      );
    }

    return _createEventUseCase(eventToSave);
  }

  Future<EventModel?> buildEventToSave() async {
    if (!(formKey.currentState?.saveAndValidate() ?? false)) return null;

    final formData = formKey.currentState!.value;
    final userId = await _resolveOwnerId();
    if (userId == null) return null;

    final dateRange = formData[EventFormFields.dateRange] as DateTimeRange?;

    final allowedBrands =
        formData[EventFormFields.allowedBrands] as List<String>? ?? <String>[];

    final priceStr = formData[EventFormFields.price] as String?;
    final parsedPrice = priceStr != null && priceStr.isNotEmpty
        ? int.tryParse(priceStr)
        : null;
    final price = (parsedPrice == null || parsedPrice == 0)
        ? null
        : parsedPrice;

    final maxParticipants = formData[EventFormFields.maxParticipants] as int?;

    return EventModel(
      id: _editingEvent?.id,
      ownerId: userId,
      name: formData[EventFormFields.name] as String,
      description:
          (formData[EventFormFields.description] as String?)?.trim() ?? '',
      startDate: dateRange?.start ?? DateTime.now(),
      endDate: dateRange?.end != dateRange?.start ? dateRange?.end : null,
      difficulty: formData[EventFormFields.difficulty] as EventDifficulty,
      meetingTime: formData[EventFormFields.meetingTime] as DateTime,
      eventType: formData[EventFormFields.eventType] as EventType,
      allowedBrands: allowedBrands,
      price: price,
      maxParticipants: maxParticipants,
      imageUrl: _editingEvent?.imageUrl,
      state: _editingEvent?.state ?? EventState.scheduled,
      waypoints: state.waypoints,
      routeGeoJson: _buildRouteGeoJson(),
    );
  }

  Future<EventModel?> buildDraftToSave() async {
    formKey.currentState?.save();
    final formData = formKey.currentState?.value ?? {};

    final name = formData[EventFormFields.name] as String?;
    if (name == null || name.trim().isEmpty) {
      emit(
        state.copyWith(
          saveResult: const ResultState.error(
            error: DomainException(
              message:
                  'El nombre del evento es requerido para guardar el borrador.',
            ),
          ),
        ),
      );
      return null;
    }

    final userId = await _resolveOwnerId();
    if (userId == null) return null;

    final dateRange = formData[EventFormFields.dateRange] as DateTimeRange?;
    final now = DateTime.now();

    final allowedBrands =
        formData[EventFormFields.allowedBrands] as List<String>? ?? <String>[];

    final priceStr = formData[EventFormFields.price] as String?;
    final parsedPrice = priceStr != null && priceStr.isNotEmpty
        ? int.tryParse(priceStr)
        : null;
    final price = (parsedPrice == null || parsedPrice == 0)
        ? null
        : parsedPrice;

    final maxParticipants = formData[EventFormFields.maxParticipants] as int?;

    return EventModel(
      id: _editingEvent?.id,
      ownerId: userId,
      name: name.trim(),
      description:
          (formData[EventFormFields.description] as String?)?.trim() ?? '',
      startDate: dateRange?.start ?? now,
      endDate: dateRange?.end != dateRange?.start ? dateRange?.end : null,
      difficulty:
          formData[EventFormFields.difficulty] as EventDifficulty? ??
          EventDifficulty.one,
      meetingTime: formData[EventFormFields.meetingTime] as DateTime? ?? now,
      eventType:
          formData[EventFormFields.eventType] as EventType? ??
          EventType.onRoad,
      allowedBrands: allowedBrands,
      price: price,
      maxParticipants: maxParticipants,
      imageUrl: _editingEvent?.imageUrl,
      state: EventState.draft,
      waypoints: state.waypoints,
      routeGeoJson: _buildRouteGeoJson(),
    );
  }

  Future<void> saveDraft({
    String? localCoverImagePath,
    String? remoteCoverImageUrl,
  }) async {
    emit(state.copyWith(saveResult: const ResultState.loading()));

    final eventToSave = await buildDraftToSave();
    if (eventToSave == null) return;

    final result = isEditing
        ? await _saveExistingEvent(
            eventToSave,
            localCoverImagePath: localCoverImagePath,
            remoteCoverImageUrl: remoteCoverImageUrl,
          )
        : await _createNewEvent(
            eventToSave,
            localCoverImagePath: localCoverImagePath,
            remoteCoverImageUrl: remoteCoverImageUrl,
          );

    result.fold(
      (error) =>
          emit(state.copyWith(saveResult: ResultState.error(error: error))),
      (event) {
        _terminalEventEmitted = true;
        _analytics.logEvent(AnalyticsEvents.eventsDraftSaved, {
          AnalyticsParams.formMode: isEditing
              ? AnalyticsParams.formModeEdit
              : AnalyticsParams.formModeCreate,
        }).ignore();
        emit(state.copyWith(saveResult: ResultState.data(data: event)));
      },
    );
  }

  Future<String?> _resolveOwnerId() async {
    if (_editingEvent?.ownerId != null) {
      return _editingEvent!.ownerId;
    }

    final result = await _getCurrentUserIdUseCase();
    return result.fold((error) {
      emit(state.copyWith(saveResult: ResultState.error(error: error)));
      return null;
    }, (userId) => userId);
  }

  // ---------------------------------------------------------------------------
  // Step navigation
  // ---------------------------------------------------------------------------

  static const List<String> _step1Fields = [
    EventFormFields.name,
    EventFormFields.dateRange,
    EventFormFields.meetingTime,
    EventFormFields.difficulty,
    EventFormFields.eventType,
  ];

  static const List<String> _step2Fields = [
    EventFormFields.description,
  ];

  static const List<String> _step3Fields = [
    EventFormFields.price,
    EventFormFields.maxParticipants,
  ];

  static const Map<int, List<String>> stepFields = {
    0: _step1Fields,
    1: _step2Fields,
    2: _step3Fields,
  };

  void nextStep() {
    final next = state.currentStep + 1;
    if (next > 3) return;
    _analytics.logEvent(AnalyticsEvents.eventsStepAdvanced, {
      AnalyticsParams.stepIndex: next,
      AnalyticsParams.stepName: _stepName(next),
    }).ignore();
    emit(state.copyWith(currentStep: next));
  }

  void prevStep() {
    final prev = state.currentStep - 1;
    if (prev < 0) return;
    _analytics.logEvent(AnalyticsEvents.eventsStepBack, {
      AnalyticsParams.stepIndex: prev,
      AnalyticsParams.stepName: _stepName(prev),
    }).ignore();
    emit(state.copyWith(currentStep: prev));
  }

  @override
  Future<void> close() {
    if (!_terminalEventEmitted) {
      _analytics.logEvent(AnalyticsEvents.eventsCreateAbandoned, {
        AnalyticsParams.formMode: isEditing
            ? AnalyticsParams.formModeEdit
            : AnalyticsParams.formModeCreate,
        AnalyticsParams.abandonedAtStep: state.currentStep,
      }).ignore();
    }
    return super.close();
  }

  void goToStep(int step) {
    assert(step >= 0 && step <= 3, 'step must be between 0 and 3');
    emit(state.copyWith(currentStep: step));
  }

  bool validateStep(int step) {
    final fields = stepFields[step];
    final formValid = fields == null ||
        fields.every(
          (name) => formKey.currentState?.fields[name]?.validate() ?? true,
        );

    if (step == 2) {
      final hasRoute = state.waypoints.isNotEmpty;
      if (!hasRoute) {
        emit(state.copyWith(showRouteError: true));
        return false;
      }
      if (state.showRouteError) {
        emit(state.copyWith(showRouteError: false));
      }
    }

    return formValid;
  }

  bool isCurrentStepValid() => validateStep(state.currentStep);

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Maps a [DomainException] to a non-PII failure category string.
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
}
