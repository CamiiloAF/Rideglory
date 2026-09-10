import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/event_registrant.dart';

part 'registrants_state.freezed.dart';

/// Pantalla EV5 (organizador): inscritos de una rodada.
@freezed
abstract class RegistrantsState with _$RegistrantsState {
  const factory RegistrantsState({
    @Default(ResultState<List<EventRegistrant>>.initial())
    ResultState<List<EventRegistrant>> registrants,
  }) = _RegistrantsState;
}
