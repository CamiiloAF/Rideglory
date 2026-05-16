import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/upload_event_image_request.dart';
import 'package:rideglory/features/events/domain/use_cases/create_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/get_generate_cover_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/upload_event_image_use_case.dart';
import 'package:rideglory/features/users/domain/use_cases/get_current_user_id_use_case.dart';

part 'event_form_cubit.freezed.dart';

@freezed
abstract class EventFormState with _$EventFormState {
  const factory EventFormState({
    @Default(ResultState<EventModel>.initial()) ResultState<EventModel> saveResult,
    @Default(ResultState<String>.initial()) ResultState<String> coverGenerationResult,
  }) = _EventFormState;
}

@injectable
class EventFormCubit extends Cubit<EventFormState> {
  EventFormCubit(
    this._createEventUseCase,
    this._updateEventUseCase,
    this._uploadEventImageUseCase,
    this._getCurrentUserIdUseCase,
    this._getGenerateCoverUseCase,
  ) : super(const EventFormState());

  final formKey = GlobalKey<FormBuilderState>();

  final CreateEventUseCase _createEventUseCase;
  final UpdateEventUseCase _updateEventUseCase;
  final UploadEventImageUseCase _uploadEventImageUseCase;
  final GetCurrentUserIdUseCase _getCurrentUserIdUseCase;
  final GetGenerateCoverUseCase _getGenerateCoverUseCase;

  EventModel? _editingEvent;

  bool get isEditing => _editingEvent != null;
  EventModel? get editingEvent => _editingEvent;

  void initialize({EventModel? event}) {
    _editingEvent = event;
    emit(const EventFormState());
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
      (error) =>
          emit(state.copyWith(saveResult: ResultState.error(error: error))),
      (event) =>
          emit(state.copyWith(saveResult: ResultState.data(data: event))),
    );
  }

  Future<void> generateCover({
    required String title,
    required String eventType,
    required String city,
  }) async {
    emit(
      state.copyWith(
        coverGenerationResult: const ResultState.loading(),
      ),
    );
    final result = await _getGenerateCoverUseCase(
      title: title,
      eventType: eventType,
      city: city,
    );
    result.fold(
      (error) => emit(
        state.copyWith(
          coverGenerationResult: ResultState.error(error: error),
        ),
      ),
      (imageUrl) => emit(
        state.copyWith(
          coverGenerationResult: ResultState.data(data: imageUrl),
        ),
      ),
    );
  }

  void resetCoverGeneration() {
    emit(
      state.copyWith(
        coverGenerationResult: const ResultState.initial(),
      ),
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

    final isFreeEvent = formData[EventFormFields.isFreeEvent] as bool? ?? false;
    final priceStr = formData[EventFormFields.price] as String?;
    final price = isFreeEvent
        ? null
        : (priceStr != null && priceStr.isNotEmpty
            ? int.tryParse(priceStr)
            : null);

    final maxParticipants =
        formData[EventFormFields.maxParticipants] as int?;

    return EventModel(
      id: _editingEvent?.id,
      ownerId: userId,
      name: formData[EventFormFields.name] as String,
      description: formData[EventFormFields.description] as String,
      city: formData[EventFormFields.city] as String,
      startDate: dateRange?.start ?? DateTime.now(),
      endDate: dateRange?.end != dateRange?.start ? dateRange?.end : null,
      difficulty: formData[EventFormFields.difficulty] as EventDifficulty,
      meetingPoint: formData[EventFormFields.meetingPoint] as String,
      destination: formData[EventFormFields.destination] as String,
      meetingTime: formData[EventFormFields.meetingTime] as DateTime,
      eventType: formData[EventFormFields.eventType] as EventType,
      allowedBrands: allowedBrands,
      price: price,
      maxParticipants: maxParticipants,
      imageUrl: _editingEvent?.imageUrl,
      state: _editingEvent?.state ?? EventState.scheduled,
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
}
