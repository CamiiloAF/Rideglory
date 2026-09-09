import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../notifications/device_token_registrar.dart';
import 'auth_state.dart';

/// Única excepción a "cubits se leen con `context.read`, nunca `getIt`":
/// el router necesita el estado de sesión fuera del árbol de widgets para
/// decidir el `redirect`, así que este cubit sí se resuelve por DI directa.
///
/// También es el punto central donde se registra el token FCM (F4): cada
/// vez que hay sesión — login, registro, social o relanzar la app con una
/// sesión ya activa — pasa por aquí.
@singleton
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._supabaseClient, this._deviceTokenRegistrar)
    : super(const AuthState.unknown()) {
    _subscription = _supabaseClient.auth.onAuthStateChange.listen(_onChange);
    _onChange(
      supabase.AuthState(
        supabase.AuthChangeEvent.initialSession,
        _supabaseClient.auth.currentSession,
      ),
    );
  }

  final supabase.SupabaseClient _supabaseClient;
  final DeviceTokenRegistrar _deviceTokenRegistrar;
  late final StreamSubscription<supabase.AuthState> _subscription;

  void _onChange(supabase.AuthState data) {
    emit(
      data.session != null
          ? const AuthState.authenticated()
          : const AuthState.unauthenticated(),
    );
    if (data.session != null) {
      unawaited(_deviceTokenRegistrar.registerForCurrentUser());
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
