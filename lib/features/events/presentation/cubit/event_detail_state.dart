import 'package:dartz/dartz.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/event.dart';
import '../../domain/event_route_change.dart';

part 'event_detail_state.freezed.dart';

/// Detalle de una rodada (EV2). `action` es el resultado de la última
/// operación disparada desde esta pantalla (inscribirme, cancelar,
/// iniciar, cambiar ruta, cancelar rodada): solo importa mientras está en
/// vuelo para deshabilitar el botón, nunca reemplaza a [event] como fuente
/// de verdad del estado del evento.
@freezed
abstract class EventDetailState with _$EventDetailState {
  const factory EventDetailState({
    @Default(ResultState<Event>.initial()) ResultState<Event> event,
    @Default(ResultState<List<EventRouteChange>>.initial())
    ResultState<List<EventRouteChange>> routeChanges,
    @Default(ResultState<Unit>.initial()) ResultState<Unit> action,
  }) = _EventDetailState;

  const EventDetailState._();

  bool get isActionInFlight => action is Loading<Unit>;
}
