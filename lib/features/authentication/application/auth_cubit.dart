import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/services/auth_service.dart';

part 'auth_state.dart';

@singleton
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;

  AuthCubit(this._authService) : super(const AuthState.initial());

  /// Check if user is logged in
  void checkAuthState() {
    final user = _authService.currentUser;
    if (user != null) {
      emit(AuthState.authenticated(user));
    } else {
      emit(const AuthState.unauthenticated());
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    emit(const AuthState.loading());
    try {
      final user = await _authService.signUpWithEmail(
        email: email,
        password: password,
      );
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.error('Sign up failed'));
      }
    } on AuthException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error('An unexpected error occurred'));
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(const AuthState.loading());
    try {
      final user = await _authService.signInWithEmail(
        email: email,
        password: password,
      );
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.error('Sign in failed'));
      }
    } on AuthException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error('An unexpected error occurred'));
    }
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    emit(const AuthState.loading());
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.error('Google sign-in failed'));
      }
    } on AuthException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error('An unexpected error occurred'));
    }
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    emit(const AuthState.loading());
    try {
      final user = await _authService.signInWithApple();
      if (user != null) {
        emit(AuthState.authenticated(user));
      } else {
        emit(const AuthState.error('Apple sign-in failed'));
      }
    } on AuthException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error('An unexpected error occurred'));
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await _authService.signOut();
      emit(const AuthState.unauthenticated());
    } on AuthException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error('Failed to sign out'));
    }
  }

  /// Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    emit(const AuthState.loading());
    try {
      await _authService.sendPasswordResetEmail(email);
      emit(const AuthState.passwordResetEmailSent());
    } on AuthException catch (e) {
      emit(AuthState.error(e.message));
    } catch (e) {
      emit(AuthState.error('Failed to send reset email'));
    }
  }
}
