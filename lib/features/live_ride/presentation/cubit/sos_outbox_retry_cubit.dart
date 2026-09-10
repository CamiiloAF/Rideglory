import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../shared/cubits/connectivity/connectivity_cubit.dart';
import '../../../../shared/cubits/connectivity/connectivity_state.dart';
import '../../domain/usecases/retry_sos_outbox_use_case.dart';

/// Cubit global sin UI propia: reintenta la cola de SOS pendiente al
/// arrancar la app, cada vez que `ConnectivityCubit` recupera señal, y
/// además con un latido periódico (D16). El latido existe porque "sin
/// señal" en la vía casi nunca es un `offline` limpio del sistema
/// operativo — es una petición individual que se cae o expira mientras
/// el teléfono se sigue reportando en línea (una torre débil, un túnel
/// corto, un pico de tráfico). Sin el latido, un SOS que falló así por
/// una sola vez se quedaría "pendiente" para siempre: nadie perdió la
/// señal, así que nadie dispara `ConnectivityOnline`. Se provee una vez
/// en la raíz (junto a `ConnectivityCubit`) para que esto no dependa de
/// que el rider tenga la pantalla de SOS abierta.
@injectable
class SosOutboxRetryCubit extends Cubit<int> {
  SosOutboxRetryCubit(this._connectivity, this._retryOutbox) : super(0) {
    _subscription = _connectivity.stream.listen(_onConnectivityChanged);
    _heartbeat = Timer.periodic(heartbeatInterval, (_) {
      unawaited(_retryOutbox());
    });
    unawaited(_retryOutbox());
  }

  /// Expuesto para que un test pueda avanzar un reloj falso sin esperar
  /// el intervalo real.
  static const Duration heartbeatInterval = Duration(seconds: 15);

  final ConnectivityCubit _connectivity;
  final RetrySosOutboxUseCase _retryOutbox;
  late final StreamSubscription<ConnectivityState> _subscription;
  late final Timer _heartbeat;

  void _onConnectivityChanged(ConnectivityState connectivityState) {
    if (connectivityState is ConnectivityOnline) {
      unawaited(_retryOutbox());
    }
  }

  @override
  Future<void> close() {
    _subscription.cancel();
    _heartbeat.cancel();
    return super.close();
  }
}
