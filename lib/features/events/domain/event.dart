import 'package:freezed_annotation/freezed_annotation.dart';

import 'event_difficulty.dart';
import 'event_state.dart';
import 'registration_status.dart';

part 'event.freezed.dart';

/// Una rodada. `myRegistrationStatus` es `null` cuando el rider que consulta
/// no tiene ninguna inscripción propia (ni siquiera cancelada).
@freezed
abstract class Event with _$Event {
  const factory Event({
    required String id,
    required String ownerId,
    required String ownerName,
    required String name,
    required DateTime startAt,
    required EventDifficulty difficulty,
    required EventState state,
    required int price,
    required int approvedCount,
    String? description,
    String? routeText,
    String? meetingPoint,
    String? destinationName,
    double? destinationLat,
    double? destinationLng,
    String? imageUrl,
    int? maxParticipants,
    DateTime? startedAt,
    RegistrationStatus? myRegistrationStatus,
    @Default(false) bool isOwnedByMe,
  }) = _Event;

  const Event._();

  bool get isFree => price <= 0;

  /// El organizador debería iniciar la rodada porque ya pasó la hora
  /// pactada y sigue en `published` (EV7).
  bool get isOverdueToStart =>
      state == EventState.published && startAt.isBefore(DateTime.now());
}
