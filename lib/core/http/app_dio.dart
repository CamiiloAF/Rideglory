import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:rideglory/core/http/api_base_url_resolver.dart';
import 'package:rideglory/core/http/firebase_auth_interceptor.dart';

abstract final class AppDio {
  static Dio create({
    required FirebaseAuth firebaseAuth,
    required FirebaseRemoteConfig remoteConfig,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiBaseUrlResolver(remoteConfig).resolve(),
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
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

    return dio;
  }
}
