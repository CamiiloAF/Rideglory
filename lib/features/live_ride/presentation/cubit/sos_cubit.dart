import 'dart:async';

import 'package:dartz/dartz.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/domain/result_state.dart';
import '../../../../core/exceptions/domain_exception.dart';
import '../../domain/sos_alert.dart';
import '../../domain/sos_outbox.dart';
import '../../domain/sos_outbox_item.dart';
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
      (alert) =>
          emit(state.copyWith(mine: SosSendState.confirmed(alert: alert))),
    );
  }

  /// Se dispara al recuperar conectividad (`SosOutboxRetryCubit`) o al
  /// volver a abrir esta pantalla con un SOS todavía pendiente.
  Future<void> retryPending() async {
    final mine = state.mine;
    if (mine is! SosSendPending) return;
    final alert = await _resolveConfirmedAlert();
    if (alert != null) {
      emit(state.copyWith(mine: SosSendState.confirmed(alert: alert)));
    }
  }

  Future<void> closeMine() async {
    final mine = state.mine;
    if (mine is SosSendConfirmed) {
      await _closeConfirmed(mine.alert);
      return;
    }
    if (mine is SosSendPending) {
      await _closePending(mine.item);
    }
  }

  Future<void> _closeConfirmed(SosAlert alert) async {
    emit(state.copyWith(mine: SosSendState.closing(alert: alert)));
    final result = await _closeSos(alert.id);
    result.fold(
      (_) => emit(state.copyWith(mine: SosSendState.confirmed(alert: alert))),
      (closed) =>
          emit(state.copyWith(mine: SosSendState.closed(alert: closed))),
    );
  }

  /// El rider pidió cerrar un SOS que localmente seguía "pendiente": la
  /// confirmación del servidor pudo perderse aunque el alta ya haya
  /// quedado escrita (D16, respuesta perdida ≠ envío fallido). Nunca se
  /// descarta la cola local sin comprobarlo primero — hacerlo dejaría una
  /// alerta activa en el servidor que ya nadie vuelve a cerrar. Se
  /// reintenta con el MISMO `clientId` (`raise_sos` es idempotente) para
  /// resolver el id real y recién ahí cerrarlo de verdad.
  Future<void> _closePending(SosOutboxItem item) async {
    emit(state.copyWith(mine: const SosSendState.sending()));
    final alert = await _resolveConfirmedAlert();
    if (alert == null) {
      // Sigue sin poder confirmarse: nada que cerrar en el servidor
      // todavía. Queda "pendiente" — el heartbeat global y un nuevo
      // toque en "cerrar" lo seguirán intentando.
      emit(state.copyWith(mine: SosSendState.pending(item: item)));
      return;
    }
    await _closeConfirmed(alert);
  }

  /// Reintenta toda la cola de SOS pendiente (`RetrySosOutboxUseCase`,
  /// idempotente por `clientId`) y devuelve la alerta de ESTA rodada si
  /// alguna se confirmó en esta corrida.
  Future<SosAlert?> _resolveConfirmedAlert() async {
    final confirmed = await _retryOutbox();
    final match = confirmed.where((alert) => alert.eventId == _eventId);
    return match.isEmpty ? null : match.first;
  }

  /// LV5c: el organizador cierra el SOS de otro rider (D19). No toca
  /// `state.mine` — `others` se actualiza solo por el stream de Realtime.
  Future<Either<DomainException, SosAlert>> closeOther(String sosId) =>
      _closeSos(sosId);

  @override
  Future<void> close() async {
    await _alertsSubscription?.cancel();
    return super.close();
  }
}
