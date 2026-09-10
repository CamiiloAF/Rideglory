import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../domain/sos_alert.dart';
import '../../domain/sos_outbox.dart';
import '../../domain/sos_status.dart';
import '../../domain/usecases/close_sos_use_case.dart';
import '../../domain/usecases/raise_sos_use_case.dart';
import '../../domain/usecases/retry_sos_outbox_use_case.dart';
import '../../domain/usecases/watch_sos_alerts_use_case.dart';
import 'sos_send_state.dart';
import 'sos_state.dart';

/// Pantallas LV3-LV5. `others` trae **todas** las alertas visibles de la
/// rodada (`sos_alerts_visible`, propias y de terceros) — filtrar cuál es
/// "mía" para la tarjeta LV5 es responsabilidad de la UI, que conoce el
/// usuario autenticado; `mine` es la fuente de verdad de la UI de SOS
/// propio (LV3/LV4) porque sigue el ciclo local pendiente→confirmado sin
/// depender de que Realtime ya haya entregado el evento.
@injectable
class SosCubit extends Cubit<SosState> {
  SosCubit(
    this._raiseSos,
    this._closeSos,
    this._watchAlerts,
    this._retryOutbox,
    this._outbox,
  ) : super(const SosState());

  final RaiseSosUseCase _raiseSos;
  final CloseSosUseCase _closeSos;
  final WatchSosAlertsUseCase _watchAlerts;
  final RetrySosOutboxUseCase _retryOutbox;
  final SosOutbox _outbox;

  StreamSubscription<dynamic>? _alertsSubscription;
  late String _eventId;

  Future<void> load(String eventId) async {
    _eventId = eventId;
    emit(state.copyWith(others: const ResultState.loading()));

    final pending = await _outbox.pending();
    final myPending = pending.where((item) => item.eventId == eventId);
    if (myPending.isNotEmpty) {
      emit(state.copyWith(mine: SosSendState.pending(item: myPending.first)));
    }

    unawaited(_alertsSubscription?.cancel());
    _alertsSubscription = _watchAlerts(eventId).listen((result) {
      result.fold(
        (error) =>
            emit(state.copyWith(others: ResultState.error(error: error))),
        (alerts) {
          emit(
            state.copyWith(
              others: alerts.isEmpty
                  ? const ResultState.empty()
                  : ResultState.data(data: alerts),
            ),
          );
          _reconcileMine(alerts);
        },
      );
    });
  }

  /// Si el SOS que tenemos como "propio" (ya confirmado) aparece cerrado
  /// en la lista de Realtime, refleja el cierre sin que el rider tenga que
  /// hacer nada (D19: puede haberlo cerrado el organizador).
  void _reconcileMine(List<SosAlert> alerts) {
    final mine = state.mine;
    if (mine is! SosSendConfirmed) return;
    final updated = alerts.where((alert) => alert.id == mine.alert.id);
    if (updated.isEmpty) return;
    final alert = updated.first;
    if (alert.status == SosStatus.closed) {
      emit(state.copyWith(mine: SosSendState.closed(alert: alert)));
    }
  }

  Future<void> raise({String? message}) async {
    emit(state.copyWith(mine: const SosSendState.sending()));
    final result = await _raiseSos(eventId: _eventId, message: message);
    result.fold(
      (item) => emit(state.copyWith(mine: SosSendState.pending(item: item))),
      (alert) => emit(state.copyWith(mine: SosSendState.confirmed(alert: alert))),
    );
  }

  /// Se dispara al recuperar conectividad (`SosOutboxRetryCubit`) o al
  /// volver a abrir esta pantalla con un SOS todavía pendiente.
  Future<void> retryPending() async {
    final mine = state.mine;
    if (mine is! SosSendPending) return;
    final confirmed = await _retryOutbox();
    final match = confirmed.where((alert) => alert.eventId == _eventId);
    if (match.isNotEmpty) {
      emit(state.copyWith(mine: SosSendState.confirmed(alert: match.first)));
    }
  }

  Future<void> closeMine() async {
    final mine = state.mine;
    if (mine is! SosSendConfirmed) return;
    emit(state.copyWith(mine: SosSendState.closing(alert: mine.alert)));
    final result = await _closeSos(mine.alert.id);
    result.fold(
      (_) => emit(state.copyWith(mine: SosSendState.confirmed(alert: mine.alert))),
      (alert) => emit(state.copyWith(mine: SosSendState.closed(alert: alert))),
    );
  }

  @override
  Future<void> close() async {
    await _alertsSubscription?.cancel();
    return super.close();
  }
}
