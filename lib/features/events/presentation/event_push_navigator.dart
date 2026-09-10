import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';

/// A dónde navega el toque de una notificación push de eventos, resuelto
/// puramente desde su payload — separado de [EventPushNavigator] para que
/// sea testeable sin Firebase ni `GoRouter`.
class EventPushRoute {
  const EventPushRoute({required this.routeName, required this.eventId});

  final String routeName;
  final String eventId;

  /// `null` cuando el payload no trae suficiente información para navegar
  /// (por ejemplo, un push sin `eventId`/`event_id`).
  static EventPushRoute? fromData(Map<String, dynamic> data) {
    if (data['type'] == 'sos') {
      final eventId = data['event_id'];
      if (eventId == null) return null;
      return EventPushRoute(
        routeName: AppRoutes.eventLive,
        eventId: eventId as String,
      );
    }
    final eventId = data['eventId'];
    if (eventId == null) return null;
    return EventPushRoute(
      routeName: AppRoutes.eventDetail,
      eventId: eventId as String,
    );
  }
}

/// EV7: cuando el rider toca la notificación de inicio de rodada o de
/// cambio de ruta, navega directo al detalle. D17b: cuando toca la
/// notificación de un SOS, navega directo a la rodada en vivo
/// (`LiveRideView` resuelve por su cuenta los datos que normalmente trae
/// el detalle del evento, vía `LiveRideCubit.resolveArgs`). Tolerante a
/// que Firebase no esté configurado en desarrollo (F4): si falla, se
/// registra en consola y la app sigue.
@lazySingleton
class EventPushNavigator {
  Future<void> init() async {
    try {
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
      final initialMessage = await FirebaseMessaging.instance
          .getInitialMessage();
      if (initialMessage != null) {
        _handleMessage(initialMessage);
      }
    } catch (error, stackTrace) {
      developer.log(
        'No se pudo inicializar la navegación por push de eventos '
        '(Firebase puede no estar configurado en este entorno).',
        name: 'EventPushNavigator',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void _handleMessage(RemoteMessage message) {
    final route = EventPushRoute.fromData(message.data);
    if (route == null) return;
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    context.pushNamed(route.routeName, pathParameters: {'id': route.eventId});
  }
}
