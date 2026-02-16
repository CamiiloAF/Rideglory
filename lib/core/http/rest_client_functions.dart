import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';

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
    // } on FirebaseAuthException catch (firebaseException) {
    //   if (kDebugMode) {
    //     print('Error in FirebaseAuth code: ${firebaseException.code}');
    //     print('Error in FirebaseAuth message: ${firebaseException.message}');
    //     print(
    //       'Error in FirebaseAuth stackTrace: ${firebaseException.stackTrace}',
    //     );
    //   }
    //
    //   return ApiResult.failure(
    //     dataException: DomainException(message: firebaseException.errorMessage),
    //   );
    //
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