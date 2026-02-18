import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rideglory/core/exceptions/auth_exception.dart';
import 'package:rideglory/core/services/auth_service.dart';
import 'package:rideglory/features/vehicles/domain/usecases/initialize_authenticated_user_vehicles_usecase.dart';
import 'package:rideglory/features/vehicles/presentation/cubit/vehicle_cubit.dart';

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

  /// Check if user is logged in
  void checkAuthState() {
    final user = _authService.currentUser;
    if (user != null) {
      emit(AuthState.authenticated(user));
      _syncAuthenticatedUserVehicles();
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

    final result = await _authService.signUpWithEmail(
      email: email,
      password: password,
    );

    result.fold((failure) => emit(AuthState.error(failure.message)), (user) {
      if (user != null) {
        emit(AuthState.authenticated(user));
        _syncAuthenticatedUserVehicles();
      } else {
        emit(
          const AuthState.error(
            'Falló el registro, intenta de nuevo más tarde',
          ),
        );
      }
    });
  }

  /// Sign in with email and password
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    emit(const AuthState.loading());

    final result = await _authService.signInWithEmail(
      email: email,
      password: password,
    );

    result.fold((failure) => emit(AuthState.error(failure.message)), (user) {
      if (user != null) {
        emit(AuthState.authenticated(user));
        _syncAuthenticatedUserVehicles();
      } else {
        emit(
          const AuthState.error(
            'Falló el inicio de sesión, intenta de nuevo más tarde',
          ),
        );
      }
    });
  }

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    emit(const AuthState.loading());

    final result = await _authService.signInWithGoogle();
    result.fold((failure) => emit(AuthState.error(failure.message)), (user) {
      if (user != null) {
        emit(AuthState.authenticated(user));
        _syncAuthenticatedUserVehicles();
      } else {
        emit(const AuthState.error('Google sign-in failed'));
      }
    });
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    emit(const AuthState.loading());

    final result = await _authService.signInWithApple();
    result.fold((failure) => emit(AuthState.error(failure.message)), (user) {
      if (user != null) {
        emit(AuthState.authenticated(user));
        _syncAuthenticatedUserVehicles();
      } else {
        emit(const AuthState.error('Apple sign-in failed'));
      }
    });
  }

  Future<void> _syncAuthenticatedUserVehicles() async {
    final vehicleResult = await _initializeAuthenticatedUserVehiclesUseCase();

    vehicleResult.fold(
      (error) {
        if (kDebugMode) {
          print('Failed to load vehicles: ${error.message}');
        }
        // Silently fail - user is authenticated but vehicles couldn't be loaded
        // They can retry manually if needed
      },
      (vehicles) {
        // Pre-set the selected vehicle in VehicleCubit
        _vehicleCubit.loadSavedVehicle(vehicles);
      },
    );
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

    await _authService.sendPasswordResetEmail(email);
    emit(const AuthState.passwordResetEmailSent());
  }

  /// Sync authenticated user's vehicles and pre-set selected vehicle.
  ///
  /// This is public and can be called from any screen (splash, home, etc.)
  /// to sync vehicles for the currently authenticated user.
  ///
  /// Only works if user is authenticated. Fails silently if user is not logged in.
  Future<void> syncAuthenticatedUserVehicles() async {
    if (_authService.currentUser == null) {
      return;
    }
    await _syncAuthenticatedUserVehicles();
  }
}
