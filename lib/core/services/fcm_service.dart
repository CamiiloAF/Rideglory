import 'dart:developer';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/features/notifications/domain/usecases/register_fcm_token_usecase.dart';
import 'package:rideglory/shared/router/app_router.dart';

/// Android notification channel for high-priority FCM messages.
const _androidChannel = AndroidNotificationChannel(
  'rideglory_high_importance',
  'Rideglory Notificaciones',
  description: 'Notificaciones de Rideglory.',
  importance: Importance.high,
);

const _ridegloryScheme = 'rideglory';

@singleton
class FcmService {
  FcmService(this._registerFcmTokenUseCase);

  final RegisterFcmTokenUseCase _registerFcmTokenUseCase;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (kDebugMode) {
      log('FCM permission: ${settings.authorizationStatus}');
    }

    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    // ── Android notification channel ────────────────────────────────────────
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    // ── Local notifications init (foreground Android tap) ───────────────────
    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: _onLocalNotificationTap,
    );

    // ── iOS foreground presentation ─────────────────────────────────────────
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // ── Foreground: mostrar en Android con route como payload ───────────────
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // ── Background: app en background, usuario tapeó la push ───────────────
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageTapped);

    // ── Terminated: app cerrada, usuario tapeó la push ─────────────────────
    final initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(
        const Duration(milliseconds: 300),
        () => _onMessageTapped(initialMessage),
      );
    }

    // ── app_links: deep links externos (rideglory://...) ───────────────────
    _setupExternalDeepLinks();

    // ── Token registration ──────────────────────────────────────────────────
    final token = await messaging.getToken();
    if (token != null) await _registerToken(token);
    messaging.onTokenRefresh.listen(_registerToken);
  }

  // ── Deep links externos ────────────────────────────────────────────────────

  Future<void> _setupExternalDeepLinks() async {
    final appLinks = AppLinks();

    // App abierta desde estado terminado via URI externo
    final initialUri = await appLinks.getInitialLink();
    if (initialUri != null) {
      Future.delayed(
        const Duration(milliseconds: 300),
        () => _navigateFromUri(initialUri),
      );
    }

    // App en background o foreground
    appLinks.uriLinkStream.listen(_navigateFromUri);
  }

  // ── FCM handlers ──────────────────────────────────────────────────────────

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    // iOS maneja foreground nativo — no necesita local plugin.
    if (!Platform.isAndroid) return;

    final route = message.data['route'] as String?;

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _androidChannel.id,
          _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      payload: route,
    );
  }

  /// Tap en notificación local foreground (Android).
  void _onLocalNotificationTap(NotificationResponse response) {
    final route = response.payload;
    if (route == null || route.isEmpty) return;
    final uri = Uri.tryParse(route);
    if (uri != null) _navigateFromUri(uri);
  }

  /// Tap en push FCM (background o terminated).
  void _onMessageTapped(RemoteMessage message) {
    final route = message.data['route'] as String?;
    if (route == null || route.isEmpty) return;
    final uri = Uri.tryParse(route);
    if (uri != null) _navigateFromUri(uri);
  }

  // ── Navegación ─────────────────────────────────────────────────────────────

  void _navigateFromUri(Uri uri) {
    if (uri.scheme != _ridegloryScheme) return;
    if (kDebugMode) log('Deep link → ${uri.toString()}');
    AppRouter.pushDeepLink(uri.toString());
  }

  // ── Token ──────────────────────────────────────────────────────────────────

  Future<void> _registerToken(String token) async {
    if (kDebugMode) log('Registering FCM token: ${token.substring(0, 10)}...');
    await _registerFcmTokenUseCase(token);
  }
}

/// Background message handler — MUST be top-level. Corre en isolate separado.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) log('FCM background message: ${message.messageId}');
}
