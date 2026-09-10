import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/destination_suggestion.dart';
import '../../domain/event_difficulty.dart';

part 'create_event_state.freezed.dart';

/// Asistente de 3 pasos para crear una rodada (EV3).
@freezed
abstract class CreateEventState with _$CreateEventState {
  const factory CreateEventState({
    @Default(0) int step,
    @Default('') String name,
    DateTime? startAt,
    @Default('') String meetingPoint,
    String? localImagePath,
    DestinationSuggestion? destination,
    @Default('') String routeText,
    @Default(EventDifficulty.medium) EventDifficulty difficulty,
    @Default(20) int maxParticipants,
    @Default(false) bool isFree,
    @Default(0) int price,
    @Default('') String destinationQuery,
    @Default(ResultState<List<DestinationSuggestion>>.initial())
    ResultState<List<DestinationSuggestion>> destinationResults,
    @Default(ResultState<Unit>.initial()) ResultState<Unit> submission,
  }) = _CreateEventState;

  const CreateEventState._();

  bool get canContinueStep1 =>
      name.trim().isNotEmpty &&
      startAt != null &&
      meetingPoint.trim().isNotEmpty;

  bool get canContinueStep2 =>
      destination != null && routeText.trim().isNotEmpty;

  bool get canSubmit => maxParticipants > 0;

  bool get isSubmitting => submission is Loading<Unit>;
}
