import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/exceptions/domain_exception.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/model/upload_event_image_request.dart';
import 'package:rideglory/features/events/domain/use_cases/create_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/upload_event_image_use_case.dart';
import 'package:rideglory/features/users/domain/use_cases/get_current_user_id_use_case.dart';

@injectable
class EventFormCubit extends Cubit<ResultState<EventModel>> {
  EventFormCubit(
    this._createEventUseCase,
    this._updateEventUseCase,
    this._uploadEventImageUseCase,
    this._getCurrentUserIdUseCase,
  ) : super(const ResultState.initial());

  final formKey = GlobalKey<FormBuilderState>();

  final CreateEventUseCase _createEventUseCase;
  final UpdateEventUseCase _updateEventUseCase;
  final UploadEventImageUseCase _uploadEventImageUseCase;
  final GetCurrentUserIdUseCase _getCurrentUserIdUseCase;

  EventModel? _editingEvent;

  bool get isEditing => _editingEvent != null;
  EventModel? get editingEvent => _editingEvent;

  void initialize({EventModel? event}) {
    _editingEvent = event;
    emit(const ResultState.initial());
  }

  Future<void> saveEvent(
    EventModel eventToSave, {
    String? localCoverImagePath,
  }) async {
    emit(const ResultState.loading());

    final result = isEditing
        ? await _saveExistingEvent(
            eventToSave,
            localCoverImagePath: localCoverImagePath,
          )
        : await _createNewEvent(
            eventToSave,
            localCoverImagePath: localCoverImagePath,
          );

    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (event) => emit(ResultState.data(data: event)),
    );
  }

  Future<Either<DomainException, EventModel>> _saveExistingEvent(
    EventModel eventToSave, {
    String? localCoverImagePath,
  }) async {
    if (localCoverImagePath == null) {
      return _updateEventUseCase(eventToSave);
    }

    final eventId = eventToSave.id;
    if (eventId == null) {
      return const Left(
        DomainException(message: 'Event ID is required for update.'),
      );
    }

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

  Future<Either<DomainException, EventModel>> _createNewEvent(
    EventModel eventToSave, {
    String? localCoverImagePath,
  }) async {
    if (localCoverImagePath == null) {
      return _createEventUseCase(eventToSave);
    }

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
    final price = priceStr != null && priceStr.isNotEmpty
        ? int.tryParse(priceStr)
        : null;

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
      emit(ResultState.error(error: error));
      return null;
    }, (userId) => userId);
  }
}
