part of 'auth_cubit.dart';

/// Authentication state
sealed class AuthState {
  const AuthState();

  /// Initial state
  const factory AuthState.initial() = _Initial;

  /// Loading state
  const factory AuthState.loading() = _Loading;

  /// Authenticated state with user
  const factory AuthState.authenticated(User user, {UserModel? appUser}) =
      _Authenticated;

  /// Authenticated state but without vehicles (needs onboarding)
  const factory AuthState.authenticatedWithoutVehicles(
    User user, {
    UserModel? appUser,
  }) = _AuthenticatedWithoutVehicles;

  /// Unauthenticated state
  const factory AuthState.unauthenticated() = _Unauthenticated;

  /// Error state
  const factory AuthState.error(String message) = _Error;

  /// Password reset email sent
  const factory AuthState.passwordResetEmailSent() = _PasswordResetEmailSent;

  /// Check if authenticated (with or without vehicles)
  bool get isAuthenticated =>
      this is _Authenticated || this is _AuthenticatedWithoutVehicles;

  /// Check if authenticated with vehicles
  bool get isAuthenticatedWithVehicles => this is _Authenticated;

  /// Check if authenticated without vehicles (needs onboarding)
  bool get isAuthenticatedWithoutVehicles =>
      this is _AuthenticatedWithoutVehicles;

  /// Check if loading
  bool get isLoading => this is _Loading;

  /// Check if has error
  bool get hasError => this is _Error;

  /// Get error message if any
  String? get errorMessage => this is _Error ? (this as _Error).message : null;

  /// Get current user if authenticated (with or without vehicles)
  User? get currentUser => this is _Authenticated
      ? (this as _Authenticated).user
      : this is _AuthenticatedWithoutVehicles
      ? (this as _AuthenticatedWithoutVehicles).user
      : null;

  UserModel? get currentApiUser => this is _Authenticated
      ? (this as _Authenticated).appUser
      : this is _AuthenticatedWithoutVehicles
      ? (this as _AuthenticatedWithoutVehicles).appUser
      : null;
}

/// Initial state
class _Initial extends AuthState {
  const _Initial();
}

/// Loading state
class _Loading extends AuthState {
  const _Loading();
}

/// Authenticated state
class _Authenticated extends AuthState {
  final User user;
  final UserModel? appUser;

  const _Authenticated(this.user, {this.appUser});
}

/// Authenticated state but without vehicles (needs onboarding)
class _AuthenticatedWithoutVehicles extends AuthState {
  final User user;
  final UserModel? appUser;

  const _AuthenticatedWithoutVehicles(this.user, {this.appUser});
}

/// Unauthenticated state
class _Unauthenticated extends AuthState {
  const _Unauthenticated();
}

/// Error state
class _Error extends AuthState {
  final String message;

  const _Error(this.message);
}

/// Password reset email sent
class _PasswordResetEmailSent extends AuthState {
  const _PasswordResetEmailSent();
}
