import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import 'connectivity_state.dart';

/// Cubit global de conectividad. Se provee con `BlocProvider` en la raíz del
/// árbol y se lee con `context.watch`/`context.read` — nunca por `getIt`.
@injectable
class ConnectivityCubit extends Cubit<ConnectivityState> {
  ConnectivityCubit(this._connectivity)
    : super(const ConnectivityState.online()) {
    _subscription = _connectivity.onConnectivityChanged.listen(_onChanged);
    _checkInitial();
  }

  final Connectivity _connectivity;
  late final StreamSubscription<List<ConnectivityResult>> _subscription;

  Future<void> _checkInitial() async {
    final result = await _connectivity.checkConnectivity();
    _onChanged(result);
  }

  void _onChanged(List<ConnectivityResult> results) {
    final isOffline =
        results.isEmpty ||
        results.every((result) => result == ConnectivityResult.none);
    emit(
      isOffline
          ? const ConnectivityState.offline()
          : const ConnectivityState.online(),
    );
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
