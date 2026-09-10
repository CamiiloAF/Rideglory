import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_ride_contacts.freezed.dart';

/// D17: contacto de emergencia del rider y teléfono del organizador,
/// cacheados **al empezar la rodada** (no se leen durante la emergencia)
/// para que el fallback sin datos (llamar / SMS) funcione sin red.
@freezed
abstract class LiveRideContacts with _$LiveRideContacts {
  const factory LiveRideContacts({
    required String organizerName,
    String? organizerPhone,
    String? emergencyContactName,
    String? emergencyContactPhone,
  }) = _LiveRideContacts;
}
