import 'dart:developer';

import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../exceptions/domain_exception.dart';
import 'api_result.dart';

const _genericErrorMessage =
    'Ups, tuvimos un error interno, por favor intentalo de nuevo más tarde.';

Future<ApiResult<T>> handlerExceptionHttp<T>({
  required Future<T> Function() function,
}) async {
  try {
    final apiResult = await function();
    return ApiResult.success(data: apiResult);
  } on DioException catch (dioException) {
    if (kDebugMode) {
      log('Error in DioException type: ${dioException.type}');
      log('Error in DioException message: ${dioException.message}');
      log('Error in DioException response: ${dioException.response?.data}');
    }

    return ApiResult.failure(
      dataException: DomainException(
        message: _getDioErrorMessage(dioException),
      ),
    );
  } on FirebaseAuthException catch (firebaseException) {
    if (kDebugMode) {
      log('Error in FirebaseAuth code: ${firebaseException.code}');
      log('Error in FirebaseAuth message: ${firebaseException.message}');
      log('Error in FirebaseAuth stackTrace: ${firebaseException.stackTrace}');
    }

    return ApiResult.failure(
      dataException: DomainException(
        message: _getFirebaseAuthErrorMessage(firebaseException.code),
      ),
    );
  } on PlatformException catch (platformException) {
    if (kDebugMode) {
      log('Error in PlatformException code: ${platformException.code}');
      log('Error in PlatformException message: ${platformException.message}');
      log('Error in PlatformException details: ${platformException.details}');
    }

    return ApiResult.failure(
      dataException: DomainException(
        message: _getPlatformExceptionErrorMessage(platformException.code),
      ),
    );
  } on DomainException catch (domainException) {
    return ApiResult.failure(dataException: domainException);
  } catch (error) {
    if (kDebugMode) {
      if (error is Error) {
        print(error.stackTrace);
      }
      log('Error in Service Exception: $error}');
    }
    return ApiResult.failure(
      dataException: const DomainException(message: _genericErrorMessage),
    );
  }
}

String _getDioErrorMessage(DioException exception) {
  final responseMessage = _extractResponseMessage(exception.response?.data);
  if (responseMessage != null && responseMessage.isNotEmpty) {
    return responseMessage;
  }

  switch (exception.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'La solicitud tardó demasiado. Revisa tu conexión e intenta de nuevo.';
    case DioExceptionType.connectionError:
      return 'No pudimos conectarnos al servidor. Revisa tu conexión a internet.';
    case DioExceptionType.badCertificate:
      return 'No pudimos validar la conexión segura con el servidor.';
    case DioExceptionType.cancel:
      return 'La solicitud fue cancelada.';
    case DioExceptionType.badResponse:
      return _getHttpStatusErrorMessage(exception.response?.statusCode);
    case DioExceptionType.unknown:
      return _genericErrorMessage;
  }
}

String? _extractResponseMessage(Object? responseData) {
  if (responseData is String) {
    return responseData;
  }

  if (responseData is Map<String, dynamic>) {
    final message = responseData['message'];
    if (message is String) {
      return message;
    }
    if (message is List) {
      return message.whereType<String>().join('\n');
    }

    final error = responseData['error'];
    if (error is String) {
      return error;
    }
  }

  return null;
}

String _getHttpStatusErrorMessage(int? statusCode) {
  switch (statusCode) {
    case 400:
      return 'La información enviada no es válida.';
    case 401:
      return 'Tu sesión expiró. Inicia sesión nuevamente.';
    case 403:
      return 'No tienes permisos para realizar esta acción.';
    case 404:
      return 'No encontramos la información solicitada.';
    case 409:
      return 'Ya existe un registro con esta información.';
    default:
      if (statusCode != null && statusCode >= 500 && statusCode < 600) {
        return _genericErrorMessage;
      }
      return _genericErrorMessage;
  }
}

Future<Either<DomainException, Model>> executeService<Model>({
  required Future<Model> Function() function,
}) async {
  final result = await handlerExceptionHttp<Model>(function: function);

  switch (result) {
    case final Success<Model> success:
      return Right(success.data);
    case final Failure<Model> failure:
      return Left(failure.dataException);
    default:
      return Left(DomainException(message: 'Unexpected result type: $result'));
  }
}

String _getFirebaseAuthErrorMessage(String? code) {
  switch (code) {
    case 'user-not-found':
      return 'No user found with this email';
    case 'wrong-password':
      return 'Incorrect password';
    case 'email-already-in-use':
      return 'Email already in use';
    case 'weak-password':
      return 'Password is too weak';
    case 'invalid-email':
      return 'Invalid email address';
    case 'invalid-credential':
      return 'Invalid credentials';
    case 'user-disabled':
      return 'User account has been disabled';
    case 'too-many-requests':
      return 'Too many login attempts. Try again later';
    case 'operation-not-allowed':
      return 'This operation is not allowed';
    case 'credential-already-in-use':
      return 'This account is already in use';
    case 'requires-recent-login':
      return 'Please login again before performing this operation';
    case 'network-request-failed':
      return 'Network error. Please check your connection';
    default:
      return _genericErrorMessage;
  }
}

String _getPlatformExceptionErrorMessage(String code) {
  switch (code) {
    case 'sign_in_failed':
      return 'Google sign-in failed. Please check your internet connection and try again';
    case 'sign_in_cancelled':
      return 'Google sign-in was cancelled';
    case 'network_error':
      return 'Network error. Please check your internet connection';
    case 'DEVELOPER_ERROR':
      return 'Developer error. Please contact support';
    default:
      return _genericErrorMessage;
  }
}
