import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    }

    handler.next(options);
  }
}
