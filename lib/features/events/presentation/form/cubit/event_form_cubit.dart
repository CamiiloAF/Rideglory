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
    @Default(<String>[]) List<String> waypoints,
    @Default(<AddressLocation?>[]) List<AddressLocation?> waypointLocations,
    @Default(RouteType.simple) RouteType routeType,
    String? meetingPointName,
    String? destinationName,
    AddressLocation? meetingPointLocation,
    AddressLocation? destinationLocation,
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

  bool get isEditing => _editingEvent != null;
  EventModel? get editingEvent => _editingEvent;

  void initialize({EventModel? event}) {
    _editingEvent = event;

    _analytics.logEvent(AnalyticsEvents.eventsCreateStarted, {
      AnalyticsParams.formMode: event != null
          ? AnalyticsParams.formModeEdit
          : AnalyticsParams.formModeCreate,
    }).ignore();

    final routeType = _detectRouteType(event);
    final routePoints = event?.routePoints ?? const [];

    AddressLocation? meetingPointLocation;
    AddressLocation? destinationLocation;
    List<AddressLocation?> waypointLocations = const [];

    if (routeType == RouteType.simple) {
      if (routePoints.isNotEmpty) meetingPointLocation = routePoints[0];
      if (routePoints.length >= 2) destinationLocation = routePoints[1];
    } else {
      waypointLocations = routePoints.map<AddressLocation?>((p) => p).toList();
    }

    emit(
      EventFormState(
        waypoints: event?.waypoints ?? const [],
        meetingPointName: event?.meetingPoint,
        destinationName: event?.destination,
        routeType: routeType,
        meetingPointLocation: meetingPointLocation,
        destinationLocation: destinationLocation,
        waypointLocations: waypointLocations,
      ),
    );
  }

  RouteType _detectRouteType(EventModel? event) {
    if (event == null) return RouteType.simple;
    if (event.waypoints.isNotEmpty) return RouteType.custom;
    final geoJson = event.routeGeoJson;
    if (geoJson != null && geoJson['routeType'] == 'custom') {
      return RouteType.custom;
    }
    return RouteType.simple;
  }

  void setRoute({
    required String meetingPointName,
    required String destinationName,
    AddressLocation? meetingPointLocation,
    AddressLocation? destinationLocation,
  }) {
    emit(
      state.copyWith(
        meetingPointName: meetingPointName,
        destinationName: destinationName,
        meetingPointLocation: meetingPointLocation,
        destinationLocation: destinationLocation,
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

  void setRouteType(RouteType type) {
    emit(state.copyWith(routeType: type));
  }

  void clearWaypoints() {
    emit(state.copyWith(waypoints: const [], waypointLocations: const []));
  }

  Map<String, dynamic>? _buildRouteGeoJson(RouteType routeType) {
    final points = <Map<String, dynamic>>[];
    if (routeType == RouteType.simple) {
      final mp = state.meetingPointLocation;
      final dest = state.destinationLocation;
      if (mp != null) {
        points.add({
          'lat': mp.latitude,
          'lng': mp.longitude,
          'label': state.meetingPointName ?? '',
        });
      }
      if (dest != null) {
        points.add({
          'lat': dest.latitude,
          'lng': dest.longitude,
          'label': state.destinationName ?? '',
        });
      }
    } else {
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
    }
    if (points.isEmpty) return null;
    return {
      'routeType': routeType == RouteType.simple ? 'simple' : 'custom',
      'points': points,
    };
  }

  Future<void> saveEvent(
    EventModel eventToSave, {
    String? localCoverImagePath,
    String? remoteCoverImageUrl,
  }) async {
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

    final isMultiBrand =
        formData[EventFormFields.isMultiBrand] as bool? ?? true;
    final allowedBrands = isMultiBrand
        ? <String>[]
        : (formData[EventFormFields.allowedBrands] as List<String>? ??
              <String>[]);

    final priceStr = formData[EventFormFields.price] as String?;
    final parsedPrice = priceStr != null && priceStr.isNotEmpty
        ? int.tryParse(priceStr)
        : null;
    final price = (parsedPrice == null || parsedPrice == 0)
        ? null
        : parsedPrice;

    final maxParticipants = formData[EventFormFields.maxParticipants] as int?;

    final routeType =
        formData[EventFormFields.routeType] as RouteType? ?? state.routeType;
    final waypointsToSave = routeType == RouteType.custom
        ? state.waypoints
        : const <String>[];

    return EventModel(
      id: _editingEvent?.id,
      ownerId: userId,
      name: formData[EventFormFields.name] as String,
      description: formData[EventFormFields.description] as String,
      city: formData[EventFormFields.city] as String,
      startDate: dateRange?.start ?? DateTime.now(),
      endDate: dateRange?.end != dateRange?.start ? dateRange?.end : null,
      difficulty: formData[EventFormFields.difficulty] as EventDifficulty,
      meetingPoint: state.meetingPointName ?? '',
      destination: state.destinationName ?? '',
      meetingTime: formData[EventFormFields.meetingTime] as DateTime,
      eventType: formData[EventFormFields.eventType] as EventType,
      allowedBrands: allowedBrands,
      price: price,
      maxParticipants: maxParticipants,
      imageUrl: _editingEvent?.imageUrl,
      state: _editingEvent?.state ?? EventState.scheduled,
      waypoints: waypointsToSave,
      routeGeoJson: _buildRouteGeoJson(routeType),
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

    final isMultiBrand =
        formData[EventFormFields.isMultiBrand] as bool? ?? true;
    final allowedBrands = isMultiBrand
        ? <String>[]
        : (formData[EventFormFields.allowedBrands] as List<String>? ??
              <String>[]);

    final priceStr = formData[EventFormFields.price] as String?;
    final parsedPrice = priceStr != null && priceStr.isNotEmpty
        ? int.tryParse(priceStr)
        : null;
    // Price of 0 or empty means free — no price stored.
    final price = (parsedPrice == null || parsedPrice == 0)
        ? null
        : parsedPrice;

    final maxParticipants = formData[EventFormFields.maxParticipants] as int?;

    final routeType =
        formData[EventFormFields.routeType] as RouteType? ?? state.routeType;
    final waypointsToSave = routeType == RouteType.custom
        ? state.waypoints
        : const <String>[];

    return EventModel(
      id: _editingEvent?.id,
      ownerId: userId,
      name: name.trim(),
      description:
          (formData[EventFormFields.description] as String?)?.trim() ?? '',
      city: (formData[EventFormFields.city] as String?)?.trim() ?? '',
      startDate: dateRange?.start ?? now,
      endDate: dateRange?.end != dateRange?.start ? dateRange?.end : null,
      difficulty:
          formData[EventFormFields.difficulty] as EventDifficulty? ??
          EventDifficulty.one,
      meetingPoint: state.meetingPointName?.trim() ?? '',
      destination: state.destinationName?.trim() ?? '',
      meetingTime: formData[EventFormFields.meetingTime] as DateTime? ?? now,
      eventType:
          formData[EventFormFields.eventType] as EventType? ??
          EventType.tourism,
      allowedBrands: allowedBrands,
      price: price,
      maxParticipants: maxParticipants,
      imageUrl: _editingEvent?.imageUrl,
      state: EventState.draft,
      waypoints: waypointsToSave,
      routeGeoJson: _buildRouteGeoJson(routeType),
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
