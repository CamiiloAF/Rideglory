import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/events/constants/event_form_fields.dart';
import 'package:rideglory/features/events/domain/model/event_model.dart';
import 'package:rideglory/features/events/domain/use_cases/add_event_use_case.dart';
import 'package:rideglory/features/events/domain/use_cases/update_event_use_case.dart';

part 'event_form_cubit.freezed.dart';
part 'event_form_state.dart';

@injectable
class EventFormCubit extends Cubit<EventFormState> {
  EventFormCubit(
    this._addEventUseCase,
    this._updateEventUseCase,
    this._authService,
  ) : super(const EventFormState.initial());

  final formKey = GlobalKey<FormBuilderState>();

  final AddEventUseCase _addEventUseCase;
  final UpdateEventUseCase _updateEventUseCase;
  final AuthService _authService;

  void initialize({EventModel? event}) {
    if (event != null) {
      emit(EventFormState.editing(event: event));
    } else {
      emit(const EventFormState.initial());
    }
  }

  Future<void> saveEvent(EventModel eventToSave) async {
    emit(const EventFormState.loading());

    final result = await state.maybeWhen(
      editing: (_) async => await _updateEventUseCase(eventToSave),
      orElse: () async => await _addEventUseCase(eventToSave),
    );

    result.fold(
      (error) => emit(EventFormState.error(message: error.message)),
      (event) => emit(EventFormState.success(event: event)),
    );
  }

  EventModel? buildEventToSave() {
    if (!(formKey.currentState?.saveAndValidate() ?? false)) return null;

    final formData = formKey.currentState!.value;
    final userId = _authService.currentUser?.uid ?? '';

    final dateRange = formData[EventFormFields.dateRange] as DateTimeRange?;

    final allowedBrandsRaw =
        formData[EventFormFields.allowedBrands] as String? ?? '';
    final allowedBrands = allowedBrandsRaw.isNotEmpty
        ? allowedBrandsRaw.split(',').map((e) => e.trim()).toList()
        : <String>[];

    final priceStr = formData[EventFormFields.price] as String?;
    final price = priceStr != null && priceStr.isNotEmpty
        ? double.tryParse(priceStr)
        : null;

    return EventModel(
      id: state.maybeWhen(editing: (e) => e.id, orElse: () => null),
      ownerId: state.maybeWhen(editing: (e) => e.ownerId, orElse: () => userId),
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
