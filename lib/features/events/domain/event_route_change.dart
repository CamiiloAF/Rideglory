import 'package:freezed_annotation/freezed_annotation.dart';

part 'event_route_change.freezed.dart';

/// Un aviso de cambio de ruta/contingencia (EV6). Es un log inmutable: no
/// se edita ni se borra.
@freezed
abstract class EventRouteChange with _$EventRouteChange {
  const factory EventRouteChange({
    required String id,
    required String eventId,
    required String message,
    required DateTime createdAt,
  }) = _EventRouteChange;
}
