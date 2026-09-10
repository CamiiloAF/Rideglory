import 'sos_outbox_item.dart';

/// Cola local durable de SOS pendientes. Se escribe **antes** de intentar
/// la red y sobrevive a que maten la app (persistencia en disco, no en
/// memoria). Implementada en `data/` con `shared_preferences`.
abstract class SosOutbox {
  /// Idempotente por `item.clientId`: encolar el mismo item dos veces no
  /// duplica la entrada.
  Future<void> enqueue(SosOutboxItem item);

  Future<List<SosOutboxItem>> pending();

  Future<void> markSent(String clientId);

  /// Incrementa el contador de intentos de un item que sigue pendiente
  /// (fallo de red o de servidor); no lo elimina.
  Future<void> markAttempt(String clientId);
}
