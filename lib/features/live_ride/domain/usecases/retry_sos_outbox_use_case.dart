import 'package:injectable/injectable.dart';

import '../sos_alert.dart';
import '../sos_outbox.dart';
import '../sos_repository.dart';

/// Reintenta todo lo que sigue pendiente en la cola de SOS. Se dispara al
/// recuperar conectividad (`ConnectivityCubit`) y al arrancar la app. Nunca
/// lanza: cada fallo individual solo deja el item en cola para el próximo
/// intento.
@injectable
class RetrySosOutboxUseCase {
  const RetrySosOutboxUseCase(this._outbox, this._repository);

  final SosOutbox _outbox;
  final SosRepository _repository;

  /// Devuelve las alertas que se confirmaron en esta corrida, para que
  /// quien las escuche (`SosCubit`) pueda pasar de "pendiente" a
  /// "confirmado" sin esperar al próximo evento de Realtime.
  Future<List<SosAlert>> call() async {
    final pending = await _outbox.pending();
    final confirmed = <SosAlert>[];
    for (final item in pending) {
      final result = await _repository.raise(item);
      await result.fold(
        (_) => _outbox.markAttempt(item.clientId),
        (alert) async {
          await _outbox.markSent(item.clientId);
          confirmed.add(alert);
        },
      );
    }
    return confirmed;
  }
}
