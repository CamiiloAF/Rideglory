import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:rideglory/core/l10n/rideglory_l10n.dart';
import 'package:rideglory/design_system/design_system.dart';
import 'package:rideglory/features/authentication/application/auth_cubit.dart';
import 'package:rideglory/shared/router/app_router.dart';

/// Códigos de [FirebaseAuthException] que indican que la sesión ya no es
/// válida en el servidor (usuario eliminado/deshabilitado/token expirado de
/// forma permanente). Nunca incluye códigos transitorios de conectividad
/// como `network-request-failed`.
const _sessionInvalidatedCodes = {
  'user-not-found',
  'user-disabled',
  'user-token-expired',
};

/// Obtiene el [AuthCubit] del contenedor DI de forma defensiva.
///
/// Devuelve `null` si el contenedor aún no está listo (p.ej. en tests sin
/// DI configurado). El logout forzado nunca debe propagar excepciones desde
/// la capa HTTP.
AuthCubit? _authCubit() {
  try {
    return GetIt.instance<AuthCubit>();
  } catch (_) {
    return null;
  }
}

class FirebaseAuthInterceptor extends Interceptor {
  FirebaseAuthInterceptor(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _firebaseAuth.currentUser?.getIdToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';

      if (kDebugMode) {
        log('Firebase token: $token');
      }
    }

    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) {
      try {
        final freshToken = await _firebaseAuth.currentUser?.getIdToken(true);
        if (freshToken != null && freshToken.isNotEmpty) {
          final options = err.requestOptions;
          options.headers['Authorization'] = 'Bearer $freshToken';

          if (kDebugMode) {
            log('Retrying with fresh Firebase token');
          }

          final dio = Dio(
            BaseOptions(
              baseUrl: options.baseUrl,
              headers: options.headers,
              connectTimeout: options.connectTimeout,
              receiveTimeout: options.receiveTimeout,
              sendTimeout: options.sendTimeout,
            ),
          );

          final response = await dio.fetch(options);
          return handler.resolve(response);
        }
      } on FirebaseAuthException catch (authError) {
        if (_sessionInvalidatedCodes.contains(authError.code)) {
          _authCubit()?.signOut();

          AppRouter.scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text(
                RidegloryL10n.current.auth_sessionEndedSnackbar,
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      } catch (_) {}
    }

    handler.next(err);
  }
}
