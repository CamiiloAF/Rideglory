import 'dart:developer';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/features/notifications/domain/usecases/register_fcm_token_usecase.dart';

/// Android notification channel for high-priority FCM messages.
const _androidChannel = AndroidNotificationChannel(
  'rideglory_high_importance',
  'Rideglory Notificaciones',
  description: 'Notificaciones de Rideglory.',
  importance: Importance.high,
);

@singleton
class FcmService {
  FcmService(this._registerFcmTokenUseCase);

  final RegisterFcmTokenUseCase _registerFcmTokenUseCase;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // Request permission
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

    // Configure local notifications plugin
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);

    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsDarwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );
    await _localNotifications.initialize(initializationSettings);

    // iOS foreground presentation
    await messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // Show foreground notifications on Android via flutter_local_notifications
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);

    // Register token
    final token = await messaging.getToken();
    if (token != null) {
      await _registerToken(token);
    }

    // Listen for token refresh
    messaging.onTokenRefresh.listen(_registerToken);
  }

  Future<void> _registerToken(String token) async {
    if (kDebugMode) log('Registering FCM token: ${token.substring(0, 10)}...');
    await _registerFcmTokenUseCase(token);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = message.notification?.android;
    if (notification == null || android == null) return;

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
    );
  }
}

/// Background message handler — MUST be a top-level function.
/// Runs in a separate Dart isolate. DI must be re-initialized.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // NOTE: Firebase.initializeApp() + configureDependencies() must be called
  // here if any DI-registered services are used in background processing.
  // For iter-2, we only log the message — no DI needed.
  if (kDebugMode) {
    log('FCM background message: ${message.messageId}');
  }
}
