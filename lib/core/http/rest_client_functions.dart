import 'package:dartz/dartz.dart';
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
  } on FirebaseAuthException catch (firebaseException) {
    if (kDebugMode) {
      print('Error in FirebaseAuth code: ${firebaseException.code}');
      print('Error in FirebaseAuth message: ${firebaseException.message}');
      print(
        'Error in FirebaseAuth stackTrace: ${firebaseException.stackTrace}',
      );
    }

    return ApiResult.failure(
      dataException: DomainException(
        message: _getFirebaseAuthErrorMessage(firebaseException.code),
      ),
    );
  } on PlatformException catch (platformException) {
    if (kDebugMode) {
      print('Error in PlatformException code: ${platformException.code}');
      print('Error in PlatformException message: ${platformException.message}');
      print('Error in PlatformException details: ${platformException.details}');
    }

    return ApiResult.failure(
      dataException: DomainException(
        message: _getPlatformExceptionErrorMessage(platformException.code),
      ),
    );
  } catch (error) {
    if (kDebugMode) {
      if (error is Error) {
        print(error.stackTrace);
      }
      print('Error in Service Exception: $error}');
    }
    return ApiResult.failure(
      dataException: const DomainException(message: _genericErrorMessage),
    );
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
