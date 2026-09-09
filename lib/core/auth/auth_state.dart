import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

/// Estado de sesión global. Lo consume únicamente el router para decidir
/// entre `/welcome` y el shell de pestañas — el resto de la app nunca lee
/// `AuthCubit` por `getIt` (única excepción de la regla, ver CLAUDE.md).
@freezed
sealed class AuthState with _$AuthState {
  const factory AuthState.unknown() = AuthUnknown;

  const factory AuthState.authenticated() = AuthAuthenticated;

  const factory AuthState.unauthenticated() = AuthUnauthenticated;
}
