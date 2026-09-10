import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/event.dart';

part 'events_list_state.freezed.dart';

/// Segmento de EV1: Próximas (published/started públicas) o Mías
/// (organizadas o con inscripción propia).
enum EventsSegment { upcoming, mine }

/// Dos resultados independientes -- uno por segmento -- porque cambiar de
/// pestaña no debe repetir una carga ya resuelta.
@freezed
abstract class EventsListState with _$EventsListState {
  const factory EventsListState({
    @Default(EventsSegment.upcoming) EventsSegment segment,
    @Default(ResultState<List<Event>>.initial())
    ResultState<List<Event>> upcoming,
    @Default(ResultState<List<Event>>.initial()) ResultState<List<Event>> mine,
  }) = _EventsListState;

  const EventsListState._();

  ResultState<List<Event>> get current =>
      segment == EventsSegment.upcoming ? upcoming : mine;

  bool get isLoading => current.maybeWhen(
    loading: () => true,
    initial: () => true,
    orElse: () => false,
  );

  bool get hasError =>
      current.maybeWhen(error: (_) => true, orElse: () => false);

  List<Event> get items => current.whenOrNull(data: (data) => data) ?? const [];

  bool get isEmpty => !isLoading && !hasError && items.isEmpty;
}
