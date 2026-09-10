import 'package:dartz/dartz.dart';

import '../../../core/exceptions/domain_exception.dart';
import 'sos_alert.dart';
import 'sos_outbox_item.dart';

abstract class SosRepository {
  /// Llama a `raise_sos`, idempotente por `item.clientId`. `Left` cuando el
  /// servidor no confirma (offline, error) — el llamador decide qué hacer
  /// con la cola, este repositorio nunca la toca.
  Future<Either<DomainException, SosAlert>> raise(SosOutboxItem item);

  Future<Either<DomainException, SosAlert>> close(String sosId);

  /// Alertas visibles de la rodada (propias y de otros), actualizadas por
  /// Realtime sobre `sos_alerts` (D16).
  Stream<Either<DomainException, List<SosAlert>>> watchAlerts(String eventId);
}
