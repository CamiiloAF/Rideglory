import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/auth_exception.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/users/domain/model/user_model.dart';
import 'package:rideglory/features/vehicles/domain/usecases/initialize_authenticated_user_vehicles_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';
import 'package:rideglory/core/l10n/rideglory_l10n.dart';

part 'auth_state.dart';

@singleton
class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final InitializeAuthenticatedUserVehiclesUseCase
  _initializeAuthenticatedUserVehiclesUseCase;
  final VehicleCubit _vehicleCubit;

  AuthCubit(
    this._authService,
    this._initializeAuthenticatedUserVehiclesUseCase,
    this._vehicleCubit,
  ) : super(const AuthState.initial());

  void checkAuthState() {
    final user = _authService.currentUser;
    if (user != null) {
      emit(const AuthState.loading());
      _syncAuthenticatedUserVehicles();
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
          await _syncAuthenticatedUserVehicles(user: authUser.user);
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
          await _syncAuthenticatedUserVehicles();
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
          await _syncAuthenticatedUserVehicles(user: authUser.user);
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
          await _syncAuthenticatedUserVehicles();
        } else {
          emit(const AuthState.error('Apple sign-in failed'));
        }
      },
    );
  }

  Future<void> _syncAuthenticatedUserVehicles({UserModel? user}) async {
    final vehicleResult = await _initializeAuthenticatedUserVehiclesUseCase();

    vehicleResult.fold(
      (error) {
        if (kDebugMode) {
          print('Failed to load vehicles: ${error.message}');
        }
        final firebaseUser = _authService.currentUser;
        if (firebaseUser != null) {
          emit(AuthState.authenticated(user ?? _authService.currentUser));
        }
      },
      (vehicles) {
        final firebaseUser = _authService.currentUser;
        if (firebaseUser == null) return;

        _vehicleCubit.loadSavedVehicle(vehicles);
        emit(AuthState.authenticated(user ?? _authService.currentUser));
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

    await _authService.sendPasswordResetEmail(email);
    emit(const AuthState.passwordResetEmailSent());
  }

  /// Sync authenticated user's vehicles and pre-set selected vehicle.
  ///
  /// Only works if user is authenticated. Fails silently if user is not logged in.
  Future<void> syncAuthenticatedUserVehicles() async {
    if (_authService.currentUser == null) {
      return;
    }
    await _syncAuthenticatedUserVehicles();
  }
}
