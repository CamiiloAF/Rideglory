import 'dart:developer' as developer;

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:go_router/go_router.dart';
import 'package:injectable/injectable.dart';

import '../../../core/router/app_router.dart';
import '../../../core/router/app_routes.dart';

/// EV7: cuando el rider toca la notificación de inicio de rodada o de
/// cambio de ruta, navega directo al detalle. Tolerante a que Firebase no
/// esté configurado en desarrollo (F4): si falla, se registra en consola
/// y la app sigue.
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
    final eventId = message.data['eventId'];
    if (eventId == null) return;
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;
    context.pushNamed(AppRoutes.eventDetail, pathParameters: {'id': eventId});
  }
}
