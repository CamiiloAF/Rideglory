import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/create_event_params.dart';
import '../../domain/destination_suggestion.dart';
import '../../domain/event_difficulty.dart';
import '../../domain/usecases/create_event_use_case.dart';
import '../../domain/usecases/search_destinations_use_case.dart';
import 'create_event_state.dart';

/// Asistente de creación en 3 pasos + publicación (EV3).
@injectable
class CreateEventCubit extends Cubit<CreateEventState> {
  CreateEventCubit(this._createEvent, this._searchDestinations)
    : super(const CreateEventState());

  final CreateEventUseCase _createEvent;
  final SearchDestinationsUseCase _searchDestinations;
  Timer? _debounce;

  void updateName(String value) => emit(state.copyWith(name: value));

  void updateStartAt(DateTime value) => emit(state.copyWith(startAt: value));

  void updateMeetingPoint(String value) =>
      emit(state.copyWith(meetingPoint: value));

  void updateLocalImagePath(String? path) =>
      emit(state.copyWith(localImagePath: path));

  void updateDestinationQuery(String query) {
    emit(state.copyWith(destinationQuery: query));
    _debounce?.cancel();
    if (query.trim().length < 3) {
      emit(state.copyWith(destinationResults: const ResultState.initial()));
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(_search(query));
    });
  }

  Future<void> _search(String query) async {
    emit(state.copyWith(destinationResults: const ResultState.loading()));
    final result = await _searchDestinations(query);
    result.fold(
      (error) => emit(
        state.copyWith(destinationResults: ResultState.error(error: error)),
      ),
      (suggestions) => emit(
        state.copyWith(destinationResults: ResultState.data(data: suggestions)),
      ),
    );
  }

  void selectDestination(DestinationSuggestion destination) {
    emit(
      state.copyWith(
        destination: destination,
        destinationQuery: destination.displayName,
        destinationResults: const ResultState.initial(),
      ),
    );
  }

  void updateRouteText(String value) => emit(state.copyWith(routeText: value));

  void selectDifficulty(EventDifficulty difficulty) =>
      emit(state.copyWith(difficulty: difficulty));

  void updateMaxParticipants(int value) =>
      emit(state.copyWith(maxParticipants: value));

  void toggleFree(bool isFree) =>
      emit(state.copyWith(isFree: isFree, price: isFree ? 0 : state.price));

  void updatePrice(int value) => emit(state.copyWith(price: value));

  void nextStep() {
    if (state.step >= 2) return;
    emit(state.copyWith(step: state.step + 1));
  }

  void previousStep() {
    if (state.step <= 0) return;
    emit(state.copyWith(step: state.step - 1));
  }

  Future<void> submit() async {
    final startAt = state.startAt;
    final destination = state.destination;
    if (startAt == null || destination == null) return;

    emit(state.copyWith(submission: const ResultState.loading()));

    final params = CreateEventParams(
      name: state.name.trim(),
      startAt: startAt,
      meetingPoint: state.meetingPoint.trim(),
      destinationName: destination.displayName,
      destinationLat: destination.lat,
      destinationLng: destination.lng,
      routeText: state.routeText.trim(),
      difficulty: state.difficulty,
      maxParticipants: state.maxParticipants,
      price: state.isFree ? 0 : state.price,
      localImagePath: state.localImagePath,
    );

    final result = await _createEvent(params);
    result.fold(
      (error) =>
          emit(state.copyWith(submission: ResultState.error(error: error))),
      (_) =>
          emit(state.copyWith(submission: const ResultState.data(data: unit))),
    );
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
