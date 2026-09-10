import 'dart:math';

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../battery_service.dart';
import '../location_service.dart';
import '../rider_position.dart';
import '../sos_alert.dart';
import '../sos_outbox.dart';
import '../sos_outbox_item.dart';
import '../sos_repository.dart';

/// El corazón de la seguridad del rider (CLAUDE.md: "el SOS nunca falla en
/// silencio"). Orden **obligatorio**, nunca alterado:
///
/// 1. Posición con timeout de 5 s o la última conocida del sistema.
/// 2. `outbox.enqueue` — persistido en disco ANTES de tocar la red.
/// 3. Intento de `raise` contra el servidor.
/// 4. Éxito → `markSent` y `Right(alert)` confirmado. Fallo → el item
///    queda en la cola (`markAttempt`) y se devuelve `Left(item)`: nunca
///    se lanza una excepción, nunca se pierde el SOS.
///
/// `Left` aquí no es un `DomainException`: es el propio [SosOutboxItem]
/// pendiente, porque un SOS sin confirmar no es un error que se descarta,
/// es un estado de UI ("pendiente") que `SosCubit` debe poder seguir
/// mostrando y que `RetrySosOutboxUseCase` reintentará.
@injectable
class RaiseSosUseCase {
  RaiseSosUseCase(this._locationService, this._batteryService, this._outbox, this._repository);

  final LocationService _locationService;
  final BatteryService _batteryService;
  final SosOutbox _outbox;
  final SosRepository _repository;

  final Random _random = Random.secure();

  Future<Either<SosOutboxItem, SosAlert>> call({
    required String eventId,
    String? message,
  }) async {
    final position = await _resolvePosition();
    final item = SosOutboxItem(
      clientId: _newClientId(),
      eventId: eventId,
      position: position,
      message: message,
      createdAt: DateTime.now().toUtc(),
    );

    await _outbox.enqueue(item);

    final result = await _repository.raise(item);
    return result.fold(
      (_) async {
        await _outbox.markAttempt(item.clientId);
        return Left(item);
      },
      (alert) async {
        await _outbox.markSent(item.clientId);
        return Right(alert);
      },
    );
  }

  Future<RiderPosition> _resolvePosition() async {
    final position = await _locationService.currentPosition(
      timeout: const Duration(seconds: 5),
    );
    final batteryPct = await _batteryService.currentLevel();
    if (position != null) {
      return position.copyWith(batteryPct: position.batteryPct ?? batteryPct);
    }
    // Nunca hubo una posición del sistema (caso raro: dispositivo recién
    // encendido, sin fix jamás). El SOS igual se encola con lat/lng 0 en
    // vez de bloquear el envío — es preferible una posición imprecisa a
    // ningún SOS.
    return RiderPosition(
      lat: 0,
      lng: 0,
      recordedAt: DateTime.now().toUtc(),
      batteryPct: batteryPct,
    );
  }

  String _newClientId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant
    final hex = bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-${hex.substring(20)}';
  }
}
