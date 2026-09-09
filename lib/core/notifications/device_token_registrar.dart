import 'dart:developer' as developer;
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Registra el token FCM del dispositivo en `device_tokens` al iniciar
/// sesión. Tolerante a que Firebase no esté configurado en desarrollo: si
/// falla, lo registra en consola y sigue — nunca bloquea el login.
@lazySingleton
class DeviceTokenRegistrar {
  DeviceTokenRegistrar(this._supabaseClient);

  final SupabaseClient _supabaseClient;

  Future<void> registerForCurrentUser() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null) {
        return;
      }
      await _supabaseClient.from('device_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': Platform.isIOS ? 'ios' : 'android',
      }, onConflict: 'user_id,token');
    } catch (error, stackTrace) {
      developer.log(
        'No se pudo registrar el token FCM (Firebase puede no estar '
        'configurado en este entorno).',
        name: 'DeviceTokenRegistrar',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
