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
      emit(const AuthState.loading());
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

    await result.fold(
      (failure) async => emit(AuthState.error(failure.message)),
      (user) async {
        if (user != null) {
          // Wait for vehicles to sync before emitting auth state
          await _syncAuthenticatedUserVehicles();
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

    await result.fold(
      (failure) async => emit(AuthState.error(failure.message)),
      (user) async {
        if (user != null) {
          // Wait for vehicles to sync before emitting auth state
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

  /// Sign in with Google
  Future<void> signInWithGoogle() async {
    emit(const AuthState.loading());

    final result = await _authService.signInWithGoogle();
    await result.fold(
      (failure) async => emit(AuthState.error(failure.message)),
      (user) async {
        if (user != null) {
          // Wait for vehicles to sync before emitting auth state
          await _syncAuthenticatedUserVehicles();
        } else {
          emit(const AuthState.error('Google sign-in failed'));
        }
      },
    );
  }

  /// Sign in with Apple
  Future<void> signInWithApple() async {
    emit(const AuthState.loading());

    final result = await _authService.signInWithApple();
    await result.fold(
      (failure) async => emit(AuthState.error(failure.message)),
      (user) async {
        if (user != null) {
          // Wait for vehicles to sync before emitting auth state
          await _syncAuthenticatedUserVehicles();
        } else {
          emit(const AuthState.error('Apple sign-in failed'));
        }
      },
    );
  }

  Future<void> _syncAuthenticatedUserVehicles() async {
    final vehicleResult = await _initializeAuthenticatedUserVehiclesUseCase();

    vehicleResult.fold(
      (error) {
        if (kDebugMode) {
          print('Failed to load vehicles: ${error.message}');
        }
        // If vehicles couldn't be loaded, treat as no vehicles (redirect to onboarding)
        final currentUser = _authService.currentUser;
        if (currentUser != null) {
          emit(AuthState.authenticatedWithoutVehicles(currentUser));
        }
      },
      (vehicles) {
        final currentUser = _authService.currentUser;
        if (currentUser == null) return;

        if (vehicles.isEmpty) {
          // No vehicles - redirect to onboarding
          emit(AuthState.authenticatedWithoutVehicles(currentUser));
        } else {
          // Has vehicles - proceed normally
          _vehicleCubit.loadSavedVehicle(vehicles);
          emit(AuthState.authenticated(currentUser));
        }
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
