import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/auth_exception.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/core/services/fcm_service.dart';
import 'package:rideglory/core/l10n/rideglory_l10n.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

part 'auth_state.dart';

@singleton
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final FcmService _fcmService;

  AuthCubit(this._authService, this._fcmService)
      : super(const AuthState.initial());

  void checkAuthState() {
    final user = _authService.currentUser;
    if (user != null) {
      emit(AuthState.authenticated(user));
      _fcmService.initialize().ignore();
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  Future<void> signUpWithEmail({
    required String fullName,
    required String email,
    required String password,
  }) async {
    emit(const AuthState.loading());

    final result = await _authService.signUpWithEmail(
      fullName: fullName,
      email: email,
      password: password,
    );

    await result.fold(
      (failure) async => emit(AuthState.error(failure.message)),
      (authUser) async {
        if (authUser.firebaseUser.uid.isNotEmpty) {
          await _printFirebaseToken(authUser.firebaseUser);
          emit(AuthState.authenticated(authUser.user));
          _fcmService.initialize().ignore();
        } else {
          emit(
            const AuthState.error(
              'Falló el registro, intenta de nuevo más tarde',
            ),
          );
        }
      },
    );
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(const AuthState.loading());

    final result = await _authService.signInWithEmail(
      email: email,
      password: password,
    );

    await result.fold(
      (failure) async => emit(AuthState.error(failure.message)),
      (firebaseUser) async {
        if (firebaseUser != null) {
          await _printFirebaseToken(firebaseUser);
          emit(AuthState.authenticated(_authService.currentUser));
          _fcmService.initialize().ignore();
        } else {
          emit(
            const AuthState.error(
              'Falló el inicio de sesión, intenta de nuevo más tarde',
            ),
          );
        }
      },
    );
  }

  Future<void> signInWithGoogle() async {
    emit(const AuthState.loading());

    final result = await _authService.signInWithGoogle();
    await result.fold(
      (failure) async => emit(AuthState.error(failure.message)),
      (authUser) async {
        if (authUser.firebaseUser.uid.isNotEmpty) {
          await _printFirebaseToken(authUser.firebaseUser);
          emit(AuthState.authenticated(authUser.user));
          _fcmService.initialize().ignore();
        } else {
          emit(const AuthState.error('Google sign-in failed'));
        }
      },
    );
  }

  Future<void> signInWithApple() async {
    emit(const AuthState.loading());

    final result = await _authService.signInWithApple();
    await result.fold(
      (failure) async => emit(AuthState.error(failure.message)),
      (firebaseUser) async {
        if (firebaseUser != null) {
          emit(AuthState.authenticated(_authService.currentUser));
        } else {
          emit(const AuthState.error('Apple sign-in failed'));
        }
      },
    );
  }

  Future<void> _printFirebaseToken(User user) async {
    if (!kDebugMode) return;

    try {
      final token = await user.getIdToken();
      if (token == null || token.isEmpty) {
        log('Firebase token is empty for user: ${user.uid}');
        return;
      }
      log('Firebase token: $token');
    } catch (error) {
      log('Failed to get Firebase token: $error');
    }
  }

  Future<void> signOut() async {
    try {
      await _authService.signOut();
      emit(const AuthState.unauthenticated());
    } on AuthException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error(RidegloryL10n.current.auth_failedToSignOut));
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    emit(const AuthState.loading());

    final result = await _authService.sendPasswordResetEmail(email);
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (_) => emit(const AuthState.passwordResetEmailSent()),
    );
  }
}
