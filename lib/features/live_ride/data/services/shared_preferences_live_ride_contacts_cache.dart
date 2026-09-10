import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/live_ride_contacts.dart';
import '../../domain/live_ride_contacts_cache.dart';

/// D17: cachea el contacto de emergencia y el teléfono del organizador al
/// empezar la rodada, para que el fallback de SOS (llamar / SMS) funcione
/// sin red. Una entrada por `eventId` para no arrastrar el contacto de una
/// rodada anterior.
@Injectable(as: LiveRideContactsCache)
class SharedPreferencesLiveRideContactsCache implements LiveRideContactsCache {
  SharedPreferencesLiveRideContactsCache(this._prefs);

  final SharedPreferences _prefs;

  String _keyFor(String eventId) => 'live_ride_contacts_$eventId';

  @override
  Future<void> save(String eventId, LiveRideContacts contacts) async {
    final json = jsonEncode({
      'organizerName': contacts.organizerName,
      'organizerPhone': contacts.organizerPhone,
      'emergencyContactName': contacts.emergencyContactName,
      'emergencyContactPhone': contacts.emergencyContactPhone,
    });
    await _prefs.setString(_keyFor(eventId), json);
  }

  @override
  Future<LiveRideContacts?> read(String eventId) async {
    final raw = _prefs.getString(_keyFor(eventId));
    if (raw == null) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return LiveRideContacts(
      organizerName: json['organizerName'] as String,
      organizerPhone: json['organizerPhone'] as String?,
      emergencyContactName: json['emergencyContactName'] as String?,
      emergencyContactPhone: json['emergencyContactPhone'] as String?,
    );
  }

  @override
  Future<void> clear(String eventId) async {
    await _prefs.remove(_keyFor(eventId));
  }
}
