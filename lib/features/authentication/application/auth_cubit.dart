import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/auth_exception.dart';
import 'package:rideglory/core/services/analytics/analytics_events.dart';
import 'package:rideglory/core/services/analytics/analytics_params.dart';
import 'package:rideglory/core/services/analytics/analytics_service.dart';
import 'package:rideglory/core/services/analytics/analytics_uid_hasher.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/core/services/fcm_service.dart';
import 'package:rideglory/core/l10n/rideglory_l10n.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';

part 'auth_state.dart';

@singleton
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final FcmService _fcmService;
  final AnalyticsService _analytics;

  AuthCubit(this._authService, this._fcmService, this._analytics)
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
      (failure) async {
        _analytics
            .logEvent(AnalyticsEvents.authFailed, {
              AnalyticsParams.authMethod: AnalyticsParams.authMethodEmail,
              AnalyticsParams.authErrorCategory:
                  _categorizeError(failure.message),
            })
            .ignore();
        emit(AuthState.error(failure.message));
      },
      (authUser) async {
        if (authUser.firebaseUser.uid.isNotEmpty) {
          await _printFirebaseToken(authUser.firebaseUser);
          await _onAuthenticated(
            firebaseUid: authUser.firebaseUser.uid,
            method: AnalyticsParams.authMethodEmail,
          );
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
      (failure) async {
        _analytics
            .logEvent(AnalyticsEvents.authFailed, {
              AnalyticsParams.authMethod: AnalyticsParams.authMethodEmail,
              AnalyticsParams.authErrorCategory:
                  _categorizeError(failure.message),
            })
            .ignore();
        emit(AuthState.error(failure.message));
      },
      (firebaseUser) async {
        if (firebaseUser != null) {
          await _printFirebaseToken(firebaseUser);
          await _onAuthenticated(
            firebaseUid: firebaseUser.uid,
            method: AnalyticsParams.authMethodEmail,
          );
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
      (failure) async {
        _analytics
            .logEvent(AnalyticsEvents.authFailed, {
              AnalyticsParams.authMethod: AnalyticsParams.authMethodGoogle,
              AnalyticsParams.authErrorCategory:
                  _categorizeError(failure.message),
            })
            .ignore();
        emit(AuthState.error(failure.message));
      },
      (authUser) async {
        if (authUser.firebaseUser.uid.isNotEmpty) {
          await _printFirebaseToken(authUser.firebaseUser);
          await _onAuthenticated(
            firebaseUid: authUser.firebaseUser.uid,
            method: AnalyticsParams.authMethodGoogle,
          );
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
      (failure) async {
        _analytics
            .logEvent(AnalyticsEvents.authFailed, {
              AnalyticsParams.authMethod: AnalyticsParams.authMethodApple,
              AnalyticsParams.authErrorCategory:
                  _categorizeError(failure.message),
            })
            .ignore();
        emit(AuthState.error(failure.message));
      },
      (firebaseUser) async {
        if (firebaseUser != null) {
          await _onAuthenticated(
            firebaseUid: firebaseUser.uid,
            method: AnalyticsParams.authMethodApple,
          );
          emit(AuthState.authenticated(_authService.currentUser));
          _fcmService.initialize().ignore();
        } else {
          emit(const AuthState.error('Apple sign-in failed'));
        }
      },
    );
  }

  /// Llama a [setUserId] con el SHA-256 del uid (nunca en claro), emite
  /// [AnalyticsEvents.authSucceeded] y fija la user property [login_method].
  /// También emite [AnalyticsEvents.authFirstHomeEntry] para cerrar el embudo.
  Future<void> _onAuthenticated({
    required String firebaseUid,
    required String method,
  }) async {
    final hashedUid = AnalyticsUidHasher.hash(firebaseUid);
    await _analytics.setUserId(hashedUid);
    await _analytics.setUserProperty(
      AnalyticsParams.userPropertyLoginMethod,
      method,
    );
    await _analytics.logEvent(
      AnalyticsEvents.authSucceeded,
      {AnalyticsParams.authMethod: method},
    );
    await _analytics.logEvent(AnalyticsEvents.authFirstHomeEntry);
  }

  /// Mapea el mensaje de error de [DomainException] a una categoría no-PII.
  /// **Nunca** pasa el texto crudo al evento de analítica.
  ///
  /// Orden deliberado: credenciales > cancelación > red > desconocido.
  /// "credenciales" contiene la subcadena "red" en español, por lo que se
  /// evalúa primero para evitar clasificarla como error de red.
  String _categorizeError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('credential') ||
        lower.contains('credencial') ||
        lower.contains('password') ||
        lower.contains('contraseña') ||
        lower.contains('user-not-found') ||
        lower.contains('wrong') ||
        lower.contains('invalid')) {
      return AnalyticsParams.authErrorInvalidCredentials;
    }
    if (lower.contains('cancel') || lower.contains('cancelado')) {
      return AnalyticsParams.authErrorCancelled;
    }
    if (lower.contains('network') ||
        lower.contains('connection') ||
        lower.contains('internet') ||
        lower.contains('conexión') ||
        lower.contains('internet')) {
      return AnalyticsParams.authErrorNetwork;
    }
    return AnalyticsParams.authErrorUnknown;
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
      (failure) {
        _analytics
            .logEvent(AnalyticsEvents.authFailed, {
              AnalyticsParams.authMethod:
                  AnalyticsParams.authMethodForgotPassword,
              AnalyticsParams.authErrorCategory:
                  _categorizeError(failure.message),
            })
            .ignore();
        emit(AuthState.error(failure.message));
      },
      (_) {
        _analytics
            .logEvent(AnalyticsEvents.authSucceeded, {
              AnalyticsParams.authMethod:
                  AnalyticsParams.authMethodForgotPassword,
            })
            .ignore();
        emit(const AuthState.passwordResetEmailSent());
      },
    );
  }
}
