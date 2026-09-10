import 'package:flutter_test/flutter_test.dart';
import 'package:rideglory/core/router/app_routes.dart';
import 'package:rideglory/features/events/presentation/event_push_navigator.dart';

/// D17b: el push de un SOS navega directo a `/live`, no al detalle del
/// evento — `LiveRideView` resuelve por su cuenta lo que normalmente trae
/// el detalle (ver `LiveRideCubit.resolveArgs`).
void main() {
  test('un push de tipo sos navega a la rodada en vivo', () {
    final route = EventPushRoute.fromData(const {
      'type': 'sos',
      'event_id': 'event-1',
      'sos_id': 'sos-1',
    });

    expect(route, isNotNull);
    expect(route!.routeName, AppRoutes.eventLive);
    expect(route.eventId, 'event-1');
  });

  test('un push sin type navega al detalle del evento', () {
    final route = EventPushRoute.fromData(const {'eventId': 'event-1'});

    expect(route, isNotNull);
    expect(route!.routeName, AppRoutes.eventDetail);
    expect(route.eventId, 'event-1');
  });

  test('un push de sos sin event_id no produce ruta', () {
    final route = EventPushRoute.fromData(const {'type': 'sos'});

    expect(route, isNull);
  });

  test('un push sin eventId no produce ruta', () {
    final route = EventPushRoute.fromData(const <String, dynamic>{});

    expect(route, isNull);
  });
}
