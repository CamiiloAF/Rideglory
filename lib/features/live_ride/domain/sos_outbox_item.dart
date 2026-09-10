import 'package:freezed_annotation/freezed_annotation.dart';

import 'rider_position.dart';

part 'sos_outbox_item.freezed.dart';

/// Un SOS pendiente de confirmar por el servidor. `clientId` es el
/// idempotency key de `raise_sos`: reintentar el mismo item nunca crea dos
/// alertas. Se persiste localmente **antes** de intentar la red (regla de
/// seguridad del rider: el SOS nunca falla en silencio).
@freezed
abstract class SosOutboxItem with _$SosOutboxItem {
  const factory SosOutboxItem({
    required String clientId,
    required String eventId,
    required RiderPosition position,
    required DateTime createdAt,
    String? message,
    @Default(0) int attempts,
  }) = _SosOutboxItem;
}
