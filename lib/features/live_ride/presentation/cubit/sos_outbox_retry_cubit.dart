import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/cubits/connectivity/connectivity_cubit.dart';
import '../../../../shared/cubits/connectivity/connectivity_state.dart';
import '../../domain/usecases/retry_sos_outbox_use_case.dart';

/// Cubit global sin UI propia: reintenta la cola de SOS pendiente al
/// arrancar la app y cada vez que `ConnectivityCubit` recupera señal. Se
/// provee una vez en la raíz (junto a `ConnectivityCubit`) para que un SOS
/// encolado en un tramo sin cobertura salga apenas vuelva la señal, sin
/// depender de que el rider tenga la pantalla de SOS abierta.
@injectable
class SosOutboxRetryCubit extends Cubit<int> {
  SosOutboxRetryCubit(this._connectivity, this._retryOutbox) : super(0) {
    _subscription = _connectivity.stream.listen(_onConnectivityChanged);
    unawaited(_retryOutbox());
  }

  final ConnectivityCubit _connectivity;
  final RetrySosOutboxUseCase _retryOutbox;
  late final StreamSubscription<ConnectivityState> _subscription;

  void _onConnectivityChanged(ConnectivityState connectivityState) {
    if (connectivityState is ConnectivityOnline) {
      unawaited(_retryOutbox());
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    return super.close();
  }
}
