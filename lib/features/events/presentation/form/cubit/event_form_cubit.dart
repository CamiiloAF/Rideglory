import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/domain/result_state.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/add_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';

@injectable
class EventFormCubit extends Cubit<ResultState<EventModel>> {
  EventFormCubit(
    this._addEventUseCase,
    this._updateEventUseCase,
    this._authService,
  ) : super(const ResultState.initial());

  final formKey = GlobalKey<FormBuilderState>();

  final AddEventUseCase _addEventUseCase;
  final UpdateEventUseCase _updateEventUseCase;
  final AuthService _authService;

  EventModel? _editingEvent;

  bool get isEditing => _editingEvent != null;
  EventModel? get editingEvent => _editingEvent;

  void initialize({EventModel? event}) {
    _editingEvent = event;
    emit(const ResultState.initial());
  }

  Future<void> saveEvent(EventModel eventToSave) async {
    emit(const ResultState.loading());

    final result = isEditing
        ? await _updateEventUseCase(eventToSave)
        : await _addEventUseCase(eventToSave);

    result.fold(
      (error) => emit(ResultState.error(error: error)),
      (event) => emit(ResultState.data(data: event)),
    );
  }

  EventModel? buildEventToSave() {
    if (!(formKey.currentState?.saveAndValidate() ?? false)) return null;

    final formData = formKey.currentState!.value;
    final userId = _authService.currentUser?.uid ?? '';

    final dateRange = formData[EventFormFields.dateRange] as DateTimeRange?;

    final allowedBrands =
        formData[EventFormFields.allowedBrands] as List<String>? ?? <String>[];

    final priceStr = formData[EventFormFields.price] as String?;
    final price = priceStr != null && priceStr.isNotEmpty
        ? int.tryParse(priceStr)
        : null;

    return EventModel(
      id: _editingEvent?.id,
      ownerId: _editingEvent?.ownerId ?? userId,
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
      recommendations: formData[EventFormFields.recommendations] as String?,
    );
  }
}
