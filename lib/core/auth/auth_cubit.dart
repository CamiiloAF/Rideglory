import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'auth_state.dart';

/// Única excepción a "cubits se leen con `context.read`, nunca `getIt`":
/// el router necesita el estado de sesión fuera del árbol de widgets para
/// decidir el `redirect`, así que este cubit sí se resuelve por DI directa.
///
/// La feature de autenticación completa (F4) construye sobre este cubit
/// mínimo: hoy solo observa `onAuthStateChange` de Supabase.
@singleton
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._supabaseClient) : super(const AuthState.unknown()) {
    _subscription = _supabaseClient.auth.onAuthStateChange.listen(_onChange);
    _onChange(
      supabase.AuthState(
        supabase.AuthChangeEvent.initialSession,
        _supabaseClient.auth.currentSession,
      ),
    );
  }

  final supabase.SupabaseClient _supabaseClient;
  late final StreamSubscription<supabase.AuthState> _subscription;

  void _onChange(supabase.AuthState data) {
    emit(
      data.session != null
          ? const AuthState.authenticated()
          : const AuthState.unauthenticated(),
    );
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
