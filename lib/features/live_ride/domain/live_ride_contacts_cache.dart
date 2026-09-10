import 'live_ride_contacts.dart';

/// Caché local de [LiveRideContacts], escrita **al empezar la rodada**
/// (D17) para que el fallback de SOS funcione sin red. Implementada en
/// `data/` con `shared_preferences`.
abstract class LiveRideContactsCache {
  Future<void> save(String eventId, LiveRideContacts contacts);

  Future<LiveRideContacts?> read(String eventId);

  Future<void> clear(String eventId);
}
