import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:rideglory/core/http/api_base_url_resolver.dart';
import 'package:rideglory/core/http/firebase_auth_interceptor.dart';

abstract final class AppDio {
  static Dio create({
    required FirebaseAuth firebaseAuth,
    required FirebaseRemoteConfig remoteConfig,
  }) {
    final resolvedUrl = ApiBaseUrlResolver(remoteConfig).resolve();
    final dio = Dio(
      BaseOptions(
        baseUrl: resolvedUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 20),
        headers: const {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(FirebaseAuthInterceptor(firebaseAuth));

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }

    // Sentry Dio interceptor — debe ser el ÚLTIMO interceptor para que
    // capture datos ya procesados.
    // tracePropagationTargets se configura globalmente en SentryFlutter.init
    // (main.dart) para restringir el header sentry-trace al host Rideglory.
    dio.addSentry(
      captureFailedRequests: true,
    );

    return dio;
  }
}
