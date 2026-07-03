import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

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
      } catch (_) {}
    }

    handler.next(err);
  }
}
